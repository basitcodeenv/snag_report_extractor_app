// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';
import 'dart:isolate';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/directory_manager.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/pdf_worker.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_state.dart';

class PdfExtractorScreenController extends StateNotifier<PdfExtractorState> {
  final DirectoryManager directoryManager;

  PdfExtractorScreenController({required this.directoryManager})
    : super(PdfExtractorState());

  void startDragging() {
    state = state.copyWith(isDragging: true);
  }

  void stopDragging() {
    state = state.copyWith(isDragging: false);
  }

  void addToQueue(List<DropItem> files) {
    state = state.copyWith(files: [...state.files, ...files]);
  }

  void removeFromQueue(DropItem file) {
    final progress = state.progress[file.path];

    if (progress?.isolate != null && progress?.done == false) {
      progress?.isolate!.kill(priority: Isolate.immediate);
    }

    state = state.copyWith(
      files: state.files.where((item) => item != file).toList(),
      progress: {...state.progress}..remove(file.path),
    );
  }

  Future<void> processPdfFiles() async {
    try {
      String outputRoot = directoryManager.getDirectory();

      state = state.copyWith(isProcessing: true, errors: []);

      for (final file in state.files) {
        final fileName = file.name;
        final filePath = file.path;

        if (state.progress[filePath]?.done == true) {
          // already processing this file
          continue;
        }

        final folderName = p.basenameWithoutExtension(filePath);
        String outputDir = "$outputRoot/$folderName";

        if (await Directory(outputDir).exists()) {
          for (var i = 2; Directory(outputDir).existsSync(); i++) {
            outputDir = "$outputRoot/$folderName ($i)";
          }
        }
        await Directory(outputDir).create(recursive: true);

        state = state.copyWith(
          progress: {
            ...state.progress,
            filePath: PdfFileProgress(fileName: fileName),
          },
        );

        final receivePort = ReceivePort();

        final isolate = await Isolate.spawn(extractPdfWorker, {
          "sendPort": receivePort.sendPort,
          "path": filePath,
          "outputDir": outputDir,
        });

        state = state.copyWith(
          progress: {
            ...state.progress,
            filePath: PdfFileProgress(fileName: fileName, isolate: isolate),
          },
        );

        await for (final msg in receivePort) {
          final progress = msg as Map<String, dynamic>;
          final currentProgress = state.progress[filePath]!;

          if (progress["error"] != null) {
            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress.copyWith(
                  error: progress["error"],
                  done: true,
                ),
              },
              errors: [...state.errors, progress["error"]],
              processedFiles: state.processedFiles + 1,
            );
            receivePort.close();
            break;
          }

          if (progress["page"] != null && progress["pageCount"] != null) {
            print(
              "Processed page ${progress["page"]}/${progress["pageCount"]}",
            );

            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress
                    .copyWith(
                      currentPage: progress["page"],
                      totalPages: progress["pageCount"],
                    )
                    .markPageDone(),
              },
            );
          }

          if (progress["image"] != null && progress["imageCount"] != null) {
            print(
              "Extracted image ${progress["image"]}/${progress["imageCount"]}",
            );
            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress.copyWith(
                  currentImage: progress["image"],
                  totalImages: progress["imageCount"],
                ),
              },
            );
          }

          if (progress["done"] == true) {
            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress.copyWith(
                  done: true,
                  outputDir: progress["outputDir"],
                ),
              },
              processedFiles: state.processedFiles + 1,
            );
            receivePort.close();
            break;
          }
        }
      }
    } finally {
      state = state.copyWith(isProcessing: false, currentFile: null);
    }
  }

  void clearErrors() {
    state = state.copyWith(errors: []);
  }
}

final pdfExtractorScreenControllerProvider =
    StateNotifierProvider<PdfExtractorScreenController, PdfExtractorState>((
      ref,
    ) {
      final DirectoryManager directoryManager = ref.read(
        directoryManagerProvider.notifier,
      );
      return PdfExtractorScreenController(directoryManager: directoryManager);
    });
