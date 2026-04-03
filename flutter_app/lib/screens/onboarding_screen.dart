import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show AppLocaleScope;
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';

const _kOnboardingCompletedKey = 'onboarding_completed';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  String? _preferredLang; // app locale
  bool? _tutorialEnabled;
  String _tutorialLang = 'en';

  static const _preferredOptions = <({String code, String label, String native})>[
    (code: 'en', label: 'English', native: 'English'),
    (code: 'ml', label: 'Malayalam', native: 'മലയാളം'),
    (code: 'hi', label: 'Hindi', native: 'हिन्दी'),
  ];

  bool get _canContinue {
    if (_step == 0) return _preferredLang != null;
    if (_step == 1) return _tutorialEnabled != null;
    return true;
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_tutorialEnabled == true) {
        setState(() => _step = 2);
      } else {
        await _finish();
      }
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  Future<void> _finish() async {
    final preferred = _preferredLang ?? 'en';
    final localeProvider = AppLocaleScope.of(context);
    await localeProvider.setLocale(Locale(preferred));

    final tutorial = TutorialService();
    await tutorial.setEnabled(_tutorialEnabled ?? false);
    if (_tutorialEnabled == true) {
      await tutorial.setLanguage(_tutorialLang);
    }

    final prefs = await SharedPreferences.getInstance();
    // If the user changes tutorial preferences, we want tutorials to re-play
    // from the beginning on the next screens.
    for (final key in prefs.getKeys()) {
      if (key.startsWith('seen_')) {
        await prefs.remove(key);
      }
    }
    await prefs.setBool(_kOnboardingCompletedKey, true);

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Preferred language',
      1 => 'Tutorial',
      _ => 'Tutorial language',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (_step) {
                          0 => 'Choose your app language',
                          1 => 'Do you want voice tutorial guidance?',
                          _ => 'Choose tutorial language',
                        },
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        switch (_step) {
                          0 =>
                            'You can change this later from the app menu.',
                          1 =>
                            'Tutorial audio will play automatically on first visit to screens.',
                          _ =>
                            'This only affects tutorial audio.',
                        },
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      if (_step == 0) ...[
                        for (final opt in _preferredOptions)
                          RadioListTile<String>(
                            value: opt.code,
                            groupValue: _preferredLang,
                            onChanged: (v) => setState(() => _preferredLang = v),
                            title: Text(opt.native),
                            subtitle: Text(opt.label),
                          ),
                      ] else if (_step == 1) ...[
                        RadioListTile<bool>(
                          value: true,
                          groupValue: _tutorialEnabled,
                          onChanged: (v) => setState(() => _tutorialEnabled = v),
                          title: const Text('Yes, enable tutorial'),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: _tutorialEnabled,
                          onChanged: (v) => setState(() => _tutorialEnabled = v),
                          title: const Text('No, skip'),
                        ),
                      ] else ...[
                        for (final opt in TutorialService.voiceLanguageOptions)
                          RadioListTile<String>(
                            value: opt.code,
                            groupValue: _tutorialLang,
                            onChanged: (v) =>
                                setState(() => _tutorialLang = v ?? 'en'),
                            title: Text(opt.native),
                            subtitle: Text(opt.label),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canContinue ? _continue : null,
                  child: Text(_step == 2 || _tutorialEnabled == false
                      ? 'Finish'
                      : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

