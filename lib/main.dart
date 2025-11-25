import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/gossamer_theme.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Check Onboarding State
  final prefs = await SharedPreferences.getInstance();
  final bool onboarded = prefs.getBool('onboarding_complete') ?? false;

  runApp(ProviderScope(child: GossamerApp(onboarded: onboarded)));
}

class GossamerApp extends ConsumerWidget {
  final bool onboarded;
  const GossamerApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If onboarded, trigger auto-login in background
    if (onboarded) {
      ref.read(chatProvider.notifier).attemptAutoLogin();
    }

    return MaterialApp(
      title: 'Gossamer',
      theme: GossamerTheme.darkTheme,
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
