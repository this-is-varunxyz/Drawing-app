import 'package:flutter/material.dart';

import 'models/stroke.dart';

class Drawscreen extends StatefulWidget {
  const Drawscreen({super.key});

  @override
  State<Drawscreen> createState() => _DrawscreenState();
}

class _DrawscreenState extends State<Drawscreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStockes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw Your Dream"),
      ),
      body: Column(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentPoints.add(details.localPosition);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPoints.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _strokes.add(Stroke(
                    points: List.from(_currentPoints),
                    color: _selectedColor,
                    brushSize: _brushSize));
              });
              _currentPoints = [];
              _redoStockes = [];
            },
            child: CustomPaint(
              painter: DrawPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentBrushSize: _brushSize),
            ),
          )
        ],
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentBrushSize;

  DrawPainter(
      {super.repaint,
        required this.strokes,
        required this.currentPoints,
        required this.currentColor,
        required this.currentBrushSize});
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}