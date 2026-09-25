import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 전면광고가 실제 노출된 시각을 영속화해 앱 재시작 후에도 쿨다운을 지킨다.
class InterstitialCooldown {
  InterstitialCooldown(this.preferences, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const duration = Duration(seconds: 90);
  static const storageKey = 'last_interstitial_shown_at';

  final SharedPreferences preferences;
  final DateTime Function() _now;

  bool get canShow {
    final stored = preferences.getString(storageKey);
    final lastShown = stored == null ? null : DateTime.tryParse(stored);
    if (lastShown == null) return true;
    return !_now().toUtc().isBefore(lastShown.toUtc().add(duration));
  }

  Future<bool> markShown() =>
      preferences.setString(storageKey, _now().toUtc().toIso8601String());
}

/// 결과 화면에서 홈으로 돌아갈 때 보여주는 전면광고를 관리한다.
///
/// 지금은 구글 공식 테스트 광고 단위 ID를 쓰고 있다. 실제 출시 전에는
/// [_androidAdUnitId] / [_iosAdUnitId]만 AdMob 콘솔에서 발급받은 실제
/// 광고 단위 ID로 교체하면 된다.
class AdService {
  AdService._();

  static const _androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _androidProductionInterstitialId =
      'ca-app-pub-8734329293403168/2938598836';
  static const _androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _androidProductionBannerId =
      'ca-app-pub-8734329293403168/1146165865';
  static const _iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const _iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// SDK 초기화 전에는 광고 객체를 만들지 않는다. 테스트에서는 초기화가
  /// 일어나지 않으므로 플랫폼 채널 요청도 발생하지 않는다.
  static final ValueNotifier<bool> initialized = ValueNotifier(false);

  static String get interstitialAdUnitId {
    if (!Platform.isAndroid) return _iosTestInterstitialId;
    return kReleaseMode
        ? _androidProductionInterstitialId
        : _androidTestInterstitialId;
  }

  static String get bannerAdUnitId {
    if (!Platform.isAndroid) return _iosTestBannerId;
    return kReleaseMode ? _androidProductionBannerId : _androidTestBannerId;
  }

  static void markInitialized() => initialized.value = true;

  static InterstitialAd? _ad;

  /// 다음에 보여줄 전면광고를 미리 로드해둔다. 웹은 플러그인이 지원하지
  /// 않으므로 아무 것도 하지 않는다.
  static void loadAd() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
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
  static Future<void> showThenProceed(VoidCallback proceed) async {
    final ad = _ad;
    if (kIsWeb || ad == null) {
      proceed();
      return;
    }

    late final InterstitialCooldown cooldown;
    try {
      cooldown = InterstitialCooldown(await SharedPreferences.getInstance());
    } catch (_) {
      proceed();
      return;
    }
    if (!cooldown.canShow) {
      proceed();
      return;
    }

    _ad = null;
    var proceeded = false;
    void proceedOnce() {
      if (proceeded) return;
      proceeded = true;
      proceed();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
        proceedOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadAd();
        proceedOnce();
      },
    );
    try {
      await ad.show();
      await cooldown.markShown();
    } catch (_) {
      ad.dispose();
      loadAd();
      proceedOnce();
    }
  }
}
