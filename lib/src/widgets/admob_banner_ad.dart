import 'dart:async';

import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

class AdmobBannerAd extends StatefulWidget {
  final bool collapsible;
  final double? height;
  final void Function(AdState state)? onAdStateChanged;
  final bool keepSpaceWhenAdNotAvailable;

  const AdmobBannerAd({super.key, this.collapsible = false, this.height, this.onAdStateChanged, this.keepSpaceWhenAdNotAvailable = false});

  @override
  // ignore: library_private_types_in_public_api
  _AdmobBannerAdState createState() => _AdmobBannerAdState();
}

class _AdmobBannerAdState extends State<AdmobBannerAd> {
  static final Logger _logger = Logger('AdmobBannerAd');
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AdHelper.showAds) {
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    if (_bannerAd != null || _isAdLoaded) return;

    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(MediaQuery.of(context).size.width.truncate());

    if (adSize == null) {
      _logger.warning('⚠️ Adaptive ad size not available.');
      return;
    }

    setState(() {
      _adSize = adSize;
    });

    final adRequest = widget.collapsible ? const AdRequest(extras: {"collapsible": "bottom"}) : const AdRequest();

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: adSize,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _logger.info('✅ Banner ad loaded.');
          _retryTimer?.cancel();
          setState(() {
            _isAdLoaded = true;
          });
          widget.onAdStateChanged?.call(AdState.loaded);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _logger.warning('❌ Banner ad failed: ${error.message}');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
          widget.onAdStateChanged?.call(AdState.error);
          AdException.check(error, adUnitId: AdHelper.bannerAdUnitId, adType: "Banner Ad");

          // Retry loading ad after 30 seconds
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 30), () {
            if (mounted && AdHelper.showAds) {
              _logger.info('🔁 Retrying banner ad load...');
              _bannerAd = null;
              _loadBannerAd();
            }
          });
        },
        onAdOpened: (_) => _logger.fine('🔓 Banner ad opened'),
        onAdClosed: (_) => _logger.fine('🔒 Banner ad closed'),
        onAdImpression: (_) => _logger.fine('📊 Banner ad impression'),
        onAdClicked: (_) => _logger.fine('🖱️ Banner ad clicked'),
      ),
    );

    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdHelper.showAds) return const SizedBox.shrink();

    final isLoading = !_isAdLoaded || _bannerAd == null || _adSize == null;

    if (isLoading) {
      return Container(height: widget.height ?? _adSize?.height.toDouble(), width: _adSize?.width.toDouble(), alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2));
    }

    return Container(
      alignment: Alignment.center,
      height: widget.height ?? _adSize!.height.toDouble(),
      width: _adSize!.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
