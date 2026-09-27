import 'dart:async';
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

  Duration get remaining {
    final stored = preferences.getString(storageKey);
    final lastShown = stored == null ? null : DateTime.tryParse(stored);
    if (lastShown == null) return Duration.zero;
    final remaining = lastShown.toUtc().add(duration).difference(_now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
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
      'ca-app-pub-8734329293403168/2938593836';
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
  static bool _isLoading = false;
  static Timer? _retryTimer;
  static int _consecutiveLoadFailures = 0;
  static const _retryDelays = <Duration>[
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 40),
    Duration(seconds: 60),
  ];

  /// 다음에 보여줄 전면광고를 미리 로드해둔다. 웹은 플러그인이 지원하지
  /// 않으므로 아무 것도 하지 않는다.
  static void loadAd() {
    if (kIsWeb || !initialized.value || _ad != null || _isLoading) return;

    _retryTimer?.cancel();
    _retryTimer = null;
    _isLoading = true;
    debugPrint('[Interstitial] load requested');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _consecutiveLoadFailures = 0;
          _ad = ad;
          debugPrint('[Interstitial] loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          debugPrint('[Interstitial] failed to load: $error');
          _scheduleRetry();
        },
      ),
    );
  }

  static void _scheduleRetry() {
    if (kIsWeb || !initialized.value || _retryTimer != null) return;
    if (_consecutiveLoadFailures >= _retryDelays.length) {
      debugPrint(
          '[Interstitial] retry paused until the next result exit');
      return;
    }
    final delay = _retryDelays[_consecutiveLoadFailures];
    _consecutiveLoadFailures++;
    debugPrint('[Interstitial] retry scheduled: ${delay.inSeconds} sec');
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      loadAd();
    });
  }

  static void _ensurePreloaded() {
    if (_ad == null && !_isLoading && _retryTimer == null) {
      _consecutiveLoadFailures = 0;
      loadAd();
    }
  }

  /// 로드된 광고가 있으면 보여준 뒤 [proceed]를 실행하고, 없으면 사용자를
  /// 기다리게 하지 않고 바로 [proceed]를 실행한다. 화면 전환이 광고 로드
  /// 성공 여부에 발목 잡히지 않도록 하기 위함이다.
  static Future<void> showThenProceed(VoidCallback proceed) async {
    debugPrint(
        '[Interstitial] result exit requested; ad ready: ${_ad != null}, loading: $_isLoading');
    final ad = _ad;
    if (kIsWeb || ad == null) {
      _ensurePreloaded();
      proceed();
      return;
    }

    late final InterstitialCooldown cooldown;
    try {
      cooldown = InterstitialCooldown(await SharedPreferences.getInstance());
    } catch (_) {
      debugPrint('[Interstitial] cooldown unavailable');
      proceed();
      return;
    }
    if (!cooldown.canShow) {
      debugPrint(
          '[Interstitial] cooldown remaining: ${cooldown.remaining.inSeconds} sec');
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
      onAdShowedFullScreenContent: (_) {
        debugPrint('[Interstitial] showed');
        unawaited(cooldown.markShown());
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[Interstitial] dismissed');
        ad.dispose();
        loadAd();
        proceedOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Interstitial] failed to show: $error');
        ad.dispose();
        loadAd();
        proceedOnce();
      },
    );
    try {
      debugPrint('[Interstitial] show requested');
      await ad.show();
    } catch (error) {
      debugPrint('[Interstitial] show threw: $error');
      ad.dispose();
      loadAd();
      proceedOnce();
    }
  }
}
