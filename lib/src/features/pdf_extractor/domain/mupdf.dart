import 'dart:ui';

class MuPdfLineFont {
  final String name;
  final String family;
  final String weight;
  final String style;
  final double size;

  MuPdfLineFont({
    required this.name,
    required this.family,
    required this.weight,
    required this.style,
    required this.size,
  });

  factory MuPdfLineFont.fromJson(Map<String, dynamic> json) {
    return MuPdfLineFont(
      name: json['name'] as String,
      family: json['family'] as String,
      weight: json['weight'] as String,
      style: json['style'] as String,
      size: (json['size'] as num).toDouble(),
    );
  }
}

class MuPdfLine {
  final String text;
  final Rect bbox;
  final MuPdfLineFont font;

  MuPdfLine({required this.text, required this.bbox, required this.font});

  factory MuPdfLine.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as Map<String, dynamic>;
    return MuPdfLine(
      text: json['text'] as String,
      bbox: Rect.fromLTWH(
        (bbox['x'] as num).toDouble(),
        (bbox['y'] as num).toDouble(),
        (bbox['w'] as num).toDouble(),
        (bbox['h'] as num).toDouble(),
      ),
      font: MuPdfLineFont.fromJson(json['font'] as Map<String, dynamic>),
    );
  }
}

class MuPdfBlock {
  final String type;
  final Rect bbox;
  final List<MuPdfLine>? lines;
  String? data;
  String? caption;

  MuPdfBlock({
    required this.type,
    required this.bbox,
    this.lines,
    this.data,
    this.caption,
  });

  factory MuPdfBlock.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List?)
        ?.map((line) => MuPdfLine.fromJson(line))
        .toList();
    final bbox = json['bbox'] as Map<String, dynamic>;

    return MuPdfBlock(
      type: json['type'] as String,
      bbox: Rect.fromLTWH(
        (bbox['x'] as num).toDouble(),
        (bbox['y'] as num).toDouble(),
        (bbox['w'] as num).toDouble(),
        (bbox['h'] as num).toDouble(),
      ),
      lines: lines,
      data: json['data'] as String?,
    );
  }
}

class MuPdfPage {
  final int pageNumber;
  final List<MuPdfBlock> blocks;

  MuPdfPage({required this.pageNumber, required this.blocks});

  factory MuPdfPage.fromJson(int pageNumber, Map<String, dynamic> json) {
    return MuPdfPage(
      pageNumber: pageNumber,
      blocks: (json['blocks'] as List)
          .map((block) => MuPdfBlock.fromJson(block))
          .toList(),
    );
  }
}
