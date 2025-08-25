import 'package:go_router/go_router.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_screen.dart';
import 'package:snag_report_extractor_app/src/routing/not_found_screen.dart';

enum AppRoute { home, novelDetail, chapter }

final goRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const PdfExtractorScreen()),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
