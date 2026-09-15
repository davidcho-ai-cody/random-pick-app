import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    AdService.loadAd();
  }
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
