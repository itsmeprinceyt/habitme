import 'package:flutter/material.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/services/ads_service.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdsService.instance.ready,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();
        return SizedBox(
          height: 50,
          child: Center(
            child: UnityBannerAd(
              placementId: AppConstants.unityBannerId,
              onFailed: (id, error, message) =>
                  debugPrint('Banner failed: $error $message'),
            ),
          ),
        );
      },
    );
  }
}
