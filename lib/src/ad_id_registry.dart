import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'ad_type.dart';

class AdIdRegistry {
  static final Logger _logger = Logger('AdIdRegistry');

  static Map<AdType, String>? _iosAdIds;
  static Map<AdType, String>? _androidAdIds;

  /// Allow user to provide either iOS, Android, or both
  static void initialize({Map<AdType, String>? ios, Map<AdType, String>? android}) {
    if (ios != null) {
      _iosAdIds = ios;
      _logger.info('iOS Ad IDs initialized with ${ios.length} entries.');
    }

    if (android != null) {
      _androidAdIds = android;
      _logger.info('Android Ad IDs initialized with ${android.length} entries.');
    }

    if (ios == null && android == null) {
      _logger.warning('AdIdRegistry.initialize called with no data.');
    }
  }

  /// Returns platform-specific ad IDs or throws if not initialized
  static Map<AdType, String> get currentPlatformAdIds {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        if (_iosAdIds != null) {
          return _iosAdIds!;
        }
        break;

      case TargetPlatform.android:
        if (_androidAdIds != null) {
          return _androidAdIds!;
        }
        break;

      default:
        _logger.severe('Unsupported platform: $defaultTargetPlatform');
        throw UnsupportedError('Platform $defaultTargetPlatform is not supported.');
    }

    _logger.severe(
      'Ad IDs not initialized for $defaultTargetPlatform. '
      'Call AdIdRegistry.initialize() with appropriate values.',
    );

    throw Exception(
      'AdIdRegistry not initialized for platform: $defaultTargetPlatform. '
      'Please call AdIdRegistry.initialize() with the required AdType map.',
    );
  }

  /// Checks if Ad IDs are available for the current platform
  static bool get isInitialized {
    return (defaultTargetPlatform == TargetPlatform.iOS && _iosAdIds != null) || (defaultTargetPlatform == TargetPlatform.android && _androidAdIds != null);
  }
}
