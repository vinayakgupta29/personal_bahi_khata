import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = true;
  late Timer _timer;
  // Toggle visibility every 2 seconds
  void _toggleFade() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // Start the timer to toggle the fade every 2 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      _toggleFade();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to prevent memory leaks
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          opacity: _isVisible
              ? 1.0
              : 0.0, // Opacity toggles between 1 (visible) and 0 (invisible)
          duration:
              const Duration(seconds: 1), // Duration of the fade animation
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
            ),
            width: 100,
            height: 100,
            child: Image.asset(
              'assets/app_icon.png', // Your app icon
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
