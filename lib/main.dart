import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RandomPickApp(initialization: _initializeServices()));
}

Future<void> _initializeServices() async {
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    AdService.loadAd();
  }
}

class RandomPickApp extends StatelessWidget {
  const RandomPickApp({super.key, this.initialization});

  final Future<void>? initialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤픽',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: initialization == null
          ? const HomeScreen()
          : BrandingSplashScreen(initialization: initialization!),
    );
  }
}

class BrandingSplashScreen extends StatefulWidget {
  const BrandingSplashScreen({
    required this.initialization,
    super.key,
  });

  final Future<void> initialization;

  @override
  State<BrandingSplashScreen> createState() => _BrandingSplashScreenState();
}

class _BrandingSplashScreenState extends State<BrandingSplashScreen> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _completeInitialization();
  }

  Future<void> _completeInitialization() async {
    try {
      await widget.initialization;
    } catch (_) {
      // Optional services must never prevent the app from reaching Home.
    }
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const HomeScreen();
    }

    return const Scaffold(
      backgroundColor: Color(0xFFF7F5FC),
      body: SafeArea(
        child: Center(
          child: Image(
            image: AssetImage('assets/images/branding/splash_brand.png'),
            fit: BoxFit.contain,
            semanticLabel: '랜덤픽 시작 화면',
          ),
        ),
      ),
    );
  }
}
