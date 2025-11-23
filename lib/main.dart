import 'package:flutter/material.dart';
import 'theme/gossamer_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unicons/unicons.dart';

void main() {
  runApp(const GossamerApp());
}

class GossamerApp extends StatelessWidget {
  const GossamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gossamer',
      theme: GossamerTheme.darkTheme,
      home: const RadarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("GOSSAMER", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(UniconsLine.cog), onPressed: () {})],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF1E1E2C), Color(0xFF050507)],
                ),
              ),
            ),
          ),
          // Ripples
          ...List.generate(3, (index) => Container(
            width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.05))),
          ).animate(onPlay: (c) => c.repeat()).scale(duration: Duration(seconds: 3+index)).fadeOut(duration: Duration(seconds: 3+index))),
          
          // Core
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              border: Border.all(color: const Color(0xFF6C63FF), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)]
            ),
            child: const Icon(UniconsLine.cube, size: 40, color: Colors.white),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white54),
          
          Positioned(
            bottom: 150,
            child: Text("MESH ACTIVE", style: TextStyle(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, letterSpacing: 2)),
          )
        ],
      ),
    );
  }
}
