import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RandomPickApp());
}

class RandomPickApp extends StatelessWidget {
  const RandomPickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤픽',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
