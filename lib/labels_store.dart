/// Provides the [LabelsStore] class.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LabelsStore {
  final String _key = 'labels';
  final Map<String, String> _labels = <String, String>{};

  String getLabel(String code) => _labels[code];

  void addLabel(String code, String label) => _labels[code] = label;

  void removeLabel(String code) => _labels.remove(code);

  bool hasLabel(String code) => _labels.containsKey(code);

  Future<void> saveLabels() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_labels);
    prefs.setString(_key, data);
  }

  Future<void> loadLabels() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String json = prefs.getString(_key);
    if (json != null) {
      final Map<String, String> data = jsonDecode(json) as Map<String, String>;
      data.forEach((String key, String value) {
        _labels[key] = value;
      });
    }
  }
}

final LabelsStore labels = LabelsStore();
