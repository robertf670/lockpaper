import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/confirm_new_pin_screen.dart'; // Uncomment this
import 'package:pinput/pinput.dart';


class EnterNewPinScreen extends ConsumerStatefulWidget {
  const EnterNewPinScreen({super.key});

  static const routeName = '/enter-new-pin';

  @override
  ConsumerState<EnterNewPinScreen> createState() => _EnterNewPinScreenState();
}

class _EnterNewPinScreenState extends ConsumerState<EnterNewPinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinCompleted(String newPin) {
    // Navigate to confirmation screen, passing the newly entered pin
    context.pushNamed( // Uncomment this block
      ConfirmNewPinScreen.routeName, 
      extra: newPin, 
    );
    // Remove placeholder SnackBar
    // ScaffoldMessenger.of(context).showSnackBar(...);

    // Clear field in case user navigates back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinController.clear();
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Reusing Pinput themes from CreatePinScreen
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(fontSize: 20, color: colorScheme.onSurface),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: colorScheme.primary)),
    );
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(color: colorScheme.surfaceContainerHigh),
    );
    // Error theme not strictly needed here as there's no validation on this screen
    // final errorPinTheme = ... 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter New PIN'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 30.0),
                child: Text(
                  'Enter your new secure 6-digit PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  obscureText: true,
                  obscuringCharacter: '●',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  // No error theme needed here
                  onCompleted: _onPinCompleted,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 