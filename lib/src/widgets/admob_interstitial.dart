import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_result.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdmobInterstitialAd {
  static final Logger _logger = Logger('AdmobInterstitialAd');
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
      _logger.fine('Interstitial ad already loading or loaded. Skipping new load request.');
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
          _logger.info('Interstitial ad loaded.');
          _interstitialAd = ad;
          _adState = AdState.loaded;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.loaded);
          }

          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              _logger.info('Interstitial ad dismissed.');
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
              _logger.warning('Failed to show interstitial ad: ${error.message}');
              ad.dispose();
              _adState = AdState.error;
              if (onAdStateChanged != null) {
                onAdStateChanged!(AdState.error);
              }
              _interstitialAd = null;

              // Try loading again after error
              Future.delayed(const Duration(seconds: 30), loadAd);
            },
            onAdShowedFullScreenContent: (_) {
              _logger.info('Interstitial ad shown.');
            },
            onAdImpression: (_) {
              _logger.fine('Interstitial ad impression recorded.');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _logger.warning('Interstitial ad failed to load: ${error.message}');
          _adState = AdState.error;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.error);
          }
          AdException.check(error, adUnitId: AdHelper.interstitialAdUnitId, adType: "Interstitial Ad");

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
        _logger.fine('Interstitial ad cooldown active. Wait $secondsLeft seconds.');
        return AdResult(wasShown: false, message: 'Not enough time passed since last ad. Try again in $secondsLeft seconds', failReason: AdFailReason.cooldownPeriod);
      }
    }

    if (_interstitialAd == null || _adState != AdState.loaded) {
      _logger.fine('Interstitial ad not ready. Current state: $_adState');
      return AdResult(wasShown: false, message: 'Ad not ready yet. Current state: $_adState', failReason: AdFailReason.notLoaded);
    }

    try {
      await _interstitialAd?.show();
      return AdResult(wasShown: true, message: 'Ad shown successfully');
    } catch (e) {
      _logger.severe('Error showing interstitial ad: $e');
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
