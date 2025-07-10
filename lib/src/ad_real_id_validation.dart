import 'dart:async';
import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_id_registry.dart';
import 'package:easy_admob_ads_flutter/src/ad_type.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdRealIdValidation {
  static final Logger _logger = Logger('AdRealIdValidation');
  static Future<void> validateAdUnits() async {
    final adTypeMap = AdIdRegistry.currentPlatformAdIds;

    final List<String> results = [];

    Future<void> runValidation({required AdType adType, required Future<dynamic> Function(String adUnitId) loader}) async {
      final adUnitId = (adTypeMap[adType] ?? '').trim();

      if (adUnitId.isEmpty) {
        results.add('⏭️ Skipped ${adType.name} ad: Ad Unit ID is empty.');
        return;
      }

      try {
        await loader(adUnitId);
        results.add('✅ ${adType.name} ad loaded successfully.');
      } catch (e) {
        results.add('❌ ${adType.name} ad failed to load: $e');
      }
    }

    await runValidation(
      adType: AdType.banner,
      loader: (id) => loadBannerAd(adUnitId: id),
    );
    await runValidation(
      adType: AdType.interstitial,
      loader: (id) => loadInterstitialAd(adUnitId: id),
    );
    await runValidation(
      adType: AdType.rewarded,
      loader: (id) => loadRewardedAd(adUnitId: id),
    );
    await runValidation(
      adType: AdType.rewardedInterstitial,
      loader: (id) => loadRewardedInterstitialAd(adUnitId: id),
    );
    await runValidation(
      adType: AdType.appOpen,
      loader: (id) => loadAppOpenAd(adUnitId: id),
    );
    await runValidation(
      adType: AdType.native,
      loader: (id) => loadNativeAd(adUnitId: id),
    );

    for (final msg in results) {
      _logger.info(msg);
    }
  }

  /// ✅ Load BannerAd
  static Future<BannerAd> loadBannerAd({required String adUnitId}) async {
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdException.check(error, adUnitId: adUnitId, adType: "Banner");
        },
      ),
    );

    await ad.load();
    return ad;
  }

  /// ✅ Load InterstitialAd
  static Future<InterstitialAd> loadInterstitialAd({required String adUnitId}) {
    final completer = Completer<InterstitialAd>();

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) {
          AdException.check(error, adUnitId: adUnitId, adType: "Interstitial");
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  /// ✅ Load RewardedAd
  static Future<RewardedAd> loadRewardedAd({required String adUnitId}) {
    final completer = Completer<RewardedAd>();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) {
          AdException.check(error, adUnitId: adUnitId, adType: "Rewarded");
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  /// ✅ Load Rewarded Interstitial Ad
  static Future<RewardedInterstitialAd> loadRewardedInterstitialAd({required String adUnitId}) {
    final completer = Completer<RewardedInterstitialAd>();

    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) {
          AdException.check(error, adUnitId: adUnitId, adType: "RewardedInterstitial");
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  /// ✅ Load App Open Ad
  static Future<AppOpenAd> loadAppOpenAd({required String adUnitId}) {
    final completer = Completer<AppOpenAd>();

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) {
          AdException.check(error, adUnitId: adUnitId, adType: "AppOpen");
          completer.completeError(error);
        },
      ),
    );

    return completer.future;
  }

  /// ✅ Get a Native Ad Widget (Medium)
  static Future<NativeAd> loadNativeAd({required String adUnitId}) {
    final completer = Completer<NativeAd>();

    final ad = NativeAd(
      adUnitId: adUnitId,
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.small),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => completer.complete(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdException.check(error, adUnitId: adUnitId, adType: "Native");
          completer.completeError(error);
        },
      ),
    );

    ad.load();
    return completer.future;
  }
}
