import 'package:flutter/material.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState(); // Best practice is to call super.initState() first

    // 1. Initialize the controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 2. Initialize the animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // 3. Start the animation
    _controller.forward();

    // 4. Navigate to Home after a 3-second delay
    Future.delayed(const Duration(seconds: 3), () {
      // Fixed typo: Navigator.pushReplacementNamed
      // Changed route to '/home' to prevent an infinite splash screen loop
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  // Always dispose of AnimationControllers to prevent memory leaks!
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // You must include a build method to render the UI on the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Wrapping a widget in FadeTransition applies your fade animation
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            "My Splash Screen",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}