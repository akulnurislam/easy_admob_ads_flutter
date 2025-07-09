import 'package:easy_admob_ads_flutter/src/ad_type.dart';

class AdmobConfig {
  final Map<AdType, String> ios;
  final Map<AdType, String> android;

  const AdmobConfig({required this.ios, required this.android});
}
