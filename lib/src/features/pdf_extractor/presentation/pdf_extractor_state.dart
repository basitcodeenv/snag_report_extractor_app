
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
  final Isolate? isolate;

  // --- ETA tracking ---
  final List<int> pageDurations; // stores ms/page
  final DateTime? lastPageTime;

  PdfFileProgress({
    required this.fileName,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentImage = 0,
    this.totalImages = 0,
    this.outputDir,
    this.done = false,
    this.error,
    this.isolate,
    List<int>? pageDurations,
    this.lastPageTime,
  }) : pageDurations = pageDurations ?? [];

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
    List<int>? pageDurations,
    DateTime? lastPageTime,
  }) {
    return PdfFileProgress(
      fileName: fileName ?? this.fileName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentImage: currentImage ?? this.currentImage,
      totalImages: totalImages ?? this.totalImages,
      done: done ?? this.done,
      outputDir: outputDir ?? this.outputDir,
      error: error ?? this.error,
      isolate: isolate ?? this.isolate,
      pageDurations: pageDurations ?? List.from(this.pageDurations),
      lastPageTime: lastPageTime ?? this.lastPageTime,
    );
  }

  /// Call this when a page finishes processing
  PdfFileProgress markPageDone() {
    final now = DateTime.now();
    final newDurations = List<int>.from(pageDurations);

    if (lastPageTime != null) {
      final duration = now.difference(lastPageTime!).inMilliseconds;
      newDurations.add(duration);

      // keep only last 10 page durations for stable avg
      if (newDurations.length > 10) {
        newDurations.removeAt(0);
      }
    }

    return copyWith(pageDurations: newDurations, lastPageTime: now);
  }

  /// Estimated time remaining
  Duration? get remainingTime {
    if (currentPage == 0 || totalPages == 0 || pageDurations.isEmpty) {
      return null;
    }

    final avgMs =
        pageDurations.reduce((a, b) => a + b) / pageDurations.length;
    final remainingPages = totalPages - currentPage;
    return Duration(milliseconds: (remainingPages * avgMs).round());
  }

}

class PdfExtractorState {
  final bool isDragging;
  final bool isProcessing;
  final List<DropItem> files;
  final DropItem? currentFile;
  final int processedFiles;
  final List<String> errors;

  final Map<String, PdfFileProgress> progress;

  PdfExtractorState({
    this.isDragging = false,
    this.isProcessing = false,
    this.files = const [],
    this.currentFile,
    this.processedFiles = 0,
    this.errors = const [],
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
      progress: progress ?? this.progress,
    );
  }
}
