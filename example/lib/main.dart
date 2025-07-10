import 'package:easy_admob_ads_flutter/easy_admob_ads_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  // 🔧 Ensure platform bindings are initialized before any async calls
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Set your actual AdMob App IDs in AndroidManifest.xml and Info.plist:
  // Android: https://developers.google.com/admob/flutter/quick-start#android
  // iOS:    https://developers.google.com/admob/flutter/quick-start#ios

  // 📌 Initialize Ad Unit IDs for both platforms
  // Use empty strings to skip loading specific ad types
  AdIdRegistry.initialize(
    ios: {
      AdType.banner: "ca-app-pub-ios-banner",
      AdType.interstitial: "ca-app-pub-ios-interstitial",
      AdType.rewarded: "ca-app-pub-ios-rewarded",
      AdType.rewardedInterstitial: "ca-app-pub-ios-rewarded-int",
      AdType.appOpen: "ca-app-pub-ios-appopen",
      AdType.native: "", // Skip Native ads on iOS
    },
    android: {
      AdType.banner: "ca-app-pub-android-banner",
      AdType.interstitial: "ca-app-pub-android-interstitial",
      AdType.rewarded: "ca-app-pub-android-rewarded",
      AdType.rewardedInterstitial: "ca-app-pub-android-rewarded-int",
      AdType.appOpen: "ca-app-pub-android-appopen",
      AdType.native: "", // Skip Native ads on Android
    },
  );

  // 🧠 Global Ad Configuration
  AdHelper.showAds = true; // Set to false to disable all ads globally
  AdHelper.showAppOpenAds = true; // Set to false to disable App Open Ad on startup
  AdHelper.showConstentGDPR = true; // Simulate GDPR consent (debug only, false in release)

  // 🚀 Initialize Google Mobile Ads SDK
  await AdmobService().initialize();

  // 🧪 Optional: Use during development to test if all ad units load successfully
  // await AdRealIdValidation.validateAdUnits();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const AdsDemo());
  }
}

class AdsDemo extends StatefulWidget {
  const AdsDemo({super.key});
  @override
  State<AdsDemo> createState() => _AdsDemoState();
}

class _AdsDemoState extends State<AdsDemo> {
  late AdmobInterstitialAd _interstitialAd;
  late AdmobRewardedAd _rewardedAd;
  late AdmobRewardedInterstitialAd _rewardedInterstitialAd;

  @override
  void initState() {
    super.initState();
    _loadAllAds();

    // Check if a privacy options entry point is required.
    _getIsPrivacyOptionsRequired();
  }

  final _consentManager = ConsentManager();
  var _isPrivacyOptionsRequired = false;
  void _getIsPrivacyOptionsRequired() async {
    if (await _consentManager.isPrivacyOptionsRequired()) {
      setState(() {
        _isPrivacyOptionsRequired = true;
      });
    }
  }

  Future<void> _loadAllAds() async {
    // Interstitial
    _interstitialAd = AdmobInterstitialAd(
      minTimeBetweenAds: Duration(seconds: 20),
      onAdStateChanged: (state) {
        debugPrint('Interstitial ad state: $state');
      },
    );
    _interstitialAd.loadAd();

    // Rewarded
    _rewardedAd = AdmobRewardedAd(
      onAdStateChanged: (state) {
        debugPrint('Rewarded ad state: $state');
      },
      onRewardEarned: (reward) {
        // _unlockLevel();
        debugPrint('You earned ${reward.amount} coins!');
      },
    );
    _rewardedAd.loadAd();

    // Rewarded Interstitial
    _rewardedInterstitialAd = AdmobRewardedInterstitialAd(
      onAdStateChanged: (state) {
        setState(() {
          switch (state) {
            case AdState.initial:
              break;
            case AdState.loading:
              break;
            case AdState.loaded:
              break;
            case AdState.error:
              break;
            case AdState.closed:
              break;
          }
        });
      },
      onRewardEarned: (reward) {
        // Show a confirmation to the user
        debugPrint('You earned ${reward.amount} coins!');
      },
    );
    _rewardedInterstitialAd.loadAd();
  }

  void _showInterstitialAd() async {
    final result = await _interstitialAd.showAd();

    if (!result.wasShown && mounted) {
      // You can provide specific messages or actions based on the fail reason
      switch (result.failReason) {
        case AdFailReason.adsDisabled:
          // Perhaps offer to enable ads for rewards
          break;
        case AdFailReason.cooldownPeriod:
          // Show countdown timer until next available ad
          break;
        case AdFailReason.notLoaded:
          // Show loading indicator and retry loading
          _rewardedAd.loadAd();
          break;
        case AdFailReason.showError:
          // Log the error or report to analytics
          break;
        case null:
          // Should not happen for failed ads
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  final _appOpenAdManager = AdmobAppOpenAd();
  void _showAppOpenAd() async {
    AdHelper.showAppOpenAds = true;
    final result = await _appOpenAdManager.showAdIfAvailable();

    if (!result.wasShown) {
      debugPrint("App Open Ad could not be shown: ${result.message}");
    }
  }

  @override
  void dispose() {
    _interstitialAd.dispose();
    _rewardedAd.dispose();
    _rewardedInterstitialAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showAds = AdHelper.showAds;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('AdMob All Ads Demo')),
      bottomNavigationBar: AdmobBannerAd(adSize: AdSize(width: screenWidth.toInt(), height: 120)),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AdmobNativeAd.small(),
              Text("Check the console logs", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  _showInterstitialAd();
                },
                child: const Text('Show Interstitial'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  _rewardedAd.showAd();
                },
                child: const Text('Show Rewarded'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _rewardedInterstitialAd.showAd();
                },
                child: const Text('Show Rewarded Interstitial'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  _showAppOpenAd();
                },
                child: const Text('Manual Show App Open Ad'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showAds = !showAds;
                    AdHelper.showAds = showAds;
                  });
                },
                child: Text(showAds ? 'Stop showing ads' : 'Start showing ads'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  MobileAds.instance.openAdInspector((error) {
                    // Error will be non-null if ad inspector closed due to an error.
                  });
                },
                child: Text("Ad Inspector"),
              ),
              if (_isPrivacyOptionsRequired) ...[
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    _consentManager.showPrivacyOptionsForm((formError) {
                      if (formError != null) {
                        debugPrint("${formError.errorCode}: ${formError.message}");
                      }
                    });
                  },
                  child: Text("Show GDPR Ad Privacy"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
