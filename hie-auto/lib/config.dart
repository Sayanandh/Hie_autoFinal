import 'dart:convert';
import 'package:flutter/services.dart';

// Create a configuration service for app settings
class ConfigService {
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config.json');
      return json.decode(jsonString);
    } catch (e) {
      return {};
    }
  }
} 