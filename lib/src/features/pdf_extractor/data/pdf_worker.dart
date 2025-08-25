import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:snag_report_extractor_app/src/features/pdf_extractor/domain/mupdf.dart';

import 'mupdf_repository.dart';

void extractPdfWorker(Map<String, dynamic> data) async {
  SendPort sendPort = data["sendPort"];
  String path = data["path"];
  String outputDir = data["outputDir"];
  final repo = MuPdfRepository.initialize();
  print("Repository initialized");
  try {
    final output = repo.extractAllJson(path, false);
    final pages = output["pages"] as List<MuPdfPage>;
    final totalPages = output["page_count"] as int;

    int imageCounter = 0;
    int totalImages = pages.fold(0, (sum, page) => sum + page.blocks.where((b) => b.type == "image").length);

    for (int pageNo = 1; pageNo <= totalPages; pageNo++) {
      final page = repo.extractPageJson(path, pageNo, true);
      sendPort.send({"page": pageNo, "pageCount": totalPages});

      for (final imgBlock in page.blocks.where((b) => b.type == "image")) {
        final base64Data = imgBlock.data;
        if (base64Data == null || base64Data.isEmpty) continue;

        final bytes = base64Decode(base64Data);
        final originalImage = img.decodeImage(bytes);
        if (originalImage == null) continue;

        final imgPath = p.join(outputDir, "image_${imageCounter++}.jpg");
        await File(imgPath).writeAsBytes(img.encodeJpg(originalImage));

        sendPort.send({"image": imageCounter, "imageCount": totalImages});
      }
    }

    sendPort.send({"done": true, "outputDir": outputDir});
  } catch (e) {
    sendPort.send({"error": e.toString()});
  } finally {
    // repo.dispose();
  }
}


// class PdfWorker {
//   static Future<void> extractPdf(SendPort sendPort, {
//     required String pdfPath,
//     required String outputDir,
//     required String fileName,
//   }) async {

//   final repo = MuPdfRepository.initialize();
//     try {
//       final output = repo.extractAllJson(pdfPath, false);
//       final pages = output["pages"] as List<MuPdfPage>;
//       final totalPages = output["page_count"] as int;
//       print(pages);
//       print(totalPages);
//       int imageCounter = 0;
//       int totalImages = pages.fold(0, (sum, page) => sum + page.blocks.where((b) => b.type == "image").length);

//       for (int pageNo = 1; pageNo <= totalPages; pageNo++) {
//         final page = repo.extractPageJson(pdfPath, pageNo, true);
//         sendPort.send({"page": pageNo, "pageCount": totalPages});

//         for (final imgBlock in page.blocks.where((b) => b.type == "image")) {
//           final base64Data = imgBlock.data;
//           if (base64Data == null || base64Data.isEmpty) continue;

//           Uint8List bytes = base64Decode(base64Data);
//           img.Image? originalImage = img.decodeImage(bytes);
//           if (originalImage == null) continue;

//           final imgPath = p.join(outputDir, "image_${imageCounter++}.jpg");
//           await File(imgPath).writeAsBytes(img.encodeJpg(originalImage));

//           bytes = Uint8List(0);
//           originalImage = null;
//           imgBlock.data = null;
//           // bytes.clear();
//           // originalImage = null;

//           sendPort.send({"image": imageCounter, "imageCount": totalImages});
//         }
//       }

//       sendPort.send({"done": true, "outputDir": outputDir});
//     } catch (e) {
//       sendPort.send({"error": e.toString()});
//     }
//   }
// }