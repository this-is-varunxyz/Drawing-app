import 'dart:ui' as ui;
import 'package:flutter/material.dart';


abstract class Command {
  void draw(Canvas canvas);
}

class PathCommand extends Command {
  final Path path;
  final Paint paint;
  PathCommand(this.path, this.paint);

  @override
  void draw(Canvas canvas) => canvas.drawPath(path, paint);
}

class PointCommand extends Command {
  final Offset point;
  final Paint paint;
  PointCommand(this.point, this.paint);

  @override
  void draw(Canvas canvas) {
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill
      ..blendMode = paint.blendMode
      ..isAntiAlias = paint.isAntiAlias;
    canvas.drawCircle(point, paint.strokeWidth / 2, fillPaint);
  }
}

class CommandManager {
  final List<Command> commands = [];
  final List<Command> redoStack = [];

  void commit(Command c) {
    commands.add(c);
    redoStack.clear();
  }

  void undo() { if (commands.isNotEmpty) redoStack.add(commands.removeLast()); }
  void redo() { if (redoStack.isNotEmpty) commands.add(redoStack.removeLast()); }
  void clearAll() { commands.clear(); redoStack.clear(); }
}

Path _createSmoothedPath(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;

  if (pts.length < 3) {
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path;
  }

  const double divider = 3.0;
  final List<Offset> diff = List.filled(pts.length, Offset.zero);

  for (int i = 0; i < pts.length; i++) {
    if (i == 0) {
      final next = pts[i + 1];
      diff[i] = Offset((next.dx - pts[i].dx) / divider, (next.dy - pts[i].dy) / divider);
    } else if (i == pts.length - 1) {
      final prev = pts[i - 1];
      diff[i] = Offset((pts[i].dx - prev.dx) / divider, (pts[i].dy - prev.dy) / divider);
    } else {
      final prev = pts[i - 1];
      final next = pts[i + 1];
      diff[i] = Offset((next.dx - prev.dx) / divider, (next.dy - prev.dy) / divider);
    }
  }

  final List<Offset> shifted = [pts[0]];
  for (int i = 1; i < pts.length; i++) {
    shifted.add(Offset(pts[i].dx + diff[i].dx, pts[i].dy + diff[i].dy));
  }

  path.moveTo(shifted[0].dx, shifted[0].dy);
  for (int i = 1; i < shifted.length - 1; i += 2) {
    path.cubicTo(
      shifted[i - 1].dx, shifted[i - 1].dy,
      shifted[i].dx, shifted[i].dy,
      shifted[i + 1].dx, shifted[i + 1].dy,
    );
  }
  return path;
}

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  static const int _canvasW = 1080;
  static const int _canvasH = 1920;

  final CommandManager _commandManager = CommandManager();
  ui.Image? _workspaceImage;

  final List<Offset> _activePoints = [];
  Path _activePath = Path();

  final TransformationController _transformationController = TransformationController();
  int _pointersOnScreen = 0;
  bool _isZooming = false;

  Color _selectedColor = Colors.black;
  double _brushSize = 4.0;
  bool _isEraserMode = false;
  bool _isDrawingMode = true;

  bool _antiAliasing = false; 
  bool _smoothing = true;

  final List<Color> _availableColors = [
    Colors.black, Colors.red, Colors.blue, Colors.green,
    Colors.orange, Colors.purple, Colors.pink, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _renderWorkspace();
  }

  Future<void> _renderWorkspace() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _canvasW.toDouble(), _canvasH.toDouble()));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, _canvasW.toDouble(), _canvasH.toDouble()), Paint()..color = Colors.white);

    for (final cmd in _commandManager.commands) {
      cmd.draw(canvas);
    }
    
    final img = await recorder.endRecording().toImage(_canvasW, _canvasH);
    if (mounted) setState(() => _workspaceImage = img);
  }

  Paint _createBrushPaint() {
    final paint = Paint()
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = _antiAliasing;

    if (_isEraserMode) {
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.transparent;
    } else {
      paint.blendMode = BlendMode.srcOver;
      paint.color = _selectedColor;
    }
    return paint;
  }

  Offset _getCanvasPoint(Offset localPosition, Size widgetSize) {
    final scenePt = _transformationController.toScene(localPosition);
    final bx = (scenePt.dx / widgetSize.width) * _canvasW;
    final by = (scenePt.dy / widgetSize.height) * _canvasH;
    return Offset(bx, by);
  }

  void _onPointerDown(PointerEvent event, Size widgetSize) {
    _pointersOnScreen++;
    if (_pointersOnScreen >= 2) {
      _isZooming = true;
      setState(() {
        _activePoints.clear();
        _activePath = Path();
      });
      return;
    }

    if (!_isDrawingMode || _isZooming) return;

    final pt = _getCanvasPoint(event.localPosition, widgetSize);
    setState(() {
      _activePoints.clear();
      _activePoints.add(pt);
      _activePath = Path()..moveTo(pt.dx, pt.dy);
    });
  }

  void _onPointerMove(PointerEvent event, Size widgetSize) {
    if (!_isDrawingMode || _isZooming || _activePoints.isEmpty) return;

    final pt = _getCanvasPoint(event.localPosition, widgetSize);
    setState(() {
      _activePoints.add(pt);
      _activePath.lineTo(pt.dx, pt.dy);
    });
  }

  void _onPointerUp(PointerEvent event, Size widgetSize) {
    _pointersOnScreen--;
    if (_pointersOnScreen < 0) _pointersOnScreen = 0;
    if (_pointersOnScreen == 0) _isZooming = false;

    if (!_isDrawingMode || _activePoints.isEmpty) return;

    final paint = _createBrushPaint();

    if (_activePath.getBounds().size == Size.zero) {
      _commandManager.commit(PointCommand(_activePoints.first, paint));
    } else {
      Path finalPath = (_smoothing && _activePoints.length >= 3 && !_isEraserMode)
          ? _createSmoothedPath(_activePoints)
          : Path.from(_activePath);
      
      _commandManager.commit(PathCommand(finalPath, paint));
    }

    setState(() {
      _activePoints.clear();
      _activePath = Path();
    });
    
    _renderWorkspace();
  }

  void _undo() { _commandManager.undo(); _renderWorkspace(); }
  void _redo() { _commandManager.redo(); _renderWorkspace(); }
  void _clear() { _commandManager.clearAll(); _renderWorkspace(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Draw Your Dream'),
        actions: [
          IconButton(icon: const Icon(Icons.zoom_out_map), onPressed: () => _transformationController.value = Matrix4.identity()),
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.pan_tool : Icons.edit),
            onPressed: () => setState(() => _isDrawingMode = !_isDrawingMode),
          ),
          IconButton(icon: const Icon(Icons.undo), onPressed: _commandManager.commands.isNotEmpty ? _undo : null),
          IconButton(icon: const Icon(Icons.redo), onPressed: _commandManager.redoStack.isNotEmpty ? _redo : null),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _commandManager.commands.isNotEmpty ? _clear : null),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Listener(
                onPointerDown: (e) => _onPointerDown(e, widgetSize),
                onPointerMove: (e) => _onPointerMove(e, widgetSize),
                onPointerUp: (e) => _onPointerUp(e, widgetSize),
                onPointerCancel: (e) => _onPointerUp(e, widgetSize), 
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  transformationController: _transformationController,
                  minScale: 0.1, maxScale: 100.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  panEnabled: !_isDrawingMode,
                  scaleEnabled: true,
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        if (_workspaceImage != null)
                          RawImage(
                            image: _workspaceImage,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.fill,
                            filterQuality: _antiAliasing ? FilterQuality.medium : FilterQuality.none, 
                          ),
                        
                        if (_activePoints.isNotEmpty)
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: ActiveStrokePainter(
                              _activePath, 
                              _createBrushPaint(),
                              constraints.maxWidth / _canvasW,
                              constraints.maxHeight / _canvasH,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            color: const Color(0xFFEEEEEE),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(_isEraserMode ? Icons.auto_fix_normal : Icons.brush, size: 20),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1.0, max: 80.0,
                        activeColor: _isEraserMode ? Colors.grey : _selectedColor,
                        onChanged: (v) => setState(() => _brushSize = v),
                      ),
                    ),
                    Text(_brushSize.toStringAsFixed(1)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _antiAliasing = !_antiAliasing);
                            _renderWorkspace(); 
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _antiAliasing ? Colors.blueAccent.withOpacity(0.15) : Colors.transparent,
                              border: Border.all(color: _antiAliasing ? Colors.blueAccent : Colors.grey.shade400, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.blur_on, size: 16, color: _antiAliasing ? Colors.blueAccent : Colors.grey),
                                const SizedBox(width: 5),
                                Text('Anti-alias', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _antiAliasing ? Colors.blueAccent : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _smoothing = !_smoothing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _smoothing ? Colors.green.withOpacity(0.15) : Colors.transparent,
                              border: Border.all(color: _smoothing ? Colors.green : Colors.grey.shade400, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gesture, size: 16, color: _smoothing ? Colors.green : Colors.grey),
                                const SizedBox(width: 5),
                                Text('Smoothing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _smoothing ? Colors.green : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isEraserMode = !_isEraserMode),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        height: 36, width: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _isEraserMode ? Colors.black : Colors.grey.shade400, width: 3),
                        ),
                        child: const Icon(Icons.auto_fix_normal, size: 18),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _availableColors.map((color) {
                            final selected = !_isEraserMode && _selectedColor == color;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedColor = color;
                                _isEraserMode = false;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                height: 36, width: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: selected ? Colors.black : Colors.transparent, width: 3),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveStrokePainter extends CustomPainter {
  final Path path;
  final Paint paintObj;
  final double scaleX;
  final double scaleY;

  ActiveStrokePainter(this.path, this.paintObj, this.scaleX, this.scaleY);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scaleX, scaleY);

    if (paintObj.blendMode == BlendMode.clear) {
      final previewPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = paintObj.strokeWidth
        ..strokeCap = paintObj.strokeCap
        ..strokeJoin = paintObj.strokeJoin
        ..style = paintObj.style
        ..isAntiAlias = paintObj.isAntiAlias;
      canvas.drawPath(path, previewPaint);
    } else {
      canvas.drawPath(path, paintObj);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter old) => true;
}