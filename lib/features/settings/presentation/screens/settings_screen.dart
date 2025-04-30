import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart';
import 'package:lockpaper/core/services/preference_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBiometricsEnabled = ref.watch(biometricsEnabledProvider);
    final prefServiceAsync = ref.watch(preferenceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            subtitle: const Text('Modify your application unlock PIN'),
            onTap: () {
              context.pushNamed(EnterCurrentPinScreen.routeName);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Enable Biometric Unlock'),
            subtitle: const Text('Use fingerprint or face unlock'),
            value: isBiometricsEnabled,
            onChanged: (bool value) {
              prefServiceAsync.whenData((service) {
                service.setBiometricsEnabled(value);
                ref.invalidate(biometricsEnabledProvider);
              });
            },
          ),
        ],
      ),
    );
  }
} 