import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  bool _initStarted = false;
  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  void init() {
    if (_initStarted) return;
    _initStarted = true;
    UnityAds.init(
      gameId: AppConstants.unityGameId,
      testMode: AppConstants.unityTestMode,
      onComplete: () {
        ready.value = true;
        _loadInterstitial();
        _loadRewarded();
      },
      onFailed: (error, message) {
        _initStarted = false;
        debugPrint('Unity Ads init failed: $error $message');
      },
    );
  }

  void _loadInterstitial() {
    UnityAds.load(
      placementId: AppConstants.unityInterstitialId,
      onComplete: (_) => _interstitialLoaded = true,
      onFailed: (id, error, message) {
        _interstitialLoaded = false;
        debugPrint('Interstitial load failed: $error $message');
      },
    );
  }

  void _loadRewarded() {
    UnityAds.load(
      placementId: AppConstants.unityRewardedId,
      onComplete: (_) => _rewardedLoaded = true,
      onFailed: (id, error, message) {
        _rewardedLoaded = false;
        debugPrint('Rewarded load failed: $error $message');
      },
    );
  }

  Future<void> showInterstitial() {
    if (!_interstitialLoaded) {
      _loadInterstitial();
      return Future.value();
    }
    _interstitialLoaded = false;
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
      _loadInterstitial();
    }

    UnityAds.showVideoAd(
      placementId: AppConstants.unityInterstitialId,
      onComplete: (_) => finish(),
      onSkipped: (_) => finish(),
      onFailed: (id, error, message) {
        debugPrint('Interstitial show failed: $error $message');
        finish();
      },
    );
    return completer.future;
  }

  Future<bool> showRewarded() {
    if (!_rewardedLoaded) {
      _loadRewarded();
      return Future.value(false);
    }
    _rewardedLoaded = false;
    final completer = Completer<bool>();
    void finish(bool watched) {
      if (!completer.isCompleted) completer.complete(watched);
      _loadRewarded();
    }

    UnityAds.showVideoAd(
      placementId: AppConstants.unityRewardedId,
      onComplete: (_) => finish(true),
      onSkipped: (_) => finish(false),
      onFailed: (id, error, message) {
        debugPrint('Rewarded show failed: $error $message');
        finish(false);
      },
    );
    return completer.future;
  }
}
