// pdf_extractor_screen.dart
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:snag_report_extractor_app/src/constants/app_sizes.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/data/directory_manager.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_controller.dart';
import 'package:desktop_drop/desktop_drop.dart';

class PdfExtractorScreen extends ConsumerWidget {
  const PdfExtractorScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfExtractorControllerProvider = ref.read(pdfExtractorScreenControllerProvider.notifier);
    final pdfExtractorScreenState = ref.watch(pdfExtractorScreenControllerProvider);
    final directoryManager = ref.watch(directoryManagerProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Snag Report Extractor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: directoryManager),
              decoration: InputDecoration(
                labelText: "Output Directory",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    ref.read(directoryManagerProvider.notifier).selectDirectory();
                  },
                  icon: const Icon(Icons.folder_open),
                ),
              ),
              readOnly: true,
            ),
            gapH16,
            ListView.builder(
              shrinkWrap: true,
              itemCount: pdfExtractorScreenState.files.length,
              itemBuilder: (context, index) {
                final file = pdfExtractorScreenState.files[index];
                final progress = pdfExtractorScreenState.progress[file.path];

                return Card(
                  child: ListTile(
                    title: Text(file.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (progress != null) ...[
                          Text(
                            "Pages: ${progress.currentPage}/${progress.totalPages}",
                          ),
                          Text(
                            "Images: ${progress.currentImage}/${progress.totalImages}",
                          ),
                          if (progress.done)
                            Text(
                              "✅ Done",
                              style: TextStyle(color: Colors.green),
                            ),
                          if (progress.error != null)
                            Text(
                              "❌ ${progress.error}",
                              style: TextStyle(color: Colors.red),
                            ),
                          LinearProgressIndicator(
                            value: (progress.totalPages > 0)
                                ? progress.currentPage / progress.totalPages
                                : null,
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(pdfExtractorScreenControllerProvider.notifier)
                            .removeFromQueue(file);
                      },
                    ),
                  ),
                );
              },
            ),
            DropTarget(
              onDragDone: (detail) async {
                print(detail);
                final files = detail.files;
                if (files.isNotEmpty) {
                  print(files);
                  await pdfExtractorControllerProvider.addToQueue(files);
                }
              },
              child: GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    allowMultiple: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final files = result.files.map((file) {
                        final bytes = File(file.path!).readAsBytesSync();
                        return DropItemFile.fromData(
                          bytes,
                          name: file.name,
                          length: file.size,
                          mimeType: 'application/pdf',
                          path: file.path
                        );
                    });
                    await pdfExtractorControllerProvider.addToQueue(files.toList());
                  }
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text('Drop PDF files here or click to select'),
                  ),
                ),
              ),
            ),
            gapH16,
            ElevatedButton(
              onPressed: () async {
                await pdfExtractorControllerProvider.processPdfFiles();
              },
              child: const Text("Extract"),
            ),
          ],
        ),
      ),
    );
  }

}
