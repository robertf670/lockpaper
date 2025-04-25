import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/app_router.dart';
import 'package:lockpaper/core/app_theme.dart';
import 'package:lockpaper/core/application/app_lock_provider.dart';
import 'package:lockpaper/core/presentation/screens/lock_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // Flag to ignore the very first resume event on launch
  bool _initialResumeProcessed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Lock the app when it goes into the background (paused or inactive)
    // Only lock if it's currently unlocked.
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        ref.read(appLockStateProvider) == false) {
      ref.read(appLockStateProvider.notifier).state = true;
    }

    // Remove resume-based locking logic
    /*
    if (state == AppLifecycleState.resumed) {
      if (!_initialResumeProcessed) {
        _initialResumeProcessed = true;
      } else {
        ref.read(appLockStateProvider.notifier).state = true;
      }
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockStateProvider);

    if (isLocked) {
      return MaterialApp(
        title: 'Lockpaper',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: LockScreen(
          onUnlocked: () {
            ref.read(appLockStateProvider.notifier).state = false;
          },
        ),
      );
    } else {
      return MaterialApp.router(
        title: 'Lockpaper',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      );
    }
  }
}
