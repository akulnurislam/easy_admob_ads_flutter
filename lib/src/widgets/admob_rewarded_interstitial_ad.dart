import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_result.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobRewardedInterstitialAd {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AdState _adState = AdState.initial;
  DateTime? _lastShowTime;
  int _retryAttempt = 0;
  final int _maxRetryAttempts = 3;

  final void Function(AdState state)? onAdStateChanged;
  final void Function(RewardItem reward)? onRewardEarned;
  final Duration minTimeBetweenAds;

  AdmobRewardedInterstitialAd({
    this.onAdStateChanged,
    this.onRewardEarned,
    // Default minimum time between showing rewarded interstitial ads
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

    try {
      await RewardedInterstitialAd.load(
        adUnitId: AdHelper.rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            _rewardedInterstitialAd = ad;
            _adState = AdState.loaded;
            _retryAttempt = 0; // Reset retry counter on successful load

            if (onAdStateChanged != null) {
              onAdStateChanged!(AdState.loaded);
            }

            debugPrint('Rewarded Interstitial ad loaded successfully');

            _rewardedInterstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
                debugPrint('Rewarded Interstitial ad dismissed');
                _lastShowTime = DateTime.now();
                ad.dispose();
                _adState = AdState.closed;
                if (onAdStateChanged != null) {
                  onAdStateChanged!(AdState.closed);
                }
                _rewardedInterstitialAd = null;

                // Auto reload after showing
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
                debugPrint('Rewarded Interstitial ad failed to show: ${error.message}');
                ad.dispose();
                _adState = AdState.error;
                if (onAdStateChanged != null) {
                  onAdStateChanged!(AdState.error);
                }
                _rewardedInterstitialAd = null;

                // Try loading again after error
                Future.delayed(const Duration(seconds: 30), loadAd);
              },
              onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
                debugPrint('Rewarded Interstitial ad showed successfully');
              },
              onAdImpression: (RewardedInterstitialAd ad) {
                debugPrint('Rewarded Interstitial ad impression recorded');
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            AdException.check(error, adUnitId: AdHelper.rewardedInterstitialAdUnitId, adType: "Rewarded Interstitial Ad");
            debugPrint('Rewarded Interstitial ad failed to load: ${error.message}');
            _adState = AdState.error;
            if (onAdStateChanged != null) {
              onAdStateChanged!(AdState.error);
            }

            // Implement exponential backoff for retries
            if (_retryAttempt < _maxRetryAttempts) {
              _retryAttempt++;
              final int retryDelay = _retryAttempt * 30; // Increasing delay with each retry
              debugPrint('Retrying to load Rewarded Interstitial ad in $retryDelay seconds (attempt $_retryAttempt of $_maxRetryAttempts)');
              Future.delayed(Duration(seconds: retryDelay), loadAd);
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading Rewarded Interstitial ad: $e');
      _adState = AdState.error;
      if (onAdStateChanged != null) {
        onAdStateChanged!(AdState.error);
      }

      // Retry loading after a fixed delay on unexpected errors
      Future.delayed(const Duration(seconds: 60), loadAd);
    }
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

    if (_rewardedInterstitialAd == null || _adState != AdState.loaded) {
      return AdResult(wasShown: false, message: 'Rewarded Interstitial ad not ready yet. Current state: $_adState', failReason: AdFailReason.notLoaded);
    }

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          if (onRewardEarned != null) {
            onRewardEarned!(reward);
          }
        },
      );
      return AdResult(wasShown: true, message: 'Rewarded Interstitial ad shown successfully');
    } catch (e) {
      debugPrint('Error showing Rewarded Interstitial ad: $e');
      _rewardedInterstitialAd?.dispose();
      _rewardedInterstitialAd = null;
      _adState = AdState.error;
      loadAd(); // Try to load for next time
      return AdResult(wasShown: false, message: 'Error showing Rewarded Interstitial ad: $e', failReason: AdFailReason.showError);
    }
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }

  AdState get adState => _adState;

  bool get isAdReady => _adState == AdState.loaded && _rewardedInterstitialAd != null;
}
