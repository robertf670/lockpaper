import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';

/// A screen that requires biometric/device authentication to proceed.
class LockScreen extends ConsumerStatefulWidget {
  /// Callback function executed upon successful authentication.
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _status = 'Waiting for authentication...';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Remove automatic authentication trigger
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //      _authenticate();
    //   }
    // });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _status = 'Authenticating...';
    });

    final biometricsService = ref.read(biometricsServiceProvider);
    bool authenticated = false;
    try {
      // Check if biometrics are supported/available first (optional but good practice)
      final bool canAuth = await biometricsService.canAuthenticate;
      if (canAuth) {
        authenticated = await biometricsService.authenticate('Please authenticate to access your notes');
        if (authenticated) {
          widget.onUnlocked(); // Call the callback on success
        } else {
          setState(() => _status = 'Authentication failed. Try again.');
        }
      } else {
        setState(() => _status = 'Biometrics not available or not enrolled.');
        // TODO: Implement PIN fallback mechanism here
      }
    } on PlatformException catch (e) {
      setState(() => _status = 'Error: ${e.message ?? "Unknown error"}');
      // Handle specific errors like lockout if needed
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Lockpaper'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_status),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Authenticate'),
              onPressed: _isAuthenticating ? null : _authenticate, // Disable button while authenticating
            ),
            // TODO: Add button/link to trigger PIN entry
          ],
        ),
      ),
    );
  }
} 