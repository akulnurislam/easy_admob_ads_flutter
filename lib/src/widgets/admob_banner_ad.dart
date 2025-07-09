import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobBannerAd extends StatefulWidget {
  final AdSize adSize;
  final void Function(AdState state)? onAdStateChanged;
  final bool keepSpaceWhenAdNotAvailable;

  const AdmobBannerAd({super.key, this.adSize = AdSize.banner, this.onAdStateChanged, this.keepSpaceWhenAdNotAvailable = false});

  @override
  _AdmobBannerAdState createState() => _AdmobBannerAdState();
}

class _AdmobBannerAdState extends State<AdmobBannerAd> {
  BannerAd? _bannerAd;
  AdState _adState = AdState.initial;

  @override
  void initState() {
    super.initState();
    if (AdHelper.showAds) {
      _loadAd();
    } else {
      _adState = AdState.closed;
      if (widget.onAdStateChanged != null) {
        widget.onAdStateChanged!(AdState.closed);
      }
    }
  }

  void _loadAd() {
    setState(() {
      _adState = AdState.loading;
    });

    if (widget.onAdStateChanged != null) {
      widget.onAdStateChanged!(AdState.loading);
    }

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _adState = AdState.loaded;
          });
          if (widget.onAdStateChanged != null) {
            widget.onAdStateChanged!(AdState.loaded);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _adState = AdState.error;
          });
          if (widget.onAdStateChanged != null) {
            widget.onAdStateChanged!(AdState.error);
          }
          AdException.check(error, adUnitId: AdHelper.bannerAdUnitId, adType: "Banner Ad");
          debugPrint('Banner ad failed to load: ${error.message}');

          // Retry loading after delay if there was an error
          Future.delayed(const Duration(minutes: 1), () {
            if (mounted && AdHelper.showAds) {
              _loadAd();
            }
          });
        },
        onAdClicked: (_) {
          debugPrint('Banner ad clicked');
        },
        onAdImpression: (_) {
          debugPrint('Banner ad impression recorded');
        },
        onAdClosed: (_) {
          setState(() {
            _adState = AdState.closed;
          });
          if (widget.onAdStateChanged != null) {
            widget.onAdStateChanged!(AdState.closed);
          }
        },
        onAdOpened: (_) {
          debugPrint('Banner ad opened');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are disabled globally and we don't need to keep space
    if (!AdHelper.showAds && !widget.keepSpaceWhenAdNotAvailable) {
      return const SizedBox.shrink();
    }

    if (_adState == AdState.loaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // If ads are disabled but we need to keep space, or if ad is loading/error
    if (widget.keepSpaceWhenAdNotAvailable || _adState == AdState.loading) {
      return Container(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        alignment: Alignment.center,
        child: _adState == AdState.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
      );
    }

    // Default: return empty widget
    return const SizedBox.shrink();
  }
}
