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
import 'package:lockpaper/core/services/preference_service.dart'; // Import PreferenceService
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
  bool _biometricsSettingEnabled = true; // Cache preference state

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

    // PIN exists, check biometrics availability AND user preference
    final biometricService = ref.read(biometricsServiceProvider);
    final prefs = await ref.read(preferenceServiceProvider.future); // Get preference service
    _biometricsSettingEnabled = prefs.isBiometricsEnabled();
    _canUseBiometrics = await biometricService.canAuthenticate;

    // Check mount status AGAIN *after* async calls but *before* critical setState
    if (!mounted) return;

    setState(() { _isLoading = false; }); // Set loading false

    // Check mount status AGAIN *before* potentially calling _attemptBiometrics or setting PIN state
    if (!mounted) return;

    // Determine initial UI state, considering the preference
    if (_biometricsSettingEnabled && _canUseBiometrics) {
      _status = 'Authenticate to unlock';
      _showPinInput = false;
       // Trigger biometrics slightly delayed
       Future.delayed(const Duration(milliseconds: 100), () {
         if (mounted && _appLifecycleState == AppLifecycleState.resumed && !_isAuthenticating) {
           _attemptBiometrics();
         }
       });
      _needsPinFocusRequest = true;
    } else {
      _status = 'Enter your PIN';
      _showPinInput = true;
      _needsPinFocusRequest = true;
    }
    if (mounted) setState(() {}); // Update UI
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

      // Check preference before attempting biometrics again
      if (_biometricsSettingEnabled && _canUseBiometrics && !_showPinInput) {
        _attemptBiometrics();
      } else if (_showPinInput) {
         // Handle PIN focus if needed
         // If resuming to the PIN screen, ensure focus is requested again.
         setState(() {
           _needsPinFocusRequest = true;
         });
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
    // Add check for the cached preference setting
    if (!_biometricsSettingEnabled || !mounted || _isAuthenticating) return;
    
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
            _needsPinFocusRequest = true; 
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Biometric error: ${e.message ?? "Unknown"}';
          _showPinInput = true;
          _isAuthenticating = false;
          _needsPinFocusRequest = true; 
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Define Pinput themes (example, customize as needed)
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

    Widget authWidget = const SizedBox.shrink();

    if (_isLoading) {
      authWidget = const Center(child: CircularProgressIndicator());
    } else if (_showPinInput) {
      // RE-ADD focus request logic for PIN
      if (_needsPinFocusRequest) {
         // Reset the flag *before* scheduling the callback
         _needsPinFocusRequest = false; 
         WidgetsBinding.instance.addPostFrameCallback((_) { 
            if (mounted) {
             // Remove setState from here 
             Future.delayed(const Duration(milliseconds: 100), () { 
                if (mounted && _pinFocusNode.canRequestFocus) {
                 _pinFocusNode.requestFocus();
                 SystemChannels.textInput.invokeMethod('TextInput.show');
               }
             });
           } 
         });
       }
       
      // Assign the actual PIN UI to authWidget
      authWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(_status, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 40),
          Pinput(
            length: 6,
            controller: _pinController,
            focusNode: _pinFocusNode,
            obscureText: true,
            obscuringCharacter: '●',
            autofocus: false, // Rely on explicit focus request
            keyboardType: TextInputType.number,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            errorPinTheme: errorPinTheme,
            onCompleted: _verifyPin,
            forceErrorState: _pinErrorMessage != null,
            errorTextStyle: TextStyle(color: colorScheme.error, fontSize: 14),
            errorText: _pinErrorMessage,
            enabled: !_isAuthenticating,
          ),
          const SizedBox(height: 20),
          // Option to switch back to biometrics if available
          if (_biometricsSettingEnabled && _canUseBiometrics) // Check setting and capability
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
           // Optional: Show a general progress indicator
           if (_isAuthenticating) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
           ]
        ],
      );
    } else {
      // Build Biometric prompt UI
      authWidget = Column(
         mainAxisAlignment: MainAxisAlignment.center,
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           const Icon(Icons.fingerprint, size: 80),
           const SizedBox(height: 20),
           Text(_status, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
           const SizedBox(height: 40),
           ElevatedButton.icon(
             icon: const Icon(Icons.fingerprint),
             label: const Text('Authenticate'),
             onPressed: _isAuthenticating ? null : _attemptBiometrics,
           ),
           const SizedBox(height: 20),
           TextButton(
             child: const Text('Use PIN'),
             onPressed: _isAuthenticating ? null : () {
               setState(() { 
                 _showPinInput = true; 
                 _status = 'Enter your PIN';
                 _needsPinFocusRequest = true; // SET FLAG HERE when switching
               });
             },
           ),
         ],
      );
    }

    return Scaffold(
       // Prevent accidental back navigation while locked
       // WillPopScope is deprecated, but demonstrates intent.
       // Use PopScope in newer Flutter versions.
       // onWillPop: () async => false, 
       body: PopScope(
         canPop: false, // Prevent back button
         child: Center(
           child: SingleChildScrollView(
             padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
             child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 350),
               child: authWidget,
             ),
           ),
         ),
       ),
    );
  }
} 