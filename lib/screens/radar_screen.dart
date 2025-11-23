import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unicons/unicons.dart';
import 'settings_sheet.dart';
import 'compose_screen.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const ComposeScreen()));
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(UniconsLine.plus, color: Colors.white),
        label: const Text("NEW MESSAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF2A2A3D), Color(0xFF050507)],
                  stops: [0.0, 1.0]
                ),
              ),
            ),
          ),
          Center(child: _buildRipples()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [const Color(0xFF6C63FF).withOpacity(0.3), Colors.transparent],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF15151F),
                        border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                      ),
                      child: const Icon(UniconsLine.cube, size: 40, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text("MESH ACTIVE", style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14)),
                const SizedBox(height: 8),
                Text("Scanning frequency 2.4GHz...", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
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

  Widget _buildRipples() {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 300, height: 300,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.03), width: 1)),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: Duration(seconds: 3 + index)).fadeOut(duration: Duration(seconds: 3 + index));
      }),
    );
  }
}
