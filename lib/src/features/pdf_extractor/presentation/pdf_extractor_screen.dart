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
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_file_card.dart';

class PdfExtractorScreen extends ConsumerWidget {
  const PdfExtractorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfExtractorControllerProvider = ref.read(
      pdfExtractorScreenControllerProvider.notifier,
    );
    final pdfExtractorScreenState = ref.watch(
      pdfExtractorScreenControllerProvider,
    );
    final directoryManager = ref.watch(directoryManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Snag Report Extractor')),
      body: SingleChildScrollView(
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
                    ref
                        .read(directoryManagerProvider.notifier)
                        .selectDirectory();
                  },
                  icon: const Icon(Icons.folder_open),
                ),
              ),
              readOnly: true,
            ),
            gapH16,
            DropTarget(
              onDragEntered: (detail) {
                pdfExtractorControllerProvider.startDragging();
              },
              onDragExited: (detail) {
                pdfExtractorControllerProvider.stopDragging();
              },
              onDragDone: (detail) async {
                final files = detail.files;
                if (files.isNotEmpty) {
                  pdfExtractorControllerProvider.addToQueue(files);
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
                        path: file.path,
                      );
                    });
                    pdfExtractorControllerProvider.addToQueue(files.toList());
                  }
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: pdfExtractorScreenState.isDragging
                          ? Colors.blue
                          : Colors.grey,
                      width: pdfExtractorScreenState.isDragging ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.upload_file,
                          size: 48,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Drag & Drop PDF files here or click to select",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            gapH16,
            ListView.builder(
              shrinkWrap: true,
              itemCount: pdfExtractorScreenState.files.length,
              itemBuilder: (context, index) {
                final file = pdfExtractorScreenState.files[index];
                final progress = pdfExtractorScreenState.progress[file.path];

                return PdfFileCard(file: file, progress: progress, onDelete: () {
                  pdfExtractorControllerProvider.removeFromQueue(file);
                });
              },
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
