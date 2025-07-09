import 'dart:async';
import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_result.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdmobAppOpenAd {
  static final AdmobAppOpenAd _instance = AdmobAppOpenAd._internal();
  factory AdmobAppOpenAd() => _instance;
  AdmobAppOpenAd._internal();

  AppOpenAd? _appOpenAd;
  AdState _adState = AdState.initial;
  bool _isShowingAd = false;
  DateTime? _lastShowTime;
  DateTime? _loadTime;
  bool _isAppFirstOpen = true; // Track if this is the first app open
  bool _isAppFirstEverOpen = false; // Track if this is first ever open (cold start)
  bool _hasCheckedFirstOpen = false; // Flag to track if we've checked first open status

  // App Open Ads should be reloaded after 4 hours
  static const Duration maxCacheTime = Duration(hours: 4);

  // Minimum duration between showing app open ads
  final Duration minTimeBetweenAds = const Duration(minutes: 1);

  // Callback for ad state changes
  void Function(AdState state)? onAdStateChanged;

  // Check if this is the first ever launch of the app
  Future<bool> _checkIfFirstEverOpen() async {
    if (_hasCheckedFirstOpen) {
      return _isAppFirstEverOpen;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      bool isFirstLaunch = !(prefs.getBool('app_launched_before') ?? false);

      // If this is the first launch, set the flag for future
      if (isFirstLaunch) {
        await prefs.setBool('app_launched_before', true);
        _isAppFirstEverOpen = true;
      } else {
        _isAppFirstEverOpen = false;
      }

      _hasCheckedFirstOpen = true;
      return _isAppFirstEverOpen;
    } catch (e) {
      debugPrint('Error checking first launch status: $e');
      _hasCheckedFirstOpen = true;
      return false;
    }
  }

  // Load the app open ad
  Future<void> loadAd() async {
    // Skip loading if ads are disabled or already showing an ad
    if (!AdHelper.showAds || _isShowingAd) {
      return;
    }

    // Check if this is the first ever open of the app
    bool isFirstEverOpen = await _checkIfFirstEverOpen();

    // Skip if there's already an ad loaded and it's not expired
    if (_appOpenAd != null && !_isAdExpired) {
      return;
    }

    // Mark as loading
    _adState = AdState.loading;
    if (onAdStateChanged != null) {
      onAdStateChanged!(AdState.loading);
    }

    try {
      await AppOpenAd.load(
        adUnitId: AdHelper.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _loadTime = DateTime.now();
            _adState = AdState.loaded;
            if (onAdStateChanged != null) {
              onAdStateChanged!(AdState.loaded);
            }
            debugPrint('App Open Ad loaded successfully');

            // If this is the first app open (but not the first ever cold start) and ad is loaded, show it
            if (_isAppFirstOpen && !isFirstEverOpen) {
              // Use a slight delay to ensure the app UI is ready
              Future.delayed(Duration(milliseconds: 500), () {
                showAdIfAvailable();
                _isAppFirstOpen = false;
              });
            } else {
              _isAppFirstOpen = false;
            }
          },
          onAdFailedToLoad: (error) {
            _adState = AdState.error;
            if (onAdStateChanged != null) {
              onAdStateChanged!(AdState.error);
            }
            AdException.check(error, adUnitId: AdHelper.appOpenAdUnitId, adType: "App Open Ad");
            debugPrint('App Open Ad failed to load: ${error.message}');

            _isAppFirstOpen = false; // Reset first open flag on failure

            // Try again later
            Future.delayed(const Duration(minutes: 1), loadAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading App Open Ad: $e');
      _adState = AdState.error;
      if (onAdStateChanged != null) {
        onAdStateChanged!(AdState.error);
      }
      _isAppFirstOpen = false;
    }
  }

  // Show the app open ad
  Future<AdResult> showAdIfAvailable() async {
    // Check if this is the first ever open of the app
    bool isFirstEverOpen = await _checkIfFirstEverOpen();

    // Skip showing if this is the first ever cold start
    if (isFirstEverOpen) {
      debugPrint('Skipping App Open Ad on first ever cold start');
      _isAppFirstOpen = false;
      return AdResult(wasShown: false, message: 'First app install cold start - skipping ad', failReason: AdFailReason.adsDisabled);
    }

    // Skip showing if ads are disabled
    if (!AdHelper.showAds) {
      _isAppFirstOpen = false;
      return AdResult(wasShown: false, message: 'Ads are disabled globally', failReason: AdFailReason.adsDisabled);
    }

    // Check if we're already showing an ad
    if (_isShowingAd) {
      return AdResult(wasShown: false, message: 'An ad is already being shown', failReason: AdFailReason.showError);
    }

    // For first app open, skip the cooldown check
    if (!_isAppFirstOpen) {
      // Check if enough time has passed since last ad
      if (_lastShowTime != null) {
        final timeSinceLastAd = DateTime.now().difference(_lastShowTime!);
        if (timeSinceLastAd < minTimeBetweenAds) {
          final secondsLeft = (minTimeBetweenAds - timeSinceLastAd).inSeconds;
          return AdResult(wasShown: false, message: 'Not enough time passed since last ad. Try again in $secondsLeft seconds', failReason: AdFailReason.cooldownPeriod);
        }
      }
    }

    // Check if ad is loaded and not expired
    if (_appOpenAd == null || _isAdExpired || !AdHelper.showAppOpenAds) {
      _isAppFirstOpen = false; // Reset first open flag
      await loadAd(); // Try to load a new ad
      return AdResult(wasShown: false, message: 'App Open Ad not ready yet', failReason: AdFailReason.notLoaded);
    }

    // Ensure we have a valid ad and show it
    if (_appOpenAd != null) {
      try {
        _isShowingAd = true;

        _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            debugPrint('App Open Ad showed full screen content');
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('App Open Ad failed to show: ${error.message}');
            _isShowingAd = false;
            ad.dispose();
            _appOpenAd = null;
            _isAppFirstOpen = false;
          },
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('App Open Ad was dismissed');
            _isShowingAd = false;
            _lastShowTime = DateTime.now();
            ad.dispose();
            _appOpenAd = null;
            _isAppFirstOpen = false;

            // Load the next ad
            loadAd();
          },
          onAdImpression: (ad) {
            debugPrint('App Open Ad impression recorded');
          },
        );

        await _appOpenAd!.show();
        return AdResult(wasShown: true, message: 'App Open Ad shown successfully');
      } catch (e) {
        debugPrint('Error showing App Open Ad: $e');
        _isShowingAd = false;
        _appOpenAd?.dispose();
        _appOpenAd = null;
        _isAppFirstOpen = false;

        // Try to load a new ad for next time
        loadAd();

        return AdResult(wasShown: false, message: 'Error showing App Open Ad: $e', failReason: AdFailReason.showError);
      }
    }

    _isAppFirstOpen = false;
    return AdResult(wasShown: false, message: 'App Open Ad not available', failReason: AdFailReason.notLoaded);
  }

  // Check if the ad has expired
  bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!) > maxCacheTime;
  }

  // Current ad state
  AdState get adState => _adState;

  // Check if ad is ready to be shown
  bool get isAdReady => _appOpenAd != null && !_isAdExpired && !_isShowingAd;

  // Dispose the ad when done
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
