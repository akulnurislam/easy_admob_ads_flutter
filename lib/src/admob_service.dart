import 'dart:async';

import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/app_lifecycle_reactor.dart';
import 'package:easy_admob_ads_flutter/src/widgets/admob_app_open_ad.dart';
import 'package:easy_admob_ads_flutter/src/widgets/admob_consent_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();

  factory AdmobService() => _instance;

  AdmobService._internal();

  bool _isInitialized = false;
  late AppLifecycleReactor _appLifecycleReactor;
  final ConsentManager _consentManager = ConsentManager();

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[ConsentManager] AdHelper.showConstentGDPR = ${AdHelper.showConstentGDPR}');
    // Step 1: Gather consent before initializing ads.
    final Completer<void> consentCompleter = Completer();
    _consentManager.gatherConsent((FormError? error) {
      if (error != null) {
        debugPrint('[ConsentManager] Error gathering consent: ${error.errorCode} - ${error.message}');
      } else {
        debugPrint('[ConsentManager] Consent successfully gathered.');
      }
      consentCompleter.complete();
    });
    await consentCompleter.future;

    // Step 2: Only initialize MobileAds if we are allowed to request ads.
    if (await _consentManager.canRequestAds()) {
      await MobileAds.instance.initialize();

      if (kDebugMode) {
        final testDeviceIds = ['kGADSimulatorID'];
        MobileAds.instance.updateRequestConfiguration(RequestConfiguration(testDeviceIds: testDeviceIds));
      } else {
        if (!AdHelper.isTestMode) {
          AdHelper.setProductionAdUnits();
        }
      }

      // Step 3: App open ad setup
      final appOpenAdManager = AdmobAppOpenAd();
      _appLifecycleReactor = AppLifecycleReactor(appOpenAdManager: appOpenAdManager);
      await appOpenAdManager.loadAd();
      _appLifecycleReactor.listenToAppStateChanges();

      _isInitialized = true;
    } else {
      debugPrint('Ads cannot be requested due to lack of consent.');
    }
  }

  bool shouldShowAds() => AdHelper.showAds;
}
