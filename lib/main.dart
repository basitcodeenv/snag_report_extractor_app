// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:snag_report_extractor_app/src/app.dart';


void main() async {
  // * For more info on error handling, see:
  // * https://docs.flutter.dev/testing/errors
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // turn off the # in the URLs on the web
      usePathUrlStrategy();
      // setup the executor for background tasks
      // * Entry point for the app
      runApp(const ProviderScope(child: MyApp()));

      // * This code will present some error UI if any uncaught exception happens
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text(
              "An error occured",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(child: Text(details.toString())),
        );
      };
    },
    (Object error, StackTrace stack) {
      // Log the error to the console
      debugPrint(error.toString());
    },
  );
}
