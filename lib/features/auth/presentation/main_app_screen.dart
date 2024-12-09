// lib/screens/main_app_screen.dart

import 'package:flutter/material.dart';

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main App'),
        backgroundColor: const Color(0xFF061535),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Main!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Onest',
          ),
        ),
      ),
      backgroundColor: const Color(0xFF061535),
    );
  }
}
