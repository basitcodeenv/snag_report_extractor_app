import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_screen.dart';
import 'package:snag_report_extractor_app/src/routing/not_found_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:snag_report_extractor_app/src/logging/talker.dart';

enum AppRoute { home, logs }

final goRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: AppRoute.home.name,
      builder: (context, state) => const PdfExtractorScreen(),
    ),
    GoRoute(
      path: '/logs',
      name: AppRoute.logs.name,
      builder: (context, state) => TalkerScreen(
        appBarLeading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.home.name),
        ),
        theme: const TalkerScreenTheme(logColors: {
          'success': Colors.green,
        }),
        appBarTitle: "Logs",
        talker: talker,
      ),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
  observers: [TalkerRouteObserver(talker)],
);
