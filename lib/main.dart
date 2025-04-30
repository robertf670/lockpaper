import 'dart:io'; // Needed for Platform
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/app_router.dart';
import 'package:lockpaper/core/app_theme.dart';
import 'package:lockpaper/core/application/app_lock_provider.dart';
import 'package:sqlite3/open.dart'; // Needed for open.overrideFor
import 'package:sqlite3/sqlite3.dart'; // Import sqlite3 for tempDirectory
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart'; // Needed for openCipherOnAndroid and workaround
import 'package:path_provider/path_provider.dart'; // Import for temp dir
import 'package:dynamic_color/dynamic_color.dart';

void main() async {
  // Ensure initialization FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // Tell sqlite3 package how to load SQLCipher on Android *FIRST*
  if (Platform.isAndroid) {
    // print("Applying Android SQLCipher workaround and override...");
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions(); 
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    // print("Android SQLCipher override applied.");
  }

  // Set temp directory for sqlite3 *after* override
  final cachebase = (await getTemporaryDirectory()).path;
  sqlite3.tempDirectory = cachebase;
  // print("Set sqlite3.tempDirectory to: $cachebase");

  // Add overrides for other platforms if necessary, e.g.:
  // if (Platform.isIOS || Platform.isMacOS) { 
  //   open.overrideFor(Platform.operatingSystem, () => DynamicLibrary.process());
  // }

  // print("Running app...");
  // Wrap ProviderScope in DynamicColorBuilder
  runApp(const DynamicColorApp());
}

// New wrapper widget to handle DynamicColorBuilder
class DynamicColorApp extends StatelessWidget {
  const DynamicColorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Pass the dynamic color schemes down to MyApp
        return ProviderScope(
          child: MyApp(lightDynamic: lightDynamic, darkDynamic: darkDynamic),
        );
      },
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  // Accept palettes
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
  
  const MyApp({super.key, this.lightDynamic, this.darkDynamic});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // Flag to ignore the very first resume event on launch
  // bool _initialResumeProcessed = false; // Unused

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
    // print('[MyApp didChangeAppLifecycleState] State: $state');

    final isCurrentlyLocked = ref.read(appLockStateProvider);
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        !isCurrentlyLocked) { 
      // print('[MyApp didChangeAppLifecycleState] Locking on backgrounding.');
      ref.read(appLockStateProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockStateProvider);

    // Create themes using palettes from DynamicColorBuilder
    final lightTheme = AppTheme.getTheme(widget.lightDynamic, Brightness.light);
    final darkTheme = AppTheme.getTheme(widget.darkDynamic, Brightness.dark);

    // --- Always return MaterialApp.router --- 
    // Get the router configuration, passing the ref
    final routerConfig = AppRouter.getRouter(ref);

    // The router's redirect logic now handles showing the LockScreen
    return MaterialApp.router(
      title: 'Lockpaper',
      theme: lightTheme, // Use dynamic or fallback theme
      darkTheme: darkTheme, // Use dynamic or fallback theme
      themeMode: ThemeMode.system, 
      routerConfig: routerConfig, // Use the configured router
      debugShowCheckedModeBanner: false,
    );

    /* // OLD LOGIC - REMOVED
    if (isLocked) {
      // Original LockScreen instantiation restored
      return MaterialApp(
        title: 'Lockpaper',
        theme: lightTheme, // Use dynamic or fallback theme
        darkTheme: darkTheme, // Use dynamic or fallback theme
        themeMode: ThemeMode.system, 
        debugShowCheckedModeBanner: false,
        home: LockScreen(
          onUnlocked: () {
            // print('[MyApp build - onUnlocked] Setting lock state to false.');
            ref.read(appLockStateProvider.notifier).state = false;
          },
        ),
      );
    } else {
      return MaterialApp.router(
        title: 'Lockpaper',
        theme: lightTheme, // Use dynamic or fallback theme
        darkTheme: darkTheme, // Use dynamic or fallback theme
        themeMode: ThemeMode.system, 
        routerConfig: AppRouter.router, // Old static router
        debugShowCheckedModeBanner: false,
      );
    }
    */
  }
}
