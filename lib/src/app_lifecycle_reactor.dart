import 'dart:async';

import 'package:easy_admob_ads_flutter/src/widgets/admob_app_open_ad.dart';
import 'package:flutter/material.dart';

class AppLifecycleReactor {
  final AdmobAppOpenAd appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) {
    // Show an app open ad when the app is brought to foreground
    if (appState == AppState.foreground) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}

/// Notifies the app of app state changes
class AppStateEventNotifier {
  static final StreamController<AppState> _appStateController = StreamController<AppState>.broadcast();

  static StreamController<AppState> get _stateController => _appStateController;

  static Stream<AppState> get appStateStream => _stateController.stream;

  static void startListening() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  static void stopListening() {
    _stateController.close();
  }

  static void _notifyAppState(AppState appState) {
    _stateController.add(appState);
  }
}

/// Observer that notifies [AppStateEventNotifier] of changes to the app lifecycle
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
