import 'package:flutter/material.dart';
import 'package:flutterapp/Features/draw/presentation/drawscreen.dart';
import 'package:flutterapp/Features/home/presentation/homescreen.dart';
import 'package:flutterapp/Features/splash/presentation/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Welcome to Flutter",
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      initialRoute: "/", 
      routes: {
        '/': (context) => const Splashscreen(), 
        '/home': (context) => const Homescreen(),
        '/draw': (context) => const DrawScreen(),
      },
    );
  }
}