import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/app.dart';
import 'package:habit_me/core/utils/expansion_preferences.dart';
import 'package:habit_me/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  runApp(const ProviderScope(child: HabitApp()));
}
