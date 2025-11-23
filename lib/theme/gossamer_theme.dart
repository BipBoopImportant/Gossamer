import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GossamerTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
      primary: const Color(0xFF6C63FF),
      secondary: const Color(0xFF00F0FF),
      surface: const Color(0xFF0F0F13),
      background: const Color(0xFF050507),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: const Color(0xFF050507),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  );
}
