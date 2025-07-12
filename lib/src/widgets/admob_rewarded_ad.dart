import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_result.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdmobRewardedAd {
  static final Logger _logger = Logger('AdmobRewardedAd');
  RewardedAd? _rewardedAd;
  AdState _adState = AdState.initial;
  DateTime? _lastShowTime;

  final void Function(AdState state)? onAdStateChanged;
  final void Function(RewardItem reward)? onRewardEarned;
  final Duration minTimeBetweenAds;
  final bool setImmersiveEnabled;

  AdmobRewardedAd({
    this.onAdStateChanged,
    this.onRewardEarned,
    // Default minimum time between showing rewarded ads
    this.minTimeBetweenAds = const Duration(minutes: 1),
    this.setImmersiveEnabled = true,
  });

  Future<void> loadAd() async {
    // Skip loading if ads are disabled
    if (!AdHelper.showAds) {
      _logger.fine('Ads are disabled. Rewarded ad will not load.');
      _adState = AdState.disabled;
      if (onAdStateChanged != null) {
        onAdStateChanged!(AdState.disabled);
      }
      return;
    }

    if (_adState == AdState.loading || _adState == AdState.loaded) {
      _logger.fine('Ad is already in state $_adState. Skipping new load.');
      return;
    }

    _adState = AdState.loading;
    if (onAdStateChanged != null) {
      onAdStateChanged!(AdState.loading);
    }

    await RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.setImmersiveMode(setImmersiveEnabled);
          _logger.info('Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _adState = AdState.loaded;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.loaded);
          }

          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              _logger.info('Rewarded ad dismissed.');
              _lastShowTime = DateTime.now();
              ad.dispose();
              _adState = AdState.closed;
              if (onAdStateChanged != null) {
                onAdStateChanged!(AdState.closed);
              }
              _rewardedAd = null;

              // Auto reload after showing
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              _logger.warning('Failed to show rewarded ad: ${error.message}');
              ad.dispose();
              _adState = AdState.error;
              if (onAdStateChanged != null) {
                onAdStateChanged!(AdState.error);
              }
              _rewardedAd = null;

              // Try loading again after error
              Future.delayed(const Duration(seconds: 30), loadAd);
            },
            onAdShowedFullScreenContent: (_) {
              _logger.info('Rewarded ad is being shown.');
            },
            onAdImpression: (_) {
              _logger.fine('Rewarded ad impression recorded.');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _logger.warning('Rewarded ad failed to load: ${error.message}');
          _adState = AdState.error;
          if (onAdStateChanged != null) {
            onAdStateChanged!(AdState.error);
          }
          AdException.check(error, adUnitId: AdHelper.rewardedAdUnitId, adType: "Rewarded Ad");

          // Retry loading after delay
          Future.delayed(const Duration(seconds: 30), loadAd);
        },
      ),
    );
  }

  Future<AdResult> showAd() async {
    // Skip showing if ads are disabled
    if (!AdHelper.showAds) {
      _logger.fine('Ads disabled. Skipping show.');
      return AdResult(wasShown: false, message: 'Ads are disabled globally', failReason: AdFailReason.adsDisabled);
    }

    // Check if enough time has passed since last ad
    if (_lastShowTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastShowTime!);
      if (timeSinceLastAd < minTimeBetweenAds) {
        final secondsLeft = (minTimeBetweenAds - timeSinceLastAd).inSeconds;
        _logger.fine('Cooldown active. Wait $secondsLeft seconds before showing next ad.');
        return AdResult(wasShown: false, message: 'Not enough time passed since last ad. Try again in $secondsLeft seconds', failReason: AdFailReason.cooldownPeriod);
      }
    }

    if (_rewardedAd == null || _adState != AdState.loaded) {
      _logger.fine('Ad not ready. State: $_adState');
      return AdResult(wasShown: false, message: 'Ad not ready yet. Current state: $_adState', failReason: AdFailReason.notLoaded);
    }

    try {
      _logger.info('Showing rewarded ad...');
      await _rewardedAd?.show(
        onUserEarnedReward: (_, reward) {
          _logger.info('User earned reward: ${reward.amount} ${reward.type}');
          if (onRewardEarned != null) {
            onRewardEarned!(reward);
          }
        },
      );
      return AdResult(wasShown: true, message: 'Ad shown successfully');
    } catch (e) {
      _logger.severe('Error showing rewarded ad: $e');
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _adState = AdState.error;
      loadAd(); // Try to load for next time
      return AdResult(wasShown: false, message: 'Error showing ad: $e', failReason: AdFailReason.showError);
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  AdState get adState => _adState;

  bool get isAdReady => _adState == AdState.loaded && _rewardedAd != null;
}
