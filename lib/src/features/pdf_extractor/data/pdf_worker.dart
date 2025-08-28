import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:snag_report_extractor_app/src/features/pdf_extractor/domain/mupdf.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/mupdf_repository.dart';


Future<void> extractPdfWorker(Map<String, dynamic> data) async {
  SendPort sendPort = data["sendPort"];
  String path = data["path"];
  String outputDir = data["outputDir"];
  final tmpDir = "$outputDir/.tmp";
  final repo = MuPdfRepository.initialize();
  print("Repository initialized");
  try {
    final totalPages = await repo.getPageCount(path);
    sendPort.send({"page": 0, "pageCount": totalPages});

    final pages = await repo.extractAll(path);

    Map<int, List<MuPdfBlock>> allTextBlocks = {};
    final imageBlocks = <int, List<MuPdfBlock>>{};
    final imageCaptions = <int, String>{};
    for (var page in pages) {
      allTextBlocks[page.pageNumber] = page.blocks
          .where((block) => block.type == "text")
          .toList();
      imageBlocks[page.pageNumber] = page.blocks
          .where((b) => b.type == "image")
          .toList();
    }

    int imgCapIndex = 0;
    for (var entry in imageBlocks.entries) {
      final pageNumber = entry.key;
      final imgBlocks = entry.value;
      final textBlocks = allTextBlocks[pageNumber] ?? [];

      for (var imgBlock in imgBlocks) {
        final top = imgBlock.bbox.top;
        final bottom = imgBlock.bbox.bottom;
        final left = imgBlock.bbox.left;
        final right = imgBlock.bbox.right;

        Rect captionRect = Rect.fromLTRB(
          left - 10,
          bottom,
          right + 10,
          bottom + 55,
        );
        // Search for caption in textBlocks
        for (var textBlock in textBlocks) {
          final lines = textBlock.lines;

          if (lines == null) {
            continue;
          }

          for (var line in lines) {
            if (captionRect.overlaps(line.bbox) && line.font.size == 10) {
              // Caption found
              imageCaptions[imgCapIndex] = line.text;
              break;
            }
          }
        }

        imageCaptions[imgCapIndex] =
            imageCaptions[imgCapIndex] ?? 'Illustrated Above';
        imgCapIndex++;
      }
    }

    int imageCounter = 1;
    int totalImages = imageBlocks.values.fold(
      0,
      (sum, blocks) => sum + blocks.length,
    );

    imgCapIndex = 0;

    for (int pageNo = 1; pageNo <= totalPages; pageNo++) {
      final imgNames = await repo.extractImages(path, tmpDir, pageNo);
      sendPort.send({"page": pageNo, "pageCount": totalPages});

      final pageImgBlocks = imageBlocks[pageNo] ?? [];
      for (int imgNo = 0; imgNo < pageImgBlocks.length; imgNo++) {
        final caption = imageCaptions[imgCapIndex] ?? 'No Caption found';
        final tmpImgPath = '$tmpDir/${imgNames[imgNo]}';
        final bytes = await File(tmpImgPath).readAsBytes();

        // 🔹 Send image bytes + caption to main isolate
        sendPort.send({
          "imageBytes": bytes,
          "caption": caption,
          "imgCount": imageCounter++,
          "totalImages": totalImages,
        });

        imgCapIndex++;
      }
    }

    sendPort.send({"done": true, "outputDir": outputDir});
  } catch (e) {
    sendPort.send({"error": e.toString()});
  } finally {
    // Cleanup
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
  }
}
