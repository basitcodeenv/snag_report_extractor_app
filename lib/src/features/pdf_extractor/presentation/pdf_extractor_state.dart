
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

  PdfFileProgress({
    required this.fileName,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentImage = 0,
    this.totalImages = 0,
    this.outputDir,
    this.done = false,
    this.error,
  });

  PdfFileProgress copyWith({
    int? currentPage,
    int? totalPages,
    int? currentImage,
    int? totalImages,
    String? outputDir,
    bool? done,
    String? error,
  }) {
    return PdfFileProgress(
      fileName: fileName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentImage: currentImage ?? this.currentImage,
      totalImages: totalImages ?? this.totalImages,
      outputDir: outputDir ?? this.outputDir,
      done: done ?? this.done,
      error: error ?? this.error,
    );
  }
}

class PdfExtractorState {
  final bool isProcessing;
  final List<DropItem> files;
  final DropItem? currentFile;
  final int processedFiles;
  final List<String> errors;
  final List<String> outputPaths;

  final Map<String, PdfFileProgress> progress;

  PdfExtractorState({
    this.isProcessing = false,
    this.files = const [],
    this.currentFile,
    this.processedFiles = 0,
    this.errors = const [],
    this.outputPaths = const [],
    this.progress = const {},
  });

  PdfExtractorState copyWith({
    bool? isProcessing,
    List<DropItem>? files,
    DropItem? currentFile,
    int? processedFiles,
    List<String>? errors,
    List<String>? outputPaths,
    Map<String, PdfFileProgress>? progress,
  }) {
    return PdfExtractorState(
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
