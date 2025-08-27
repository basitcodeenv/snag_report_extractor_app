import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:snag_report_extractor_app/src/features/pdf_extractor/domain/mupdf.dart';

import 'mupdf_repository.dart';

void _drawText(img.Image image, String text, int x, int y) {
  final font = img.arial24;

  img.drawString(
    image,
    text,
    font: font,
    x: x,
    y: y,
    color: img.ColorRgb8(0, 0, 0),
    wrap: true,
  );
}

Future<void> extractPdfWorker(Map<String, dynamic> data) async {
  SendPort sendPort = data["sendPort"];
  String path = data["path"];
  String outputDir = data["outputDir"];
  final repo = MuPdfRepository.initialize();
  print("Repository initialized");
  try {
    final output = repo.extractAllJson(path, false);
    final pages = output["pages"] as List<MuPdfPage>;
    final totalPages = output["page_count"] as int;

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

    int imgIndex = 0;
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
          bottom + 75,
        );
        // Search for caption in textBlocks
        for (var textBlock in textBlocks) {
          final lines = textBlock.lines;

          if (lines == null) {
            continue;
          }

          for (var line in lines) {
            if (captionRect.overlaps(line.bbox)) {
              // Caption found
              imageCaptions[imgIndex] = line.text;
              break;
            }
          }

          if (captionRect.overlaps(textBlock.bbox)) {
            // Caption found
            imageCaptions[imgIndex] =
                textBlock.lines?.map((line) => line.text).join(' ') ??
                'Illustrated Above';
            break;
          }
        }

        imageCaptions[imgIndex] =
            imageCaptions[imgIndex] ?? 'Illustrated Above';
        imgIndex++;
      }
    }

    int imageCounter = 0;
    int totalImages = imageBlocks.values.fold(
      0,
      (sum, blocks) => sum + blocks.length,
    );

    imgIndex = 0;

    for (int pageNo = 1; pageNo <= totalPages; pageNo++) {
      final page = repo.extractPageJson(path, pageNo, true);
      sendPort.send({"page": pageNo, "pageCount": totalPages});

      for (final imgBlock in page.blocks.where((b) => b.type == "image")) {
        final base64Data = imgBlock.data;
        if (base64Data == null || base64Data.isEmpty) continue;

        final caption = imageCaptions[imgIndex] ?? 'No Caption found';

        final bytes = base64Decode(base64Data);
        final originalImage = img.decodeImage(bytes);
        if (originalImage == null) continue;

        // Calculate new image dimensions (add space for caption)
        const captionHeight = 60;
        const padding = 10;
        final newHeight = originalImage.height + captionHeight + (padding * 2);

        // Create new image with white background
        final newImage = img.Image(
          width: originalImage.width,
          height: newHeight,
        );
        img.fill(newImage, color: img.ColorRgb8(255, 255, 255));

        // Copy original image to new image
        img.compositeImage(newImage, originalImage);

        // Add caption text
        _drawText(
          newImage,
          caption,
          padding,
          originalImage.height + padding + 10,
        );

        final imgPath = p.join(outputDir, "image_${imageCounter++}.jpg");

        final newImageFile = File(imgPath);
        await newImageFile.writeAsBytes(img.encodePng(newImage));

        sendPort.send({"image": imageCounter, "imageCount": totalImages});
        imgIndex++;
      }
    }

    sendPort.send({"done": true, "outputDir": outputDir});
  } catch (e) {
    print("PDF Worker Error");
    print(e);
    sendPort.send({"error": e.toString()});
  }
}
