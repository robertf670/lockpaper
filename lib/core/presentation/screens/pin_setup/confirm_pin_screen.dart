import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';

class ConfirmPinScreen extends ConsumerStatefulWidget {
  final String initialPin;

  const ConfirmPinScreen({super.key, required this.initialPin});

  static const routeName = '/confirm-pin'; // Example route name

  @override
  ConsumerState<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends ConsumerState<ConfirmPinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>(); 
  String? _errorMessage;

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

  Future<void> _onPinCompleted(String confirmedPin) async {
    if (confirmedPin == widget.initialPin) {
      setState(() {
        _errorMessage = null; // Clear previous error
      });
      try {
        // Show loading indicator?
        final pinService = ref.read(pinStorageServiceProvider);
        await pinService.setPin(confirmedPin);

        // Navigate back to LockScreen (or maybe pop until root?)
        // Popping twice removes CreatePin and ConfirmPin
        if (mounted) {
          // Use GoRouter to navigate back to the main screen, clearing setup stack
          context.goNamed(NotesListScreen.routeName); 
          // Optionally show a success message (Snackbar)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN set successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to save PIN. Please try again.';
          });
          _pinController.clear();
          _pinFocusNode.requestFocus();
        }
      }
    } else {
      // Pins don't match
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
      });
      _pinController.clear();
      // Delay focus request slightly to ensure it happens after build
      Future.delayed(Duration.zero, () { 
        if (mounted) { // Check mount status again in delayed callback
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data for colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define Pinput theme based on AppTheme (copied from CreatePinScreen for consistency)
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm PIN'),
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
                    'Re-enter your PIN to confirm.',
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
                    // Apply the themes
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    errorPinTheme: errorPinTheme,
                    onCompleted: _onPinCompleted,
                    forceErrorState: _errorMessage != null,
                    errorTextStyle: TextStyle(
                      color: colorScheme.error, // Use theme error color
                      fontSize: 14,
                    ),
                    errorText: _errorMessage,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 