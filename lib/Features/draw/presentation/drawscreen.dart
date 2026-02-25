import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Drawscreen extends StatefulWidget {
  const Drawscreen ({super.key});

  @override
  State<Drawscreen> createState() => _DrawscreenState();
}

class _DrawscreenState extends State<Drawscreen> {
  List<Stroke> _strokes = [];
  List<Stroke> _redoStockes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black
  @override
  Widget build(BuildContext context){
    return const Placeholder();
  }
}