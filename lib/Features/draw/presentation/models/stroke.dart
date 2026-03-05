import 'dart:ui';

class Stroke {
  final Path path;
  final Color color;
  final double brushSize;
  final bool isEraser;

  Stroke({
    required this.path,
    required this.color,
    required this.brushSize,
    this.isEraser = false,
  });
}