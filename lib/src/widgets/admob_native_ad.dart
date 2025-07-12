import 'package:easy_admob_ads_flutter/src/ad_exceptions.dart';
import 'package:easy_admob_ads_flutter/src/ad_helper.dart';
import 'package:easy_admob_ads_flutter/src/models/ad_state.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';

/// A widget that displays a native ad using Google's pre-built templates
class AdmobNativeAd extends StatefulWidget {
  /// The height of the ad
  final double height;

  /// Callback for ad state changes
  final void Function(AdState state)? onAdStateChanged;

  /// Whether to keep space when ad is not available
  final bool keepSpaceWhenAdNotAvailable;

  /// The ad template style
  final NativeTemplateStyle templateStyle;

  /// Create a native ad widget
  const AdmobNativeAd({
    super.key,
    required this.height,
    this.onAdStateChanged,
    this.keepSpaceWhenAdNotAvailable = false,
    required this.templateStyle, // Made required to avoid default value issue
  });

  // Factory constructors for common template styles

  /// Creates a small native ad with default styling
  factory AdmobNativeAd.small({
    Key? key,
    double height = 120.0,
    void Function(AdState state)? onAdStateChanged,
    bool keepSpaceWhenAdNotAvailable = false,
    Color backgroundColor = Colors.white,
    double cornerRadius = 8.0,
  }) {
    return AdmobNativeAd(
      key: key,
      height: height,
      onAdStateChanged: onAdStateChanged,
      keepSpaceWhenAdNotAvailable: keepSpaceWhenAdNotAvailable,
      templateStyle: NativeTemplateStyle(templateType: TemplateType.small, mainBackgroundColor: backgroundColor, cornerRadius: cornerRadius),
    );
  }

  /// Creates a medium native ad with default styling
  factory AdmobNativeAd.medium({
    Key? key,
    double height = 320.0,
    void Function(AdState state)? onAdStateChanged,
    bool keepSpaceWhenAdNotAvailable = false,
    Color backgroundColor = Colors.white,
    double cornerRadius = 8.0,
  }) {
    return AdmobNativeAd(
      key: key,
      height: height,
      onAdStateChanged: onAdStateChanged,
      keepSpaceWhenAdNotAvailable: keepSpaceWhenAdNotAvailable,
      templateStyle: NativeTemplateStyle(templateType: TemplateType.medium, mainBackgroundColor: backgroundColor, cornerRadius: cornerRadius),
    );
  }

  @override
  // ignore: library_private_types_in_public_api
  _AdmobNativeAdState createState() => _AdmobNativeAdState();
}

class _AdmobNativeAdState extends State<AdmobNativeAd> {
  static final Logger _logger = Logger('AdmobNativeAd');
  NativeAd? _nativeAd;
  AdState _adState = AdState.initial;
  bool _isAdLoaded = false;
  int _retryAttempt = 0;
  final int _maxRetryAttempts = 3;

  @override
  void initState() {
    super.initState();
    if (AdHelper.showAds) {
      _loadAd();
    } else {
      _adState = AdState.disabled;
      if (widget.onAdStateChanged != null) {
        widget.onAdStateChanged!(AdState.disabled);
      }
    }
  }

  void _loadAd() {
    _logger.info('Loading native ad...');
    setState(() {
      _adState = AdState.loading;
      _isAdLoaded = false;
    });

    if (widget.onAdStateChanged != null) {
      widget.onAdStateChanged!(AdState.loading);
    }

    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _logger.info('Native ad loaded successfully.');
          if (mounted) {
            setState(() {
              _adState = AdState.loaded;
              _isAdLoaded = true;
              _retryAttempt = 0; // Reset retry counter on success
            });
            if (widget.onAdStateChanged != null) {
              widget.onAdStateChanged!(AdState.loaded);
            }
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _logger.warning('Native ad failed to load: ${error.message}');
          AdException.check(error, adUnitId: AdHelper.nativeAdUnitId, adType: "Native Ad");
          if (mounted) {
            setState(() {
              _adState = AdState.error;
              _isAdLoaded = false;
            });
            if (widget.onAdStateChanged != null) {
              widget.onAdStateChanged!(AdState.error);
            }
          }

          // Implement exponential backoff for retries
          if (_retryAttempt < _maxRetryAttempts && mounted) {
            _retryAttempt++;
            final int retryDelay = _retryAttempt * 20; // Increasing delay with each retry
            _logger.fine('Retrying native ad load in $retryDelay seconds (attempt $_retryAttempt of $_maxRetryAttempts)');
            Future.delayed(Duration(seconds: retryDelay), () {
              if (mounted) _loadAd();
            });
          }
        },
        onAdOpened: (_) => _logger.fine('Native ad opened.'),
        onAdClosed: (_) => _logger.fine('Native ad closed.'),
        onAdImpression: (_) => _logger.fine('Native ad impression recorded.'),
        onAdClicked: (_) => _logger.fine('Native ad clicked.'),
      ),
      // Use the template style
      nativeTemplateStyle: widget.templateStyle,
      request: const AdRequest(),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are disabled globally and we don't need to keep space
    if (!AdHelper.showAds && !widget.keepSpaceWhenAdNotAvailable) {
      _logger.fine('Ads are disabled. Native ad will not load.');
      return const SizedBox.shrink();
    }

    if (_adState == AdState.loaded && _isAdLoaded && _nativeAd != null) {
      return SizedBox(
        height: widget.height,
        child: AdWidget(ad: _nativeAd!),
      );
    }

    // If ads are disabled but we need to keep space, or if ad is loading/error
    if (widget.keepSpaceWhenAdNotAvailable || _adState == AdState.loading) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: _adState == AdState.loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : _adState == AdState.error
            ? const Text('Ad not available')
            : null,
      );
    }

    // Default: return empty widget
    return const SizedBox.shrink();
  }
}
