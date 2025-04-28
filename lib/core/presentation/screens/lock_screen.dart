import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';
// import 'package:local_auth/local_auth.dart'; // Unused
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
  // bool _authTriggeredThisBuild = false; // Unused
  // Track app lifecycle state
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState != null) {
      _appLifecycleState = WidgetsBinding.instance.lifecycleState;
    }
    // Trigger authentication check after the first frame, ONLY if app is currently resumed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure widget is still mounted AND app is resumed before calling async method
      if (mounted && 
          ref.read(appLockStateProvider) && 
          _appLifecycleState == AppLifecycleState.resumed) { 
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final previousState = _appLifecycleState;
    _appLifecycleState = state; // Update state first
    // Trigger auth only when resuming, if locked, and not already authenticating
    if (state == AppLifecycleState.resumed && previousState != AppLifecycleState.resumed) {
       // Check lock state from provider
      final isLocked = ref.read(appLockStateProvider);
      if (isLocked && !_isAuthenticating) {
        _authenticate(); // <<< Restored call
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
      return;
    }
    // Set flag *immediately* after the guard
    _isAuthenticating = true; 
    // --- END IMMEDIATE GUARD ---

    // REMOVED Check for resumed state within authenticate - rely on triggers
    // if (_appLifecycleState != AppLifecycleState.resumed) {
    //   print('[LockScreen _authenticate] Skipped: App not resumed ($_appLifecycleState).');
    //    _isAuthenticating = false; // Reset flag if skipping
    //   return;
    // }
    
    // print('[LockScreen _authenticate] Called.'); // Simplified log

    // Update status *after* confirming we are proceeding
    setState(() {
      // _isAuthenticating = true; // MOVED TO TOP
      _status = 'Authenticating...';
    });

    final service = ref.read(biometricsServiceProvider);
    final keyService = ref.read(encryptionKeyServiceProvider);
    bool authenticated = false;
    try {
      final bool canAuth = await service.canAuthenticate;
      // print('[LockScreen _authenticate] canAuthenticate result: $canAuth');

      // REMOVED Explicit check for device support - now part of canAuthenticate
      // final bool deviceSupported = await LocalAuthentication().isDeviceSupported();
      // print('[LockScreen _authenticate] isDeviceSupported result: $deviceSupported');

      // if (canAuth && deviceSupported) { // Old check
      if (canAuth) { // Simplified check relying on BiometricsService
        authenticated = await service.authenticate('Please authenticate to access your notes');
        // print('[LockScreen _authenticate] authenticate result: $authenticated');
        if (authenticated) {
          // print('[LockScreen _authenticate] Authentication successful. Handling encryption key...');
          String? key;
          final bool keyExists = await keyService.hasStoredKey();
          if (keyExists) {
            // print('[LockScreen _authenticate] Existing key found. Retrieving...');
            key = await keyService.getDatabaseKey();
            // print('[LockScreen _authenticate] Key retrieved.');
          } else {
             // print('[LockScreen _authenticate] No key found in storage. Generating new key...');
             // Generate and store a new key if one doesn't exist
             try {
               key = await keyService.generateAndStoreNewKey();
               // print('[LockScreen _authenticate] New key generated and stored.');
             } catch (e) {
               // print('[LockScreen _authenticate] Error generating/storing key: $e');
               key = null;
             }
             // key = null; // Ensure key is null if not found // OLD LINE
             // Keep authenticated = true, but key will be null, leading to error below // OLD COMMENT
          }

          if (key != null && key.isNotEmpty) {
            // print('[LockScreen _authenticate] Setting encryption key provider...');
            ref.read(encryptionKeyProvider.notifier).state = key;
            // print('[LockScreen _authenticate] Key provider set. Calling onUnlocked.');
            widget.onUnlocked(); // Proceed to unlock the app UI
          } else {
            // print('[LockScreen _authenticate] Error: Failed to retrieve or generate key.');
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
      // print('[LockScreen _authenticate] PlatformException: ${e.code} - ${e.message}');
      setState(() => _status = 'Error: ${e.message ?? "Unknown error"}');
      // Handle specific errors like lockout if needed
    } finally {
      // print('[LockScreen _authenticate] Finally block. Mounted: $mounted, Authenticated: $authenticated');
      // Only reset the flag if mounted and authentication didn't succeed
      // If successful, the widget will be disposed anyway.
      if (mounted && !authenticated) { 
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('[LockScreen build] Called. Status: $_status, isAuthenticating: $_isAuthenticating');
    // _authTriggeredThisBuild = false; // REMOVED

    // <<< Restored original build method >>>
    /* // Simplified build method commented out
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Lockpaper (Simplified)'),
      ),
      body: const Center(
        child: Text('Simplified Lock Screen for Testing'),
      ),
    );
    */

    // Original build method restored
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
              label: const Text('Authenticate with biometrics'),
              onPressed: _isAuthenticating ? null : _authenticate,
              // Add Semantics for button state
              // Semantics properties can be added here if needed, 
              // e.g., hint, enabled state description
            ),
          ],
        ),
      ),
    );
  }
} 