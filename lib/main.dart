import 'package:flutter/material.dart';
import 'theme/gossamer_theme.dart';
import 'screens/home_shell.dart'; // We use the Shell now

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
      home: const HomeShell(), // Points to the Navigation Wrapper
      debugShowCheckedModeBanner: false,
    );
  }
}
