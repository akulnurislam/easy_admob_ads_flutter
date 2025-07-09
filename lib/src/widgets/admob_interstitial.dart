import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_result.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobInterstitialAd {
  InterstitialAd? _interstitialAd;
  AdState _adState = AdState.initial;
  DateTime? _lastShowTime;

  final void Function(AdState state)? onAdStateChanged;
  final Duration minTimeBetweenAds;

  AdmobInterstitialAd({
    this.onAdStateChanged,
    // Default minimum time between showing interstitial ads is 1 minute
    this.minTimeBetweenAds = const Duration(minutes: 1),
  });

  Future<void> loadAd() async {
    // Skip loading if ads are disabled
    if (!AdHelper.showAds) {
      _adState = AdState.closed;
      if (onAdStateChanged != null) {
        onAdStateChanged!(AdState.closed);
      }
      return;
    }

    if (_adState == AdState.loading || _adState == AdState.loaded) {
      return;
    }

    _adState = AdState.loading;
    if (onAdStateChanged != null) {
      onAdStateChanged!(AdState.loading);
    }

    await InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _adState = AdState.loaded;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.loaded);
          }

          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              _lastShowTime = DateTime.now();
              ad.dispose();
              _adState = AdState.closed;
              if (onAdStateChanged != null) {
                onAdStateChanged!(AdState.closed);
              }
              _interstitialAd = null;

              // Auto reload after showing
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _adState = AdState.error;
              if (onAdStateChanged != null) {
                onAdStateChanged!(AdState.error);
              }
              _interstitialAd = null;
              debugPrint('Interstitial ad failed to show: ${error.message}');

              // Try loading again after error
              Future.delayed(const Duration(seconds: 30), loadAd);
            },
            onAdShowedFullScreenContent: (_) {
              debugPrint('Interstitial ad showed successfully');
            },
            onAdImpression: (_) {
              debugPrint('Interstitial ad impression recorded');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _adState = AdState.error;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.error);
          }
          AdException.check(error, adUnitId: AdHelper.interstitialAdUnitId, adType: "Interstitial Ad");
          debugPrint('Interstitial ad failed to load: ${error.message}');

          // Retry loading after delay
          Future.delayed(const Duration(seconds: 30), loadAd);
        },
      ),
    );
  }

  Future<AdResult> showAd() async {
    // Skip showing if ads are disabled
    if (!AdHelper.showAds) {
      return AdResult(wasShown: false, message: 'Ads are disabled globally', failReason: AdFailReason.adsDisabled);
    }

    // Check if enough time has passed since last ad
    if (_lastShowTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastShowTime!);
      if (timeSinceLastAd < minTimeBetweenAds) {
        final secondsLeft = (minTimeBetweenAds - timeSinceLastAd).inSeconds;
        return AdResult(wasShown: false, message: 'Not enough time passed since last ad. Try again in $secondsLeft seconds', failReason: AdFailReason.cooldownPeriod);
      }
    }

    if (_interstitialAd == null || _adState != AdState.loaded) {
      return AdResult(wasShown: false, message: 'Ad not ready yet. Current state: $_adState', failReason: AdFailReason.notLoaded);
    }

    try {
      await _interstitialAd?.show();
      return AdResult(wasShown: true, message: 'Ad shown successfully');
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _adState = AdState.error;
      loadAd(); // Try to load for next time
      return AdResult(wasShown: false, message: 'Error showing ad: $e', failReason: AdFailReason.showError);
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  AdState get adState => _adState;

  bool get isAdReady => _adState == AdState.loaded && _interstitialAd != null;
}
