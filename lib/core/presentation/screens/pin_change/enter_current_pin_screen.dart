import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_new_pin_screen.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:pinput/pinput.dart';

class EnterCurrentPinScreen extends ConsumerStatefulWidget {
  const EnterCurrentPinScreen({super.key});

  static const routeName = '/enter-current-pin';

  @override
  ConsumerState<EnterCurrentPinScreen> createState() => _EnterCurrentPinScreenState();
}

class _EnterCurrentPinScreenState extends ConsumerState<EnterCurrentPinScreen> {
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

  Future<void> _onPinCompleted(String enteredPin) async {
    setState(() {
      _errorMessage = null; // Clear previous error on new attempt
    });

    final pinService = ref.read(pinStorageServiceProvider);
    final bool isCorrect = await pinService.verifyPin(enteredPin);

    if (!mounted) return; // Check mounted state after async gap

    if (isCorrect) {
      // Navigate to the next step in the flow
      context.pushNamed(EnterNewPinScreen.routeName);
    } else {
      // Show error, clear field, request focus
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Reusing Pinput themes from ConfirmPinScreen
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
        title: const Text('Enter Current PIN'),
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
                  'Please enter your current 6-digit PIN to proceed.',
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