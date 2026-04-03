// lib/services/tutorial_service.dart
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._();
  factory TutorialService() => _instance;
  TutorialService._();

  final AudioPlayer _player = AudioPlayer();
  String _lang = 'en';
  bool _enabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lang    = prefs.getString('tutorial_lang')  ?? 'en';
    _enabled = prefs.getBool('tutorial_enabled') ?? true;
  }

  Future<void> setLanguage(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tutorial_lang', lang);
  }

  Future<void> setEnabled(bool val) async {
    _enabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_enabled', val);
  }

  bool get isEnabled => _enabled;
  String get currentLang => _lang;

  Future<bool> _isFirstVisit(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('seen_$screenKey') ?? false);
  }

  Future<void> _markSeen(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_$screenKey', true);
  }

  Future<void> speak(String screenKey, {bool force = false}) async {
    if (!_enabled) return;
    final first = await _isFirstVisit(screenKey);
    if (!first && !force) return;

    // Path: assets/audio/en/camera.mp3
    final path = 'assets/audio/$_lang/$screenKey.mp3';

    try {
      await _markSeen(screenKey);
      await _player.stop();
      await _player.setAsset(path);
      await _player.play();
    } catch (e) {
      // File missing for this language — silently skip
      
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
