import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'radar_screen.dart';
import 'inbox_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: extendBody allows the background to draw behind the floating nav bar
      extendBody: true, 
      
      body: _index == 0 ? const RadarScreen() : const InboxScreen(),
      
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30), // Raised from bottom
        height: 80,
        decoration: BoxDecoration(
          // Blur effect for true glassmorphism
          color: const Color(0xFF15151F).withOpacity(0.8),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(UniconsLine.rss_interface, "RADAR", 0),
            _buildNavItem(UniconsLine.envelope_alt, "INBOX", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)))
            ]
          ],
        ),
      ),
    );
  }
}
