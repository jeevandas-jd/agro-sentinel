// lib/services/tutorial_service.dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef TutorialVoiceOption = ({String code, String label, String native});

class TutorialService extends ChangeNotifier {
  static final TutorialService _instance = TutorialService._();
  factory TutorialService() => _instance;
  TutorialService._();

  static const int _kPrefsVersion = 3;
  static const String _kPrefsVersionKey = 'tutorial_prefs_version';

  /// Languages that have bundled tutorial MP3 folders (`assets/audio/<code>/`).
  static const List<TutorialVoiceOption> voiceLanguageOptions = [
    (code: 'en', label: 'English', native: 'English'),
    (code: 'ml', label: 'Malayalam', native: 'മലയാളം'),
    (code: 'hi', label: 'Hindi', native: 'हिन्दी'),
  ];

  final AudioPlayer _player = AudioPlayer();
  String _lang = 'en';
  bool _enabled = true;
  bool _inited = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_inited) return;
    _initFuture ??= _init();
    await _initFuture;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final existingVersion = prefs.getInt(_kPrefsVersionKey) ?? 0;
    if (existingVersion != _kPrefsVersion) {
      for (final key in prefs.getKeys()) {
        if (key.startsWith('seen_')) {
          await prefs.remove(key);
        }
      }
      await prefs.setInt(_kPrefsVersionKey, _kPrefsVersion);
    }
    _lang = prefs.getString('tutorial_lang') ?? 'en';
    _enabled = prefs.getBool('tutorial_enabled') ?? true;
    _inited = true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_lang == lang) return;
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tutorial_lang', lang);
    notifyListeners();
  }

  Future<void> setEnabled(bool val) async {
    _enabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_enabled', val);
    if (!val) {
      await _player.stop();
    }
    notifyListeners();
  }

  bool get isEnabled => _enabled;
  String get currentLang => _lang;

  /// Key for [AudioPlayer.setAsset] / [rootBundle.load].
  String _tutorialAssetKey(String screenKey) {
    final relative = 'audio/$_lang/$screenKey.mp3';
    if (kIsWeb) return relative;
    return 'assets/$relative';
  }

  /// Plays tutorial audio for [screenKey] when tutorial is enabled.
  Future<void> speak(String screenKey) async {
    await init();
    if (!_enabled) return;

    final path = _tutorialAssetKey(screenKey);

    try {
      await _player.stop();
      await _player.setAsset(path);
      await _player.play();
    } catch (_) {}
  }

  Future<void> stop() => _player.stop();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
