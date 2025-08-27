import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:snag_report_extractor_app/src/features/pdf_extractor/presentation/pdf_extractor_state.dart';

class PdfFileCard extends StatelessWidget {
  final DropItem file;
  final PdfFileProgress? progress;
  final VoidCallback? onDelete;

  const PdfFileCard({
    super.key,
    required this.file,
    this.progress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // final eta = progress?.remainingTime;
    // print('ETA');
    // print(eta);
    final progressRatio = (progress != null && progress?.error == null)
        ? (progress!.totalPages > 0)
              ? progress!.currentPage / progress!.totalPages
              : null
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with filename + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // if (progress != null && eta != null && progress!.done == false)
                //     Chip(
                //     label: Text(
                //       eta.inMinutes > 0
                //         ? "ETA: ${eta.inMinutes}m ${eta.inSeconds % 60}s"
                //         : "ETA: ${eta.inSeconds % 60}s",
                //     ),
                //     backgroundColor: Colors.orange.shade100,
                //     labelStyle: const TextStyle(color: Colors.orange),
                //   ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                  tooltip: "Remove file",
                ),
              ],
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (progress == null)
                  Chip(
                    label: const Text("In Queue"),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: const TextStyle(color: Colors.grey),
                  )
                else if (progress!.done && progress!.error == null)
                  Chip(
                    label: const Text("Complete"),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: const TextStyle(color: Colors.green),
                  )
                else if (progress!.error != null)
                  Chip(
                    label: Text("Failed"),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
                if (progress != null) ...[
                  Chip(
                    label: Text(
                      "Pages ${progress!.currentPage}/${progress!.totalPages}",
                    ),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(color: Colors.blue),
                  ),
                  Chip(
                    label: Text(
                      "Images ${progress!.currentImage}/${progress!.totalImages}",
                    ),
                    backgroundColor: Colors.purple.shade50,
                    labelStyle: const TextStyle(color: Colors.purple),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.grey.shade200,
              color: progress != null && progress!.done
                  ? Colors.green
                  : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
