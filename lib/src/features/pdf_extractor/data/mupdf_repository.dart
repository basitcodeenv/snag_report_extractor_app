import 'dart:convert';
import 'dart:io';

import 'package:snag_report_extractor_app/src/features/pdf_extractor/domain/mupdf.dart';
import 'package:snag_report_extractor_app/src/logging/talker.dart';

class MuPdfRepository {
  final String mutoolPath;

  MuPdfRepository._(this.mutoolPath);

  static MuPdfRepository initialize() {
    String mutool = '';

    if (Platform.isWindows) {
      mutool = 'mutool.exe';
    }
    if (Platform.isMacOS) {
      mutool = '/Users/mac/Documents/Projects/mupdf/build/release/mutool';
    }

    return MuPdfRepository._(mutool);
  }

  Future<int> getPageCount(String pdfPath) async {
    var result = await Process.run(mutoolPath, ['info', pdfPath]);
    if (result.exitCode == 0) {
      // Parse the output to find the page count
      var output = result.stdout as String;
      var pageCount = _parsePageCount(output);
      return pageCount;
    } else {
      talker.error('Failed to get page count for $pdfPath: ${result.stderr}');
      throw Exception('Failed to get page count');
    }
  }

  int _parsePageCount(String output) {
    // Implement parsing logic based on mutool output format
    var lines = output.split('\n');
    for (var line in lines) {
      if (line.startsWith('Pages:')) {
        return int.parse(line.split(':')[1].trim());
      }
    }
    talker.error('Page count not found in output');
    throw Exception('Page count not found in output');
  }

  Future<List<String>> extractImages(
    String pdfPath,
    String outDir,
    int pageNumber,
  ) async {
    var result = await Process.run(mutoolPath, [
      'image',
      '-o',
      outDir,
      pdfPath,
      pageNumber.toString(),
    ]);
    if (result.exitCode == 0) {
      // Parse the output to find the extracted image paths
      var output = result.stdout as String;
      var imagePaths = _parseImagePaths(output);
      return imagePaths;
    } else {
      talker.error('Failed to extract images for $pdfPath: ${result.stderr}');
      throw Exception('Failed to extract images for $pdfPath:\n ${result.stderr}');
    }
  }

  List<String> _parseImagePaths(String output) {
    // Implement parsing logic based on mutool output format
    var lines = output.split('\n');
    var imagePaths = <String>[];
    for (var line in lines) {
      if (line.startsWith('page-')) {
        imagePaths.add(line.trim());
      }
    }
    return imagePaths;
  }

  Future<List<MuPdfPage>> extractAll(String pdfPath) async {
    try {
      var result = await Process.run(mutoolPath, [
        'draw',
        '-F',
        'stext.json',
        pdfPath,
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final json = jsonDecode(output) ;
        final pages = (json['pages'] as List)
            .asMap()
            .entries
            .map((entry) {
              int pageNo = entry.key + 1;
              return MuPdfPage.fromJson(pageNo, entry.value as Map<String, dynamic>);
            })
            .toList();
        return pages;
      } else {
        talker.error('Failed to extract pages for $pdfPath: ${result.stderr}');
        throw Exception(
          'Failed to extract pages for $pdfPath:\n ${result.stderr}',
        );
      }
    } catch (e, stackTrace) {
      talker.error('Error extracting pages for $pdfPath: $e', stackTrace);
      rethrow;
    }
  }

  Future<MuPdfPage> extractPage(String pdfPath, int pageNumber) async {
    var result = await Process.run(mutoolPath, [
      'draw',
      '-F',
      'stext.json',
      pdfPath,
      pageNumber.toString(),
    ]);
    if (result.exitCode == 0) {
      final output = result.stdout as String;
      final json = jsonDecode(output) as Map<String, dynamic>;
      if (json['pages'] == null || json['pages'].isEmpty) {
        talker.error('No pages found in output');
        throw Exception('No pages found in output');
      }
      final muPdfPage = MuPdfPage.fromJson(pageNumber, json['pages'][0]);
      return muPdfPage;
    } else {
      talker.error('Failed to extract page for $pdfPath, page $pageNumber: ${result.stderr}');
      throw Exception('Failed to extract page for $pdfPath, page $pageNumber:\n ${result.stderr}');
    }
  }
}
