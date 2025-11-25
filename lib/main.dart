import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/gossamer_theme.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: GossamerApp()));
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
