import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snag_report_extractor_app/src/theme_mode_provider.dart';
import 'package:snag_report_extractor_app/src/localization/string_hardcoded.dart';
import 'package:snag_report_extractor_app/src/routing/app_routing.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'app',
      onGenerateTitle: (BuildContext context) => "Novel TTS".hardcoded,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.blue.shade800, // Seed color for light theme
              brightness: Brightness.light,
            ).copyWith(
              primary: Colors.blue.shade800,
              primaryContainer:
                  Colors.blue.shade500, // Custom primary container
              secondaryContainer:
                  Colors.blueAccent.shade400, // Custom secondary container
              surface: Colors.grey.shade50, // Very light gray for surfaces
              onSurface: Colors.black, // Text/icons on surface color
              error: Colors.red.shade700, // Error color for light theme
              onError: Colors.white, // Text/icons on error color
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade800, // Dark blue for app bar
          foregroundColor: Colors.white, // White text/icons on app bar
          elevation: 4, // Subtle shadow
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800, // Dark blue for buttons
            foregroundColor: Colors.white, // White text on buttons
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.blue.shade600, // Seed color for dark theme
              brightness: Brightness.dark,
            ).copyWith(
              primary: Colors.blue.shade600,
              primaryContainer:
                  Colors.blue.shade900, // Custom primary container
              secondaryContainer:
                  Colors.blueAccent.shade700, // Custom secondary container
              surface: Colors.black, // Pure black for surfaces
              onSurface: Colors.white, // Text/icons on surface color
              error: Colors.red.shade500, // Error color for dark theme
              onError: Colors.black, // Text/icons on error color
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600, // Medium blue for buttons
            foregroundColor: Colors.white, // White text on buttons
          ),
        ),
      ),
      themeMode: themeMode,
    );
  }
}
