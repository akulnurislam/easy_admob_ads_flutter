import 'dart:async';

import 'package:easy_admob_ads_flutter/src/widgets/admob_app_open_ad.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AppLifecycleReactor {
  static final Logger _logger = Logger('AppLifecycleReactor');
  final AdmobAppOpenAd appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    _logger.info('Started listening to app state changes.');
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) {
    _logger.info('App state changed to: $appState');
    // Show an app open ad when the app is brought to foreground
    if (appState == AppState.foreground) {
      _logger.fine('Triggering App Open Ad...');
      appOpenAdManager.showAdIfAvailable();
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
