import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 결과 화면에서 홈으로 돌아갈 때 보여주는 전면광고를 관리한다.
///
/// 지금은 구글 공식 테스트 광고 단위 ID를 쓰고 있다. 실제 출시 전에는
/// [_androidAdUnitId] / [_iosAdUnitId]만 AdMob 콘솔에서 발급받은 실제
/// 광고 단위 ID로 교체하면 된다.
class AdService {
  AdService._();

  static const _androidAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  static String get _adUnitId =>
      Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;

  static InterstitialAd? _ad;

  /// 다음에 보여줄 전면광고를 미리 로드해둔다. 웹은 플러그인이 지원하지
  /// 않으므로 아무 것도 하지 않는다.
  static void loadAd() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  /// 로드된 광고가 있으면 보여준 뒤 [proceed]를 실행하고, 없으면 사용자를
  /// 기다리게 하지 않고 바로 [proceed]를 실행한다. 화면 전환이 광고 로드
  /// 성공 여부에 발목 잡히지 않도록 하기 위함이다.
  static void showThenProceed(VoidCallback proceed) {
    final ad = _ad;
    if (kIsWeb || ad == null) {
      proceed();
      return;
    }

    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
        proceed();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadAd();
        proceed();
      },
    );
    ad.show();
  }
}
