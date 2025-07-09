import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/app_lifecycle_reactor.dart';
import 'package:easy_admob_ads_flutter/src/widgets/admob_app_open_ad.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();

  factory AdmobService() => _instance;

  AdmobService._internal();

  bool _isInitialized = false;
  late AppLifecycleReactor _appLifecycleReactor;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();

    // Configure test devices for development
    if (kDebugMode) {
      final testDeviceIds = ['kGADSimulatorID'];

      // Add more test device IDs if needed
      // For Android, use adb logcat to find test device ID
      // For iOS, use the Xcode console

      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: testDeviceIds));
    } else {
      // If in production mode, set production ad unit IDs
      if (!AdHelper.isTestMode) {
        AdHelper.setProductionAdUnits();
      }
    }

    // Initialize app open ad
    final appOpenAdManager = AdmobAppOpenAd();
    _appLifecycleReactor = AppLifecycleReactor(appOpenAdManager: appOpenAdManager);

    // Load the initial app open ad
    await appOpenAdManager.loadAd();

    // Start listening for app foreground/background events
    _appLifecycleReactor.listenToAppStateChanges();

    _isInitialized = true;
  }

  // Helper method to check if ads should be shown based on global settings
  bool shouldShowAds() {
    return AdHelper.showAds;
  }
}
