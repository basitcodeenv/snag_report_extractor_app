import 'package:talker_flutter/talker_flutter.dart';

/// A custom log type for success messages
class SuccessLog extends TalkerLog {
  SuccessLog(String super.message)
    : super(logLevel: LogLevel.debug, title: 'SUCCESS');
}

/// Extension to add `success()` method to Talker
extension TalkerSuccessExtension on Talker {
  void success(String message) {
    logCustom(SuccessLog(message));
  }
}
