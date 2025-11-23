import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unicons/unicons.dart';
import 'settings_sheet.dart';
import 'compose_screen.dart';
import 'dart:math' as math;

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});
  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Removed FAB. Moved button to body for better visibility.
      body: Stack(
        children: [
          // 1. Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [Color(0xFF1E1E2C), Color(0xFF050507)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Content (Centered)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // RADAR STACK (Groups Beam + Icon so they are perfectly aligned)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Beam (Confined to this box)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          return CustomPaint(
                            size: const Size(300, 300),
                            painter: RadarPainter(_controller.value),
                          );
                        },
                      ),
                      
                      // Ripples
                      ...List.generate(3, (index) => Container(
                        width: 250, height: 250,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.03), width: 1)),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: Duration(seconds: 3 + index)).fadeOut(duration: Duration(seconds: 3 + index))),

                      // The Core Icon
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF15151F),
                          border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.6), blurRadius: 40)]
                        ),
                        child: const Icon(UniconsLine.cube, size: 40, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text("MESH ONLINE", style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16)).animate().fadeIn().shimmer(duration: 3.seconds),
                const SizedBox(height: 8),
                Text("Relay: wss://damus.io", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'monospace')),
                
                const SizedBox(height: 30),

                // NEW MESSAGE BUTTON (Moved here for visibility)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ComposeScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Color(0xFF6C63FF))),
                      elevation: 0,
                    ),
                    icon: const Icon(UniconsLine.plus, color: Colors.white),
                    label: const Text("NEW MESSAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),

          // 3. Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("GOSSAMER", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.white)),
                    IconButton(
                      icon: const Icon(UniconsLine.cog, color: Colors.white),
                      onPressed: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (c) => const SettingsSheet()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double rotation;
  RadarPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, const Color(0xFF6C63FF).withOpacity(0.2), Colors.transparent],
        stops: const [0.0, 0.25, 1.0],
        startAngle: 0.0,
        endAngle: math.pi / 2,
        transform: GradientRotation(rotation * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => oldDelegate.rotation != rotation;
}
