import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExpansionPreferences {
  ExpansionPreferences._();

  static final ExpansionPreferences instance = ExpansionPreferences._();

  File? _file;
  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/expansion_state.json');
    return _file!;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _cache = jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    _loaded = true;
  }

  bool getBool(String key, {bool defaultValue = true}) {
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    return defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value;
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(_cache), flush: true);
    } catch (_) {}
  }
}

