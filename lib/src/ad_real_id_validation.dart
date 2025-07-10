import 'dart:async';
import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_id_registry.dart';
import 'package:easy_admob_ads_flutter/src/ad_type.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdRealIdValidation {
  static Future<void> validateAdUnits() async {
    final adTypeMap = AdIdRegistry.currentPlatformAdIds;

    debugPrint('🔎 Testing Real Test ID\'s');

    Future<void> runValidation({required AdType adType, required Future<void> Function(String adUnitId) loader}) async {
      final adUnitId = (adTypeMap[adType] ?? '').trim();

      if (adUnitId.isEmpty) {
        debugPrint('⏭️ Skipped ${adType.name} ad: Ad Unit ID is empty.');
        return;
      }

      try {
        await loader(adUnitId);
        debugPrint('✅ ${adType.name} ad loaded successfully.');
      } catch (e) {
        debugPrint('❌ ${adType.name} ad failed to load: $e');
      }
    }

    await runValidation(
      adType: AdType.banner,
      loader: (adUnitId) => loadBannerAd(adUnitId: adUnitId),
    );

    await runValidation(
      adType: AdType.interstitial,
      loader: (adUnitId) => loadInterstitialAd(adUnitId: adUnitId),
    );

    await runValidation(
      adType: AdType.rewarded,
      loader: (adUnitId) => loadRewardedAd(adUnitId: adUnitId),
    );

    await runValidation(
      adType: AdType.rewardedInterstitial,
      loader: (adUnitId) => loadRewardedInterstitialAd(adUnitId: adUnitId),
    );

    await runValidation(
      adType: AdType.appOpen,
      loader: (adUnitId) => loadAppOpenAd(adUnitId: adUnitId),
    );

    await runValidation(
      adType: AdType.native,
      loader: (adUnitId) => loadNativeAd(adUnitId: adUnitId),
    );

    debugPrint('🧪 Real Ad unit validation process completed.');
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
