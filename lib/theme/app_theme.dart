import 'package:flutter/material.dart';

/// PLAY YOUR NEXT WORLD 브랜드 톤(딥 바이올렛 계열)의 기본 테마.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF6750E5);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
