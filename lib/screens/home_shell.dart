import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'radar_screen.dart';
import 'inbox_screen.dart';
import 'identity_screen.dart';

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
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          RadarScreen(),
          InboxScreen(),
          IdentityScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF15151F).withOpacity(0.9),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(UniconsLine.rss_interface, "RADAR", 0),
            _buildNavItem(UniconsLine.envelope_alt, "INBOX", 1),
            _buildNavItem(UniconsLine.user_circle, "ME", 2),
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : Colors.grey, size: 20),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF), fontSize: 12))
            ]
          ],
        ),
      ),
    );
  }
}
