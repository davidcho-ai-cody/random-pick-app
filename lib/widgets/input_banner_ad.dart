import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// 입력 화면에서만 사용하는 배너. 키보드가 열리면 광고를 제거하고,
/// 닫히면 새 광고를 요청한다. 실패 시 공간을 차지하지 않는다.
class InputBannerAd extends StatefulWidget {
  const InputBannerAd({super.key});

  @override
  State<InputBannerAd> createState() => _InputBannerAdState();
}

class _InputBannerAdState extends State<InputBannerAd> {
  BannerAd? _ad;
  bool _keyboardVisible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AdService.initialized.addListener(_onAvailabilityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_keyboardVisible == keyboardVisible && _ad != null) return;
    _keyboardVisible = keyboardVisible;
    if (_keyboardVisible) {
      _disposeAd();
    } else {
      _loadIfPossible();
    }
  }

  void _onAvailabilityChanged() {
    if (mounted && !_keyboardVisible) _loadIfPossible();
  }

  void _loadIfPossible() {
    if (kIsWeb || !AdService.initialized.value || _ad != null || _loading) {
      return;
    }
    _loading = true;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loading = false;
          if (!mounted || _keyboardVisible) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, _) {
          _loading = false;
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  void _disposeAd() {
    final ad = _ad;
    _ad = null;
    ad?.dispose();
  }

  @override
  void dispose() {
    AdService.initialized.removeListener(_onAvailabilityChanged);
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (_keyboardVisible || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
