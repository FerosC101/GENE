// lib/core/config/api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // For web, we'll use hardcoded values since .env doesn't work well with web
  // For mobile, we'll try to use .env first, then fall back to these
  
  static const String _googleMapsApiKeyFallback = 'AIzaSyClM3oua_QM_fSy_9WgnhQK6jkoN50lGTc';
  static const String _geminiApiKeyFallback = 'AIzaSyCB0fj0yJovgsMjtpCY_klPnFGfDFNX52I';
  
  static String get googleMapsApiKey {
    try {
      final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      // dotenv not loaded, use fallback
    }
    return _googleMapsApiKeyFallback;
  }
  
  static String get geminiApiKey {
    try {
      final key = dotenv.env['GEMINI_API_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      // dotenv not loaded, use fallback
    }
    return _geminiApiKeyFallback;
  }
}
