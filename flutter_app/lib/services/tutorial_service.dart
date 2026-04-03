// lib/services/tutorial_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._();
  factory TutorialService() => _instance;
  TutorialService._();

  // Bump this whenever tutorial logic/screenKey mapping changes.
  // When it changes, we clear `seen_*` so tutorials can re-play.
  static const int _kPrefsVersion = 1;
  static const String _kPrefsVersionKey = 'tutorial_prefs_version';

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
    _lang    = prefs.getString('tutorial_lang')  ?? 'en';
    _enabled = prefs.getBool('tutorial_enabled') ?? true;
    _inited = true;
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

  /// Key for [AudioPlayer.setAsset] / [rootBundle.load].
  ///
  /// On **web**, the engine resolves assets as `<base>assets/<key>` (see
  /// `flutter_web_sdk/.../asset_manager.dart`). Pubspec entries are usually
  /// `assets/audio/...`; passing that full string makes the browser request
  /// `assets/assets/audio/...` (404).
  String _tutorialAssetKey(String screenKey) {
    final relative = 'audio/$_lang/$screenKey.mp3';
    if (kIsWeb) return relative;
    return 'assets/$relative';
  }

  Future<void> speak(String screenKey, {bool force = false}) async {
    await init();
    if (!_enabled) return;
    final first = await _isFirstVisit(screenKey);
    if (!first && !force) return;

    final path = _tutorialAssetKey(screenKey);

    try {
      await _player.stop();
      await _player.setAsset(path);
      await _player.play();
      // Only mark as "seen" once the asset loaded successfully.
      await _markSeen(screenKey);
    } catch (e) {
      // File missing for this language/screen — mark as seen so we don't retry.
      await _markSeen(screenKey);
      
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
