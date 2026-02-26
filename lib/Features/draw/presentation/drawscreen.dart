import 'package:flutter/material.dart';
import 'models/stroke.dart';

class Drawscreen extends StatefulWidget {
  const Drawscreen({super.key});

  @override
  State<Drawscreen> createState() => _DrawscreenState();
}

class _DrawscreenState extends State<Drawscreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStrokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;

  final List<Color> _availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStrokes.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStrokes.removeLast());
      });
    }
  }

  void _clearAll() {
    setState(() {
      _strokes.clear();
      _redoStrokes.clear();
      _currentPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw Your Dream"),
        actions: [

          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? _undo : null,
            tooltip: "Undo",
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStrokes.isNotEmpty ? _redo : null,
            tooltip: "Redo",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _strokes.isNotEmpty ? _clearAll : null,
            tooltip: "Clear All",
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: GestureDetector(
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
                _redoStrokes = [];
              },
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,

                child: ClipRect(
                  child: CustomPaint(
                    painter: DrawPainter(
                        strokes: _strokes,
                        currentPoints: _currentPoints,
                        currentColor: _selectedColor,
                        currentBrushSize: _brushSize),
                  ),
                ),
              ),
            ),
          ),


          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
              ],
            ),
            child: Column(
              children: [
                
                Row(
                  children: [
                    const Icon(Icons.brush, size: 20),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1.0,
                        max: 20.0,
                        activeColor: _selectedColor,
                        onChanged: (value) {
                          setState(() {
                            _brushSize = value;
                          });
                        },
                      ),
                    ),
                    Text(_brushSize.toStringAsFixed(1)),
                  ],
                ),

                const SizedBox(height: 10),


                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (_selectedColor == color)
                                const BoxShadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
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

  DrawPainter({
    super.repaint,
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentBrushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }


    final paint = Paint()
      ..color = currentColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = currentBrushSize;

    for (int i = 0; i < currentPoints.length - 1; i++) {
      canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}