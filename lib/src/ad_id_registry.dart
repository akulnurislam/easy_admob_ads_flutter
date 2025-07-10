import 'package:flutter/foundation.dart';
import 'ad_type.dart';

class AdIdRegistry {
  static Map<AdType, String>? _iosAdIds;
  static Map<AdType, String>? _androidAdIds;

  /// Allow user to provide either iOS, Android, or both
  static void initialize({Map<AdType, String>? ios, Map<AdType, String>? android}) {
    if (ios != null) _iosAdIds = ios;
    if (android != null) _androidAdIds = android;
  }

  /// Returns platform-specific ad IDs or throws if not initialized
  static Map<AdType, String> get currentPlatformAdIds {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_iosAdIds != null) return _iosAdIds!;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      if (_androidAdIds != null) return _androidAdIds!;
    }

    throw Exception(
      'AdIdRegistry not initialized for platform: $defaultTargetPlatform. '
      'Please call AdIdRegistry.initialize() with the required AdType map.',
    );
  }
}
