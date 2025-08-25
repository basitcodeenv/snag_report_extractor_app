
import 'dart:isolate';

import 'package:desktop_drop/desktop_drop.dart';

class PdfFileProgress {
  final String fileName;
  final int currentPage;
  final int totalPages;
  final int currentImage;
  final int totalImages;
  final String? outputDir;
  final bool done;
  final String? error;
  /// Timestamp when this file started processing
  final DateTime? startTime;
  final Isolate? isolate;

  PdfFileProgress({
    required this.fileName,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentImage = 0,
    this.totalImages = 0,
    this.outputDir,
    this.done = false,
    this.error,
    this.startTime,
    this.isolate,
  });

  PdfFileProgress copyWith({
    String? fileName,
    DateTime? startTime,
    int? currentPage,
    int? totalPages,
    int? currentImage,
    int? totalImages,
    bool? done,
    String? outputDir,
    String? error,
    Isolate? isolate,
  }) {
    return PdfFileProgress(
      fileName: fileName ?? this.fileName,
      startTime: startTime ?? this.startTime,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentImage: currentImage ?? this.currentImage,
      totalImages: totalImages ?? this.totalImages,
      done: done ?? this.done,
      outputDir: outputDir ?? this.outputDir,
      error: error ?? this.error,
      isolate: isolate ?? this.isolate,
    );
  }

  /// Estimated time remaining
  Duration? get remainingTime {
    if (startTime == null || currentPage == 0 || totalPages == 0) return null;

    final elapsed = DateTime.now().difference(startTime!);
    final avgPerPage = elapsed.inMilliseconds / currentPage;
    final remainingPages = totalPages - currentPage;
    final remainingMs = (remainingPages * avgPerPage).round();

    return Duration(milliseconds: remainingMs);
  }

}

class PdfExtractorState {
  final bool isDragging;
  final bool isProcessing;
  final List<DropItem> files;
  final DropItem? currentFile;
  final int processedFiles;
  final List<String> errors;
  final List<String> outputPaths;

  final Map<String, PdfFileProgress> progress;

  PdfExtractorState({
    this.isDragging = false,
    this.isProcessing = false,
    this.files = const [],
    this.currentFile,
    this.processedFiles = 0,
    this.errors = const [],
    this.outputPaths = const [],
    this.progress = const {},
  });

  PdfExtractorState copyWith({
    bool? isDragging,
    bool? isProcessing,
    List<DropItem>? files,
    DropItem? currentFile,
    int? processedFiles,
    List<String>? errors,
    List<String>? outputPaths,
    Map<String, PdfFileProgress>? progress,
  }) {
    return PdfExtractorState(
      isDragging: isDragging ?? this.isDragging,
      isProcessing: isProcessing ?? this.isProcessing,
      files: files ?? this.files,
      currentFile: currentFile ?? this.currentFile,
      processedFiles: processedFiles ?? this.processedFiles,
      errors: errors ?? this.errors,
      outputPaths: outputPaths ?? this.outputPaths,
      progress: progress ?? this.progress,
    );
  }
}
