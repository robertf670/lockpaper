import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lockpaper/core/application/app_lock_provider.dart';
import 'package:lockpaper/core/security/encryption_key_service.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';

/// A screen that requires biometric/device authentication to proceed.
class LockScreen extends ConsumerStatefulWidget {
  /// Callback function executed upon successful authentication.
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  String _status = 'Waiting for authentication...';
  bool _isAuthenticating = false;
  // Flag to ensure auth trigger happens only once *per build cycle*
  bool _authTriggeredThisBuild = false;
  // Track app lifecycle state
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    print('[LockScreen initState] Called');
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState != null) {
      _appLifecycleState = WidgetsBinding.instance.lifecycleState;
      print('[LockScreen initState] Initial Lifecycle State: $_appLifecycleState');
      // Attempt initial auth only if starting in resumed state
      if (_appLifecycleState == AppLifecycleState.resumed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Check mount status inside callback
             print('[LockScreen initState] Post-frame check, calling _authenticate.');
            _authenticate();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    print('[LockScreen dispose] Called');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[LockScreen didChangeAppLifecycleState] State: $state');
    final previousState = _appLifecycleState;
    _appLifecycleState = state; // Update state first
    // Trigger auth only when resuming, if locked, and not already authenticating
    if (state == AppLifecycleState.resumed && previousState != AppLifecycleState.resumed) {
       // Check lock state from provider
      final isLocked = ref.read(appLockStateProvider);
      print('[LockScreen didChangeAppLifecycleState] Resumed. isLocked: $isLocked, isAuthenticating: $_isAuthenticating');
      if (isLocked && !_isAuthenticating) {
        print('[LockScreen didChangeAppLifecycleState] Triggering authenticate on resume.');
        _authenticate();
      }
    }
    // No need for setState here unless UI depends directly on _appLifecycleState
    // setState(() {
    //   _appLifecycleState = state;
    // });
  }

  Future<void> _authenticate() async {
    // --- IMMEDIATE GUARD --- 
    // Prevent reentry if already authenticating or widget is disposed
    if (!mounted || _isAuthenticating) {
      print('[LockScreen _authenticate] Skipped: Already authenticating or unmounted.');
      return;
    }
    // Set flag *immediately* after the guard
    _isAuthenticating = true; 
    // --- END IMMEDIATE GUARD ---

    // Check lifecycle state *before* proceeding further
    if (_appLifecycleState != AppLifecycleState.resumed) {
      print('[LockScreen _authenticate] Skipped: App not resumed ($_appLifecycleState).');
       _isAuthenticating = false; // Reset flag if skipping
      return;
    }
    // Reset the build trigger flag at the start of authentication attempt
    // _authTriggeredThisBuild = false; // REMOVED (Not needed anymore)
    // if (!mounted || _isAuthenticating) return; // MOVED TO TOP
    print('[LockScreen _authenticate] Called.'); // Simplified log
    // if (_isAuthenticating) return; // MOVED TO TOP

    // Update status *after* confirming we are proceeding
    setState(() {
      // _isAuthenticating = true; // MOVED TO TOP
      _status = 'Authenticating...';
    });

    final biometricsService = ref.read(biometricsServiceProvider);
    final keyService = ref.read(encryptionKeyServiceProvider);
    bool authenticated = false;
    try {
      final bool canAuth = await biometricsService.canAuthenticate;
      print('[LockScreen _authenticate] canAuthenticate result: $canAuth');

      // Explicitly check device support again right before authenticating
      final bool deviceSupported = await LocalAuthentication().isDeviceSupported();
      print('[LockScreen _authenticate] isDeviceSupported result: $deviceSupported');

      if (canAuth && deviceSupported) { // Check both flags
        authenticated = await biometricsService.authenticate('Please authenticate to access your notes');
        print('[LockScreen _authenticate] authenticate result: $authenticated');
        if (authenticated) {
          print('[LockScreen _authenticate] Authentication successful. Handling encryption key...');
          String? key;
          final bool keyExists = await keyService.hasStoredKey();
          if (keyExists) {
            print('[LockScreen _authenticate] Existing key found. Retrieving...');
            key = await keyService.getDatabaseKey();
            print('[LockScreen _authenticate] Key retrieved.');
          } else {
             print('[LockScreen _authenticate] CRITICAL: No encryption key found in storage!');
             key = null; // Ensure key is null if not found
             // Keep authenticated = true, but key will be null, leading to error below
          }

          if (key != null && key.isNotEmpty) {
            print('[LockScreen _authenticate] Setting encryption key provider...');
            ref.read(encryptionKeyProvider.notifier).state = key;
            print('[LockScreen _authenticate] Key provider set. Calling onUnlocked.');
            widget.onUnlocked(); // Proceed to unlock the app UI
          } else {
            print('[LockScreen _authenticate] Error: Failed to retrieve or generate key.');
            setState(() => _status = 'Error: Could not access encryption key.');
          }
        } else {
          setState(() => _status = 'Authentication failed. Try again.');
        }
      } else {
        setState(() => _status = 'Biometrics not available or not enrolled.');
        // TODO: Implement PIN fallback mechanism here
      }
    } on PlatformException catch (e) {
      print('[LockScreen _authenticate] PlatformException: ${e.code} - ${e.message}');
      setState(() => _status = 'Error: ${e.message ?? "Unknown error"}');
      // Handle specific errors like lockout if needed
    } finally {
      print('[LockScreen _authenticate] Finally block. Mounted: $mounted, Authenticated: $authenticated');
      // Only reset the flag if mounted and authentication didn't succeed
      // If successful, the widget will be disposed anyway.
      if (mounted && !authenticated) { 
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[LockScreen build] Called. Status: $_status, isAuthenticating: $_isAuthenticating');
    // _authTriggeredThisBuild = false; // REMOVED

    // REMOVE AUTH TRIGGER LOGIC FROM BUILD
    // final isLocked = ref.watch(appLockStateProvider);
    // print('[LockScreen build] isLocked: $isLocked, _authTriggeredThisBuild: $_authTriggeredThisBuild');
    // if (isLocked && !_authTriggeredThisBuild) {
    //   _authTriggeredThisBuild = true;
    //   print('[LockScreen build] Triggering auth via post-frame callback');
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //      print('[LockScreen build] PostFrameCallback running. Lifecycle: $_appLifecycleState');
    //      // Check mount status and lifecycle state again inside the callback
    //      if(mounted && _appLifecycleState == AppLifecycleState.resumed) {
    //        print('[LockScreen build] PostFrameCallback: Conditions met, calling _authenticate.');
    //        _authenticate();
    //      } else {
    //         print('[LockScreen build] PostFrameCallback: Widget unmounted or app not resumed, skipping auth.');
    //      }
    //   });
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Lockpaper'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add Semantics for live updates
            Semantics(
              liveRegion: true, // Announce changes to screen readers
              child: Text(_status),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              // Add Semantics label to the button text for clarity
              label: const Text('Authenticate with biometrics'), 
              onPressed: _isAuthenticating ? null : _authenticate, // Disable button while authenticating
            ),
            // TODO: Add button/link to trigger PIN entry
          ],
        ),
      ),
    );
  }
} 