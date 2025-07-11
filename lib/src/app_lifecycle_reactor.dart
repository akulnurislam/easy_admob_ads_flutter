import 'dart:async';

import 'package:easy_admob_ads_flutter/src/widgets/admob_app_open_ad.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AppLifecycleReactor {
  static final Logger _logger = Logger('AppLifecycleReactor');

  final AdmobAppOpenAd appOpenAdManager;
  final Duration cooldownDuration;
  final Duration minimumBackgroundDuration;

  DateTime? _lastAdAttemptTime;
  DateTime? _backgroundEnterTime;

  AppLifecycleReactor({required this.appOpenAdManager, this.cooldownDuration = const Duration(seconds: 60), this.minimumBackgroundDuration = const Duration(minutes: 2)});

  void listenToAppStateChanges() {
    _logger.info('Started listening to app state changes.');
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen(_onAppStateChanged);
  }

  void _onAppStateChanged(AppState appState) {
    _logger.info('App state changed to: $appState');

    final now = DateTime.now();

    if (appState == AppState.background) {
      _backgroundEnterTime = now;
      // _logger.fine('Entered background at: $_backgroundEnterTime');
    }

    if (appState == AppState.foreground) {
      // Only proceed if background entry time is known
      if (_backgroundEnterTime != null) {
        final backgroundDuration = now.difference(_backgroundEnterTime!);

        if (backgroundDuration >= minimumBackgroundDuration) {
          // _logger.fine('Returned from REAL background (duration: ${backgroundDuration.inSeconds}s)');

          if (_lastAdAttemptTime == null || now.difference(_lastAdAttemptTime!) >= cooldownDuration) {
            _lastAdAttemptTime = now;
            _logger.fine('Cooldown passed. Triggering App Open Ad...');
            appOpenAdManager.showAdIfAvailable();
          } else {
            final remaining = cooldownDuration - now.difference(_lastAdAttemptTime!);
            _logger.fine('App Open Ad skipped due to cooldown. Time remaining: ${remaining.inSeconds}s');
          }
        } else {
          // _logger.fine('Returned from SHORT pause — not considered real background (duration: ${backgroundDuration.inMilliseconds}ms)');
        }

        // Reset background entry time
        _backgroundEnterTime = null;
      }
    }
  }
}

/// Notifies the app of app state changes
class AppStateEventNotifier {
  static final Logger _logger = Logger('AppLifecycleReactor');
  static final StreamController<AppState> _appStateController = StreamController<AppState>.broadcast();

  static StreamController<AppState> get _stateController => _appStateController;

  static Stream<AppState> get appStateStream => _stateController.stream;

  static void startListening() {
    _logger.fine('AppLifecycleObserver registered.');
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  static void stopListening() {
    _stateController.close();
  }

  static void _notifyAppState(AppState appState) {
    _logger.fine('AppStateEventNotifier notified: $appState');
    _stateController.add(appState);
  }
}

/// Observer that notifies [AppStateEventNotifier] of changes to the app lifecycle
class _AppLifecycleObserver extends WidgetsBindingObserver {
  static final Logger _logger = Logger('AppLifecycleReactor');
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.fine('Raw lifecycle event: $state');
    if (state == AppLifecycleState.resumed) {
      // App moved to foreground
      AppStateEventNotifier._notifyAppState(AppState.foreground);
    } else if (state == AppLifecycleState.paused) {
      // App moved to background
      AppStateEventNotifier._notifyAppState(AppState.background);
    }
  }
}

/// States of the app
enum AppState {
  foreground, // App is visible and active
  background, // App is not visible
}
