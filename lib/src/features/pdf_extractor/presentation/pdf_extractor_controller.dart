// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';
import 'dart:isolate';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/directory_manager.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/pdf_worker.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_state.dart';
import 'package:worker_manager/worker_manager.dart';


class PdfExtractorScreenController extends StateNotifier<PdfExtractorState> {
  final DirectoryManager directoryManager;

  PdfExtractorScreenController({ required this.directoryManager }) : super(PdfExtractorState());

  Future<void> addToQueue(List<DropItem> files) async {
    state = state.copyWith(
      files: [...state.files, ...files],
    );
  }

  Future<void> removeFromQueue(DropItem file) async {
    state = state.copyWith(
      files: state.files.where((item) => item != file).toList(),
    );
  }

  Future<void> processPdfFiles() async {
    try {
      String outputRoot = directoryManager.getDirectory();

      state = state.copyWith(
        isProcessing: true,
        errors: [],
      );

      for (final file in state.files) {
        final fileName = file.name;
        final filePath = file.path;
        state = state.copyWith(
          progress: {
            ...state.progress,
            filePath: PdfFileProgress(fileName: fileName),
          },
        );

        final outputDir = "$outputRoot/${p.basename(filePath)}";
        if (!await Directory(outputDir).exists()) {
          await Directory(outputDir).create(recursive: true);
        }

        // final cancelable = workerManager
        //     .executeWithPort<void, Map<String, dynamic>>((
        //       SendPort sendPort,
        //     ) async {
        //       return await PdfWorker.extractPdf(
        //         sendPort,
        //         pdfPath: filePath,
        //         outputDir: outputDir,
        //         fileName: fileName,
        //       );
        //     }, onMessage: (message) {
        //         if (message.containsKey("page")) {
        //           print(
        //             "Processed page ${message["page"]}/${message["pageCount"]}",
        //           );
        //         }
          //         if (message.containsKey("image")) {
          //           print(
          //             "Extracted image ${message["image"]}/${message["imageCount"]}",
          //           );
        //         }
        //         if (message.containsKey("done")) {
        //           print(
        //             "✅ Extraction finished. Output: ${message["outputDir"]}",
        //           );
        //         }
        //         if (message.containsKey("error")) {
        //           print("❌ Error: ${message["error"]}");
        //         }
        //       },
        //   );
        final receivePort = ReceivePort();

        await Isolate.spawn(
          extractPdfWorker,
          {
            "sendPort": receivePort.sendPort,
            "path": filePath,
            "outputDir": outputDir,
          },
        );

        await for (final msg in receivePort) {
          final progress = msg as Map<String, dynamic>;
          final currentProgress = state.progress[filePath]!;

          if (progress["error"] != null) {
            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress.copyWith(error: progress["error"], done: true),
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
            state = state.copyWith(progress: {
              ...state.progress,
              filePath: currentProgress.copyWith(
                currentPage: progress["page"],
                totalPages: progress["pageCount"],
              ),
            });
          }

          if (progress["image"] != null && progress["imageCount"] != null) {
            print(
              "Extracted image ${progress["image"]}/${progress["imageCount"]}",
            );
            state = state.copyWith(progress: {
              ...state.progress,
              filePath: currentProgress.copyWith(
                currentImage: progress["image"],
                totalImages: progress["imageCount"],
              ),
            });
          }

          if (progress["done"] == true) {
            state = state.copyWith(
              progress: {
                ...state.progress,
                filePath: currentProgress.copyWith(done: true, outputDir: progress["outputDir"]),
              },
              outputPaths: [...state.outputPaths, progress["outputDir"] ?? ""],
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

  // Future<String> _processSinglePdf(DropItem file) async {
  //     final pdfName = file.name;
  //     final pdfPath = file.path;
  //     final outputDir = '${directoryManager.getDirectory()}/$pdfName';
  //     print(outputDir);
  //     // Ensure the output directory exists
  //     if (!await Directory(outputDir).exists()) {
  //       await Directory(outputDir).create(recursive: true);
  //     }
  //     final output = repo.extractAllJson(pdfPath, true);
  //     final List<MuPdfPage> pages = output["pages"];

  //     Map<int, List<MuPdfBlock>> allTextBlocks = {};
  //     Map<int, List<MuPdfBlock>> imageBlocks = {};

  //     for (var page in pages) {
  //       allTextBlocks[page.pageNumber] = page.blocks.where((block) => block.type == "text").toList();
  //       imageBlocks[page.pageNumber] = page.blocks.where((block) => block.type == "image").toList();
  //     }

  //     // Match image blocks with their captions
  //     for (var entry in imageBlocks.entries) {
  //       final pageNumber = entry.key;
  //       final imgBlocks = entry.value;
  //       final textBlocks = allTextBlocks[pageNumber] ?? [];

  //       for (var imgBlock in imgBlocks) {
  //         final left = imgBlock.bbox.left;
  //         final top = imgBlock.bbox.top;
  //         final width = imgBlock.bbox.width;
  //         final height = imgBlock.bbox.height;

  //         Rect captionRect = Rect.fromLTWH(left - 10, height, width + 10, height + 75 );
  //         // Search for caption in textBlocks
  //         for (var textBlock in textBlocks) {
  //           if (textBlock.bbox.overlaps(captionRect)) {
  //             // Caption found
  //             imgBlock.caption = textBlock.lines?.map((line) => line.text).join(' ') ?? 'No Lines found';
  //             break;
  //           }
  //         }

  //         imgBlock.caption = imgBlock.caption ?? 'No Caption found';
  //       }
  //     }

  //     // Create image with caption
  //     final indexedImgBlocks = imageBlocks.values.expand((blocks) => blocks).indexed;
  //     for (var (index, imgBlock) in indexedImgBlocks) {
  //       final caption = imgBlock.caption ?? 'No Caption found while creating image';
  //       final base64Data = imgBlock.data;
  //       if (base64Data == null || base64Data.isEmpty) {
  //         continue; // Skip if no image data
  //       }
  //       // Decode the base64 string
  //       final bytes = base64Decode(base64Data);
  //       final originalImage = img.decodeImage(bytes);
  //       if (originalImage == null) {
  //         continue;
  //       }

  //       // Calculate new image dimensions (add space for caption)
  //       const captionHeight = 80;
  //       const padding = 20;
  //       final newHeight = originalImage.height + captionHeight + (padding * 2);

  //       // Create new image with white background
  //       final newImage = img.Image(
  //         width: originalImage.width,
  //         height: newHeight,
  //       );
  //       img.fill(newImage, color: img.ColorRgb8(255, 255, 255));

  //       // Copy original image to new image
  //       img.compositeImage(newImage, originalImage, dstX: padding, dstY: padding);

  //       // Add caption text
  //       _drawText(
  //         newImage,
  //         caption,
  //         padding,
  //         originalImage.height + padding + 20,
  //       );

  //       // Save the new image
  //       final imgPath = p.join(outputDir, 'image_$index.jpg');

  //       final newImageFile = File(imgPath);
  //       await newImageFile.writeAsBytes(img.encodePng(newImage));
  //     }

  //     return outputDir;
  // }




  // Simple text drawing (you might want to use a more sophisticated solution)
  void _drawText(img.Image image, String text, int x, int y) {
    final font = img.arial24;
    img.drawString(
      image,
      text,
      font: font,
      x: x,
      y: y,
      color: img.ColorRgb8(0, 0, 0),
    );
  }

  // Future<String> _processSinglePdf(DropItem file) async {
  //   print("this");
  //   print(file);
  //   final pdfPath = file.path;
  //   final mutoolPath = await _copyBinaryToTemp();
  //   print(mutoolPath);
  //   final outputDir = directoryManager.getDirectory();
  //   print(outputDir);
  //   // Ensure the mutool binary exists and is executable
  //   if (!await File(mutoolPath).exists()) {
  //     throw Exception('Mutool binary not found at $mutoolPath');
  //   }
  //   final result = await Process.run(mutoolPath, [
  //     'draw',
  //     '-F',
  //     'html',
  //     pdfPath,
  //   ], runInShell: Platform.isWindows);
  //   print("Next step");
  //   print(result);
  //   print(result.stderr);
  //   if (result.exitCode != 0) {
  //     throw Exception('Failed to process PDF: ${result.stderr}');
  //   }
  //   print(result.stdout);

  //   BeautifulSoup bs = BeautifulSoup(result.stdout);
  //   final images = bs.findAll('img');
  //   var outputIndex = 0;
  //   for (final imgEl in images) {
  //     final src = imgEl.attributes['src']; // base64 image string
  //     print("imgSrc");
  //     print(src);
  //     if (src == null || src.isEmpty) {
  //       continue;
  //     }
  //     final bytes = base64Decode(src.split(',').last);
  //     final image = img.decodeImage(bytes);
  //     if (image == null) {
  //       continue;
  //     }
      // final style = imgEl.attributes['style'];
      // final transformMatrix = style?.split(';').firstWhere(
      //   (s) => s.startsWith('transform:matrix('),
      //   orElse: () => '',
      // );
      // if (transformMatrix == null || transformMatrix.isEmpty) {
      //   continue;
      // }
      // final matrixValues = transformMatrix
      //     .replaceAll('transform:matrix(', '')
      //     .replaceAll(')', '')
      //     .split(',')
      //     .map((s) => double.tryParse(s.trim()) ?? 0.0)
      //     .toList();

      // final scaleX = matrixValues.isNotEmpty ? matrixValues[0] : 1.0;
      // final scaleY = matrixValues.length > 3 ? matrixValues[3] : 1.0;
      // final left = matrixValues.length > 4 ? matrixValues[4] : 0.0;
      // final top = matrixValues.length > 5 ? matrixValues[5] : 0.0;

      // final imageWidth = image.width * scaleX;
      // final imageHeight = image.height * scaleY;

    //   Save the scaled image to the output directory
    //   final outputPath = p.join(outputDir, 'image_${outputIndex++}.jpg');
    //   await File(outputPath).writeAsBytes(img.encodeJpg(image));
    // }

  //   return 'output_directory';
  // }

  // Get the appropriate mutool binary path
  // String _getMutoolPath() {
  //   if (Platform.isWindows) {
  //     return 'assets/mupdf/win/mutool.exe';
  //   } else if (Platform.isMacOS) {
  //     return 'assets/mupdf/mac/mutool';
  //   } else {
  //     throw UnsupportedError('Platform not supported');
  //   }
  // }

  // // Copy binary from assets to temporary directory
  // Future<String> _copyBinaryToTemp() async {
  //   final mutoolAssetPath = _getMutoolPath();
  //   final outputDir = directoryManager.getDirectory();
  //   try {
  //     final binary = await rootBundle.load(mutoolAssetPath);
  //     // Create temporary directory if it doesn't exist
  //     final tempDir = Directory("$outputDir/tmp");
  //     if (!await tempDir.exists()) {
  //       await tempDir.create(recursive: true);
  //     }

  //     final binaryName = Platform.isWindows ? 'mutool.exe' : 'mutool';
  //     final binaryFile = File(p.join(tempDir.path, binaryName));

  //     await binaryFile.writeAsBytes(binary.buffer.asUint8List());

  //     // Make executable on macOS/Linux
  //     if (!Platform.isWindows) {
  //       _makeExecutableWithFallback(binaryFile.path);
  //     }

  //     return binaryFile.path;
  //   } catch (e) {
  //     print('Failed to load mutool binary from assets: $e');
  //     throw Exception('Mutool binary not found in assets. Please check your pubspec.yaml and asset paths.');
  //   }
  // }


  void clearErrors() {
    state = state.copyWith(errors: []);
  }
}

final pdfExtractorScreenControllerProvider =
    StateNotifierProvider<PdfExtractorScreenController, PdfExtractorState>((ref) {
  final DirectoryManager directoryManager = ref.read(directoryManagerProvider.notifier);
  // final MuPdfRepository muPdfRepository = ref.read(muPdfRepositoryProvider);
  return PdfExtractorScreenController(directoryManager: directoryManager);
});
