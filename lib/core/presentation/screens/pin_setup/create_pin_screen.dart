import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/presentation/screens/pin_setup/confirm_pin_screen.dart'; // Will create next
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  static const routeName = '/create-pin'; // Example route name

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>(); // Optional, for Pinput validation

  @override
  void initState() {
    super.initState();
    // Request focus after the first frame
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

  void _onPinCompleted(String pin) {
    // Navigate to confirmation screen using GoRouter
    context.pushNamed(
      ConfirmPinScreen.routeName, 
      extra: pin, // Pass pin as extra argument
    );
    // Clear the field in case user navigates back
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) { // Check mount status after async gap
          _pinController.clear();
          _pinFocusNode.requestFocus();
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data for colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define Pinput theme based on AppTheme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 20,
        color: colorScheme.onSurface, // Use theme text color
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // Use M3 surface color
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent), // Default no border
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary), // Primary color border when focused
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
       decoration: defaultPinTheme.decoration!.copyWith(
         // Slightly different background for submitted state?
         color: colorScheme.surfaceContainerHigh, // Or keep same as default
       ),
    );
    
    final errorPinTheme = defaultPinTheme.copyWith(
      textStyle: TextStyle(color: colorScheme.error), // Use error color for text
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.error), // Error color border
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up PIN'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 30.0),
                  child: Text(
                    'Create a secure 6-digit PIN for your app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Pinput(
                    length: 6, // Example length, make configurable?
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    obscureText: true, // Hide PIN characters
                    obscuringCharacter: '●',
                    autofocus: true, // Helps ensure keyboard pops up
                    keyboardType: TextInputType.number,
                    // Apply the themes
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme, 
                    errorPinTheme: errorPinTheme,
                    // validator: (s) { // Example validation
                    //   return s == '111111' ? null : 'PIN is incorrect';
                    // },
                    onCompleted: _onPinCompleted,
                    // Haptic feedback can be nice: hapticFeedbackType: HapticFeedbackType.lightImpact,
                  ),
                ),
                // Add some spacing or other UI elements if needed
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 