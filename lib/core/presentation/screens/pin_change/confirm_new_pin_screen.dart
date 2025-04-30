import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; // For navigation target
import 'package:pinput/pinput.dart';

class ConfirmNewPinScreen extends ConsumerStatefulWidget {
  final String newPinToConfirm;

  const ConfirmNewPinScreen({super.key, required this.newPinToConfirm});

  static const routeName = '/confirm-new-pin';

  @override
  ConsumerState<ConfirmNewPinScreen> createState() => _ConfirmNewPinScreenState();
}

class _ConfirmNewPinScreenState extends ConsumerState<ConfirmNewPinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
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
    if (confirmedPin == widget.newPinToConfirm) {
      setState(() {
        _errorMessage = null; // Clear previous error
      });
      try {
        final pinService = ref.read(pinStorageServiceProvider);
        await pinService.setPin(confirmedPin); // Save the new PIN

        if (mounted) {
          // Navigate back to the main screen after successful change
          // Pop EnterNewPin, Pop ConfirmNewPin, Pop EnterCurrentPin?
          // Or just go home.
          context.goNamed(NotesListScreen.routeName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN changed successfully!')),
          );
        }
      } catch (e) {
        // Handle exceptions during pin save
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to save new PIN. Please try again.';
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
        if (mounted) { 
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Reusing Pinput themes
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
    final errorPinTheme = defaultPinTheme.copyWith(
      textStyle: TextStyle(color: colorScheme.error),
      decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: colorScheme.error)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm New PIN'),
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
                  'Re-enter your new 6-digit PIN to confirm.',
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
                  errorPinTheme: errorPinTheme,
                  onCompleted: _onPinCompleted,
                  forceErrorState: _errorMessage != null,
                  errorTextStyle: TextStyle(color: colorScheme.error, fontSize: 14),
                  errorText: _errorMessage,
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