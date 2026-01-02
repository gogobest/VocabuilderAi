import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage Text-to-Speech configuration
class TtsConfigService {
  static const String _engineKey = 'tts_engine';
  static const String _languageKey = 'tts_language';
  static const String _rateKey = 'tts_rate';
  static const String _pitchKey = 'tts_pitch';
  static const String _volumeKey = 'tts_volume';
  
  /// Get the selected TTS engine
  Future<String?> getSelectedEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_engineKey);
  }
  
  /// Set the selected TTS engine
  Future<void> setSelectedEngine(String engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_engineKey, engine);
  }
  
  /// Get the selected language
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en-US';
  }
  
  /// Set the selected language
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }
  
  /// Get the speech rate (0.0 to 1.0)
  Future<double> getRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? 0.5;
  }
  
  /// Set the speech rate
  Future<void> setRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
  }
  
  /// Get the pitch (0.0 to 1.0)
  Future<double> getPitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_pitchKey) ?? 1.0;
  }
  
  /// Set the pitch
  Future<void> setPitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pitchKey, pitch);
  }
  
  /// Get the volume (0.0 to 1.0)
  Future<double> getVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 1.0;
  }
  
  /// Set the volume
  Future<void> setVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, volume);
  }
  
  /// Reset all TTS settings to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_engineKey);
    await prefs.remove(_languageKey);
    await prefs.setDouble(_rateKey, 0.5);
    await prefs.setDouble(_pitchKey, 1.0);
    await prefs.setDouble(_volumeKey, 1.0);
  }
} 