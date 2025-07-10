import 'dart:io';
import 'package:easy_admob_ads_flutter/easy_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final adTypeMap = AdIdRegistry.currentPlatformAdIds;

class AdHelper {
  // Global flag to enable/disable ads throughout the app
  static bool showAds = true;

  // Flag specifically for App Open Ads
  static bool showAppOpenAds = true;

  // Flag specifically for Consent GDPR
  static bool showConstentGDPR = false;

  // Flag for Consent
  static bool isPrivacyOptionsRequired = false;

  // Test ids
  static List<String> testDeviceIds = <String>[];

  /// Call this from your app's main() if you want to see logs from this package.
  static void setupAdLogging({Level level = Level.ALL}) {
    if (kDebugMode) {
      Logger.root.level = level;
      Logger.root.onRecord.listen((record) {
        debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
      });
    }
  }

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

  // Private fields (default to test IDs)
  static final String _androidBannerAdUnitId = adTypeMap[AdType.banner] ?? '';
  static final String _androidInterstitialAdUnitId = adTypeMap[AdType.interstitial] ?? '';
  static final String _androidRewardedAdUnitId = adTypeMap[AdType.rewarded] ?? '';
  static final String _androidRewardedInterstitialAdUnitId = adTypeMap[AdType.rewardedInterstitial] ?? '';
  static final String _androidAppOpenAdUnitId = adTypeMap[AdType.appOpen] ?? '';
  static final String _androidNativeAdUnitId = adTypeMap[AdType.native] ?? '';

  static final String _iOSBannerAdUnitId = adTypeMap[AdType.banner] ?? '';
  static final String _iOSInterstitialAdUnitId = adTypeMap[AdType.interstitial] ?? '';
  static final String _iOSRewardedAdUnitId = adTypeMap[AdType.rewarded] ?? '';
  static final String _iOSRewardedInterstitialAdUnitId = adTypeMap[AdType.rewardedInterstitial] ?? '';
  static final String _iOSAppOpenAdUnitId = adTypeMap[AdType.appOpen] ?? '';
  static final String _iOSNativeAdUnitId = adTypeMap[AdType.native] ?? '';
}
