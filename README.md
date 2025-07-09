[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

# Easy AdMob Integration for Flutter

[![pub package](https://img.shields.io/pub/v/easy_admob_ads_flutter.svg?logo=dart\&logoColor=00b9fc)](https://pub.dev/packages/easy_admob_ads_flutter)
[![Last Commit](https://img.shields.io/github/last-commit/huzaibsayyed/easy_admob_ads_flutter?logo=git\&logoColor=white)](https://github.com/huzaibsayyed/easy_admob_ads_flutter/commits/main)
[![Pull Requests](https://img.shields.io/github/issues-pr/huzaibsayyed/easy_admob_ads_flutter?logo=github\&logoColor=white)](https://github.com/huzaibsayyed/easy_admob_ads_flutter/pulls)
[![Code Size](https://img.shields.io/github/languages/code-size/huzaibsayyed/easy_admob_ads_flutter?logo=github\&logoColor=white)](https://github.com/huzaibsayyed/easy_admob_ads_flutter)
[![License](https://img.shields.io/github/license/huzaibsayyed/easy_admob_ads_flutter?logo=open-source-initiative\&logoColor=green)](https://github.com/huzaibsayyed/easy_admob_ads_flutter/blob/main/LICENSE)

**Show some 💙 by giving the repo a ⭐ and liking the package on pub.dev!**

## Features

This package simplifies integrating multiple AdMob ad formats in your Flutter apps, including:

* Banner
* Interstitial
* Rewarded
* Rewarded Interstitial
* App Open Ads
* Native Ads

## Getting Started

To get started with `easy_admob_ads_flutter`, follow the steps below to integrate AdMob ads into your Flutter app.


### 1. Install the package

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  easy_admob_ads_flutter: ^<latest_version>
```

> Replace `<latest_version>` with the latest version on [pub.dev](https://pub.dev/packages/easy_admob_ads_flutter)

**OR** install it directly via terminal:

```bash
flutter pub add easy_admob_ads_flutter
```

### 2. Configure platform-specific AdMob setup

#### Android

* Open your `android/app/src/main/AndroidManifest.xml`
* Add your AdMob App ID inside the `<application>` tag:

```xml
<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

#### iOS

* Open your `ios/Runner/Info.plist` and add:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### 3. Initialize the SDK and pass your Ad Unit IDs

Inside your `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ad unit IDs for Android and/or iOS (required for at least one)
  AdIdRegistry.initialize(
    ios: {
      AdType.banner: "ca-app-pub-ios-banner",
      AdType.interstitial: "ca-app-pub-ios-interstitial",
      AdType.rewarded: "ca-app-pub-ios-rewarded",
      AdType.rewardedInterstitial: "ca-app-pub-ios-rewarded-int",
      AdType.appOpen: "ca-app-pub-ios-appopen",
      AdType.native: "", // Leave empty to skip a specific type
    },
    android: {
      AdType.banner: "ca-app-pub-android-banner",
      AdType.interstitial: "ca-app-pub-android-interstitial",
      AdType.rewarded: "ca-app-pub-android-rewarded",
      AdType.rewardedInterstitial: "ca-app-pub-android-rewarded-int",
      AdType.appOpen: "ca-app-pub-android-appopen",
      AdType.native: "", // Leave empty to skip a specific type
    },
  );

  // Optional: configure ad visibility
  AdHelper.showAds = true;
  AdHelper.showAppOpenAds = true;

  // Initialize Google Mobile Ads
  await AdmobService().initialize();

  runApp(const MyApp());
}
```

See the full example in the [`example/`](https://github.com/huzaibsayyed/easy_admob_ads_flutter) folder of this repository for complete usage of all ad types with interactive UI.

## Usage

After initializing AdMob and registering your ad unit IDs, you can use the following widgets and classes to display ads:

### Banner Ad

```dart
AdmobBannerAd(adSize: AdSize(width: screenWidth, height: 120))
```

### Native Ad

```dart
AdmobNativeAd.medium()
```

### Interstitial Ad

```dart
final interstitialAd = AdmobInterstitialAd();
interstitialAd.loadAd();
interstitialAd.showAd();
```

### Rewarded Ad

```dart
final rewardedAd = AdmobRewardedAd(
  onRewardEarned: (reward) {
    // Grant the user a reward
  },
);
rewardedAd.loadAd();
rewardedAd.showAd();
```

### Rewarded Interstitial Ad

```dart
final rewardedInterstitialAd = AdmobRewardedInterstitialAd(
  onRewardEarned: (reward) {
    // Grant reward here
  },
);
rewardedInterstitialAd.loadAd();
rewardedInterstitialAd.showAd();
```

### App Open Ad

```dart
final appOpenAd = AdmobAppOpenAd();
appOpenAd.loadAd();
appOpenAd.showAdIfAvailable();
```

You can also control when App Open ads show automatically using: `AdHelper.showAppOpenAds = true;`

## Author

##### Huzaib Sayyed

[![GitHub](https://img.shields.io/badge/GitHub-%23121011.svg?logo=github&logoColor=white)](https://github.com/huzaibsayyed) [![LinkedIn](https://custom-icon-badges.demolab.com/badge/LinkedIn-0A66C2?logo=linkedin-white&logoColor=fff)](https://www.linkedin.com/in/huzaif7)