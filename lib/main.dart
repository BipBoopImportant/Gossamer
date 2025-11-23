import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemChrome
import 'theme/gossamer_theme.dart';
import 'screens/home_shell.dart';

void main() {
  // 1. Initialize binding so we can talk to the OS before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Make System Bars Transparent (Edge-to-Edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // White icons for Dark BG
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const GossamerApp());
}

class GossamerApp extends StatelessWidget {
  const GossamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gossamer',
      theme: GossamerTheme.darkTheme,
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
