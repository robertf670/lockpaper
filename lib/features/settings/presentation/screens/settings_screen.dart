import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
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
              // Navigate to the start of the change PIN flow
              context.pushNamed(EnterCurrentPinScreen.routeName);
            },
          ),
          // TODO: Add other settings later (e.g., enable/disable biometrics)
        ],
      ),
    );
  }
} 