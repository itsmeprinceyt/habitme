import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/app.dart';
import 'package:habit_me/core/utils/app_log.dart';
import 'package:habit_me/core/utils/expansion_preferences.dart';
import 'package:habit_me/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tee debugPrint into the in-app log viewer.
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) AppLog.add(message);
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  try {
    await ExpansionPreferences.instance.load();
  } catch (_) {}
  // Best-effort warm-up of the notification plugin. It must never delay the
  // first frame: the scheduler calls it again, in the background, whenever it
  // actually needs it.
  unawaited(NotificationService.instance.init().catchError((_) {}));
  runApp(const ProviderScope(child: HabitApp()));
}
