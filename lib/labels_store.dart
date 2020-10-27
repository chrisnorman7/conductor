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
      final Map<dynamic, dynamic> data =
          jsonDecode(json) as Map<dynamic, dynamic>;
      data.forEach((dynamic key, dynamic value) {
        _labels[key as String] = value as String;
      });
    }
  }
}

final LabelsStore labels = LabelsStore();
