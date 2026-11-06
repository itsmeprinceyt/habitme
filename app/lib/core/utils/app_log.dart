import 'dart:collection';
import 'package:flutter/foundation.dart';

/// In-memory ring buffer of app logs, viewable from the Logs page.
abstract final class AppLog {
  static final Queue<String> _lines = Queue<String>();
  static const _maxLines = 600;

  /// Bumped on every add so listeners (the Logs page) can rebuild.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void add(String message) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    _lines.addLast('[$stamp] $message');
    while (_lines.length > _maxLines) {
      _lines.removeFirst();
    }
    version.value++;
  }

  static List<String> get lines => List.unmodifiable(_lines);

  static void clear() => _lines.clear();
}
