import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Homescreen extends StatelessWidget {
  const Homescreen ({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Drawings"),
      ),
      body: Center(
        child: ElevatedButton(onPressed: (){Navigator.pushNamed(context, '/draw');}, child: const Text('Create New drawihng')),
      ),
    );
  }
}