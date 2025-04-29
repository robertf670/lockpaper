import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Added for navigation
import 'package:lockpaper/core/presentation/screens/pin_setup/create_pin_screen.dart'; // Added for navigation
import 'package:lockpaper/core/security/biometrics_service.dart';
// import 'package:local_auth/local_auth.dart'; // Unused
import 'package:lockpaper/core/application/app_lock_provider.dart';
import 'package:lockpaper/core/security/encryption_key_service.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart'; // Added for PIN logic
import 'package:lockpaper/features/notes/data/app_database.dart';
import 'package:pinput/pinput.dart'; // Added for PIN input widget

/// A screen that requires biometric/device authentication or PIN to proceed.
class LockScreen extends ConsumerStatefulWidget {
  /// Callback function executed upon successful authentication.
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  // State variables
  String _status = 'Checking setup...';
  bool _isAuthenticating = false; // General flag for any auth process
  bool _isLoading = true; // Flag to show loading indicator during initial checks
  AppLifecycleState? _appLifecycleState;

  // PIN specific state
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _pinErrorMessage;
  bool _showPinInput = false; // Controls whether to show PIN or Biometric UI
  bool _canUseBiometrics = false; // Cache biometric availability
  bool _needsPinFocusRequest = false; // RE-ADD flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState = WidgetsBinding.instance.lifecycleState;
    _checkSetupAndAuthenticate();
  }

  Future<void> _checkSetupAndAuthenticate() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final pinService = ref.read(pinStorageServiceProvider);
    final hasPin = await pinService.hasPin();

    if (!mounted) return;

    if (!hasPin) {
      // No PIN set, navigate to setup
      setState(() { _isLoading = false; _status = 'Redirecting to PIN setup...'; });
      // Use pushReplacement to prevent user from going back to lock screen without PIN
      context.goNamed(CreatePinScreen.routeName);
      return; // Stop further execution
    }

    // PIN exists, check biometrics availability
    final biometricService = ref.read(biometricsServiceProvider);
    _canUseBiometrics = await biometricService.canAuthenticate;

    setState(() { _isLoading = false; });

    // Determine initial UI state
    if (_canUseBiometrics) {
      _status = 'Authenticate to unlock';
      _showPinInput = false;
       Future.delayed(const Duration(milliseconds: 100), () {
         if (mounted && _appLifecycleState == AppLifecycleState.resumed && !_isAuthenticating) {
           _attemptBiometrics();
         }
       });
    } else {
      _status = 'Enter your PIN';
      _showPinInput = true;
      _needsPinFocusRequest = true; // SET FLAG HERE
    }
     if (mounted) setState(() {}); // Update UI with initial status/visibility
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final previousState = _appLifecycleState;
    _appLifecycleState = state;

    if (state == AppLifecycleState.resumed &&
        previousState != AppLifecycleState.resumed &&
        !_isLoading &&
        !_isAuthenticating &&
         ref.read(appLockStateProvider)) {

      if (_canUseBiometrics && !_showPinInput) {
        _attemptBiometrics();
      } else if (_showPinInput) {
         // If showing PIN input, maybe trigger focus again? Less ideal.
         // Relying on ValueKey + autofocus for now.
         // WidgetsBinding.instance.addPostFrameCallback((_) {
         //    if(mounted && _pinFocusNode.canRequestFocus) _pinFocusNode.requestFocus();
         // });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Renamed from _authenticate to be specific
  Future<void> _attemptBiometrics() async {
    if (!mounted || _isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _status = 'Authenticating with biometrics...';
      _pinErrorMessage = null;
    });

    final service = ref.read(biometricsServiceProvider);
    bool authenticated = false;
    try {
      authenticated = await service.authenticate('Please authenticate to access your notes');

      if (mounted) {
        if (authenticated) {
          await _handleSuccessfulAuth();
        } else {
          setState(() {
            _status = 'Biometric authentication failed. Enter PIN.';
            _showPinInput = true;
            _isAuthenticating = false;
            _needsPinFocusRequest = true; // SET FLAG HERE
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Biometric error: ${e.message ?? "Unknown"}';
          _showPinInput = true;
          _isAuthenticating = false;
          _needsPinFocusRequest = true; // SET FLAG HERE
        });
      }
    } finally {
       if (mounted && !authenticated) {
         setState(() => _isAuthenticating = false);
       }
    }
  }

  Future<void> _verifyPin(String pin) async {
     if (!mounted || _isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _status = 'Verifying PIN...';
      _pinErrorMessage = null;
    });

    final pinService = ref.read(pinStorageServiceProvider);
    bool pinCorrect = false;
    try {
      pinCorrect = await pinService.verifyPin(pin);

      if (mounted) {
        if (pinCorrect) {
          await _handleSuccessfulAuth();
        } else {
          setState(() {
            _status = 'Incorrect PIN. Please try again.';
            _pinErrorMessage = 'Incorrect PIN'; 
            _isAuthenticating = false;
            _needsPinFocusRequest = true; // SET FLAG HERE
          });
          _pinController.clear(); 
        }
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _status = 'Error verifying PIN.';
          _pinErrorMessage = 'Verification Error';
          _isAuthenticating = false;
          _needsPinFocusRequest = true; // SET FLAG HERE
        });
        _pinController.clear();
      }
    } finally {
       if (mounted && !pinCorrect) {
         setState(() => _isAuthenticating = false);
       }
    }
  }

  // Common logic after successful Biometric or PIN auth
  Future<void> _handleSuccessfulAuth() async {
    if (!mounted) return;
    setState(() { _status = 'Authentication successful. Unlocking...'; });

    final keyService = ref.read(encryptionKeyServiceProvider);
    String? key;
    try {
      final bool keyExists = await keyService.hasStoredKey();
      if (keyExists) {
        key = await keyService.getDatabaseKey();
      } else {
        key = await keyService.generateAndStoreNewKey();
      }

      if (mounted) {
        if (key != null && key.isNotEmpty) {
          ref.read(encryptionKeyProvider.notifier).state = key;
          widget.onUnlocked(); // Proceed to unlock the app UI
        } else {
           // This case should ideally not happen if generation/retrieval is robust
          setState(() {
            _status = 'Error: Could not access encryption key.';
            _isAuthenticating = false; // Allow retry?
            // Potentially force PIN input again or show specific error UI
             _showPinInput = true;
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if(mounted) _pinFocusNode.requestFocus();
             });
          });
        }
      }
    } catch (e) {
       if (mounted) {
         setState(() {
           _status = 'Error accessing keys after auth.';
           _isAuthenticating = false;
           _showPinInput = true; // Show PIN on key error
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if(mounted) _pinFocusNode.requestFocus();
             });
         });
       }
    }
     // Note: No need to reset _isAuthenticating here if successful, as widget will unmount.
  }


  @override
  Widget build(BuildContext context) {
    // Get theme data for colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define Pinput theme based on AppTheme (copied from setup screens)
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 20,
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
       decoration: defaultPinTheme.decoration!.copyWith(
         color: colorScheme.surfaceContainerHigh,
       ),
    );
    
    final errorPinTheme = defaultPinTheme.copyWith(
      textStyle: TextStyle(color: colorScheme.error),
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.error),
      ),
    );

    // RE-IMPLEMENT post-frame callback logic for focus request with internal delay
    if (_needsPinFocusRequest) {
      // Reset the flag *before* scheduling the callback to prevent issues
      // if build is called again before the callback runs.
       _needsPinFocusRequest = false; // Direct assignment should be safe here

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a minimal delay *within* the post-frame callback
        Future.delayed(const Duration(milliseconds: 100), () { // e.g., 100ms delay
           if (mounted) { // Check mount status again after delay
             if (_pinFocusNode.canRequestFocus && !_pinFocusNode.hasFocus) {
                _pinFocusNode.requestFocus();
                // Explicitly request keyboard show after focus
                SystemChannels.textInput.invokeMethod('TextInput.show');
             }
           }
        });
      });
      // NOTE: Removed the setState call to reset flag from here, handled above.
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Lockpaper'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator initially
            : Padding( // Add padding around content
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Semantics( // Status message
                      liveRegion: true,
                      child: Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 40),

                    // --- Conditional UI for PIN vs Biometrics ---
                    if (_showPinInput) ...[
                      // PIN Input UI
                       Pinput(
                        length: 6, // Should match setup screens
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        obscureText: true,
                        obscuringCharacter: '●',
                        autofocus: false, // Set autofocus to false, rely on explicit request
                        keyboardType: TextInputType.number,
                        // Apply the themes
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        errorPinTheme: errorPinTheme,
                        onCompleted: _verifyPin,
                        forceErrorState: _pinErrorMessage != null,
                        errorTextStyle: TextStyle(
                          color: colorScheme.error, // Use theme error color
                          fontSize: 14,
                         ),
                         errorText: _pinErrorMessage,
                         enabled: !_isAuthenticating, // Disable during verification
                      ),
                      const SizedBox(height: 20),
                       // Option to switch back to biometrics if available
                      if (_canUseBiometrics)
                        TextButton.icon(
                           icon: const Icon(Icons.fingerprint),
                           label: const Text('Use Biometrics'),
                           onPressed: _isAuthenticating ? null : () {
                             setState(() {
                               _showPinInput = false;
                               _status = 'Authenticate to unlock';
                               _pinErrorMessage = null;
                               _pinController.clear(); // Clear PIN field
                             });
                             // Attempt biometrics immediately after switching
                             _attemptBiometrics();
                           },
                         ),

                    ] else ...[
                      // Biometric Prompt UI (only shown if _canUseBiometrics is true)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint, size: 30),
                        label: const Text('Authenticate with biometrics', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        onPressed: _isAuthenticating ? null : _attemptBiometrics,
                      ),
                      const SizedBox(height: 20),
                      // Option to switch to PIN input
                      TextButton(
                         child: const Text('Use PIN Instead'),
                         onPressed: _isAuthenticating ? null : () {
                           setState(() {
                             _showPinInput = true;
                             _status = 'Enter your PIN';
                             _needsPinFocusRequest = true; // SET FLAG HERE
                           });
                         },
                       ),
                    ],
                    // --- End Conditional UI ---

                     // Optional: Show a general progress indicator during any auth operation
                    if (_isAuthenticating && !_isLoading) ...[
                       const SizedBox(height: 20),
                       const CircularProgressIndicator(),
                    ]

                  ],
                ),
              ),
      ),
    );
  }
} 