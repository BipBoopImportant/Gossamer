import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:unicons/unicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/store.dart';
import 'home_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _pinController = TextEditingController();
  int _step = 0; // 0: Welcome, 1: PIN, 2: Loading

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: Stack(
        children: [
          // Background Gradient
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
          
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return Column(
          key: const ValueKey(0),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(UniconsLine.cube, size: 80, color: Colors.white).animate().scale(duration: 1.seconds),
            const SizedBox(height: 32),
            const Text("GOSSAMER", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white)),
            const SizedBox(height: 16),
            Text("The Decentralized Digital Aether.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("CREATE IDENTITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(UniconsLine.lock, size: 60, color: Color(0xFF6C63FF)),
            const SizedBox(height: 32),
            const Text("SECURE YOUR NODE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            const Text("Enter a PIN to encrypt your identity.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Colors.white, letterSpacing: 8),
              maxLength: 4,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _finalizeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("GENERATE KEYS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00F0FF)),
            const SizedBox(height: 32),
            Text("Generating Entropy...", style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 2)),
          ],
        );
      default:
        return Container();
    }
  }

  Future<void> _finalizeSetup() async {
    if (_pinController.text.length < 4) return;
    
    setState(() => _step = 2);
    
    try {
      // 1. Initialize Rust Core with PIN
      final notifier = ref.read(chatProvider.notifier);
      await notifier.initializeWithPin(_pinController.text);
      
      // 2. Save complete flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await prefs.setString('user_pin', _pinController.text); // In prod, use SecureStorage!
      
      // 3. Navigate
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomeShell()));
      }
    } catch (e) {
      // Handle error
    }
  }
}
