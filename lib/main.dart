import 'dart:io'; // Needed for Platform
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/app_router.dart';
import 'package:lockpaper/core/app_theme.dart';
import 'package:lockpaper/core/application/app_lock_provider.dart';
import 'package:lockpaper/core/presentation/screens/lock_screen.dart';
import 'package:sqlite3/open.dart'; // Needed for open.overrideFor
import 'package:sqlite3/sqlite3.dart'; // Import sqlite3 for tempDirectory
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart'; // Needed for openCipherOnAndroid and workaround
import 'package:path_provider/path_provider.dart'; // Import for temp dir

void main() async {
  // Ensure initialization FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // // Set temp directory for sqlite3 *before* override (might help) - REMOVED
  // final cachebase = (await getTemporaryDirectory()).path;
  // sqlite3.tempDirectory = cachebase;
  // print("Set sqlite3.tempDirectory to: $cachebase");

  // Tell sqlite3 package how to load SQLCipher on Android
  if (Platform.isAndroid) {
    print("Applying Android SQLCipher workaround and override...");
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions(); 
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    print("Android SQLCipher override applied.");
  }
  // Add overrides for other platforms if necessary, e.g.:
  // if (Platform.isIOS || Platform.isMacOS) { 
  //   open.overrideFor(Platform.operatingSystem, () => DynamicLibrary.process());
  // }

  print("Running app...");
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
  bool _isUnlocking = false; // Flag for grace period during unlock

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

    if (state == AppLifecycleState.resumed) {
      if (!_initialResumeProcessed) {
        _initialResumeProcessed = true;
      } else {
        // Only re-lock if not currently in the unlock grace period
        if (!_isUnlocking) {
          ref.read(appLockStateProvider.notifier).state = true;
        }
      }
    }
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
            // Set grace period flag, unlock, then reset flag
            setState(() { _isUnlocking = true; });
            ref.read(appLockStateProvider.notifier).state = false;
            Future.delayed(const Duration(milliseconds: 100), () {
               if (mounted) { // Check if still mounted before resetting flag
                 setState(() { _isUnlocking = false; });
               }
            });
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
