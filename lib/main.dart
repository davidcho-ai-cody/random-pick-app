import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RandomPickApp());
  unawaited(_initializeServices());
}

Future<void> _initializeServices() async {
  try {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      AdService.markInitialized();
      AdService.loadAd();
    }
  } catch (_) {
    // Optional services must never prevent the app from reaching Home.
  }
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
