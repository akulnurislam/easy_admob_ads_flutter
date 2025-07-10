import 'dart:io';
import 'package:easy_admob_ads_flutter/easy_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';

final adTypeMap = AdIdRegistry.currentPlatformAdIds;

class AdHelper {
  // Global flag to enable/disable ads throughout the app
  static bool showAds = true;

  // Flag specifically for App Open Ads
  static bool showAppOpenAds = true;

  // Flag specifically for Consent GDPR
  static bool showConstentGDPR = false;

  // Flag to control test vs production ads - default based on build mode
  static bool isTestMode = kDebugMode;

  // Get Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSInterstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get Rewarded Ad Unit ID
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSRewardedAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get Rewarded Ad Unit ID
  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSRewardedInterstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get App Open Ad Unit ID
  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return _androidAppOpenAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSAppOpenAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get Native Ad Unit ID
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return _androidNativeAdUnitId;
    } else if (Platform.isIOS) {
      return _iOSNativeAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Set up production ad unit IDs
  static void setProductionAdUnits() {
    if (Platform.isAndroid) {
      _androidBannerAdUnitId = adTypeMap[AdType.banner] ?? 'unknown';
      _androidInterstitialAdUnitId =
          adTypeMap[AdType.interstitial] ?? 'unknown';
      _androidRewardedAdUnitId = adTypeMap[AdType.rewarded] ?? 'unknown';
      _androidRewardedInterstitialAdUnitId =
          adTypeMap[AdType.rewardedInterstitial] ?? 'unknown';
      _androidAppOpenAdUnitId = adTypeMap[AdType.appOpen] ?? 'unknown';
      _androidNativeAdUnitId = adTypeMap[AdType.native] ?? 'unknown';
    } else if (Platform.isIOS) {
      _iOSBannerAdUnitId = adTypeMap[AdType.banner] ?? 'unknown';
      _iOSInterstitialAdUnitId = adTypeMap[AdType.interstitial] ?? 'unknown';
      _iOSRewardedAdUnitId = adTypeMap[AdType.rewarded] ?? 'unknown';
      _iOSRewardedInterstitialAdUnitId =
          adTypeMap[AdType.rewardedInterstitial] ?? 'unknown';
      _iOSAppOpenAdUnitId = adTypeMap[AdType.appOpen] ?? 'unknown';
      _iOSNativeAdUnitId = adTypeMap[AdType.native] ?? 'unknown';
    }
  }

  // Private fields (default to test IDs)
  static String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static String _androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static String _androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static String _androidRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';
  static String _androidAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/3419835294';
  static String _androidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  static String _iOSBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static String _iOSInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static String _iOSRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  static String _iOSRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866';
  static String _iOSAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5575463023';
  static String _iOSNativeAdUnitId = 'ca-app-pub-3940256099942544/3986624511';
}
