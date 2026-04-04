import 'package:flutter/material.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import '../core/providers/locale_provider.dart';
import '../main.dart' show AppLocaleScope;
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';

/// Spoken tutorial MP3 language only (en / ml / hi).
void showTutorialVoicePickerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.55;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListenableBuilder(
            listenable: TutorialService(),
            builder: (context, _) {
              final svc = TutorialService();
              final current = svc.currentLang;
              return ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tutorial voice',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Voice hints use files in assets/audio/<language>/.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  for (final opt in TutorialService.voiceLanguageOptions)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: opt.code == current
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.inputFill,
                        child: Text(
                          opt.native.characters.first,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: opt.code == current
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      title: Text(
                        opt.native,
                        style: TextStyle(
                          fontWeight: opt.code == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: opt.code == current
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        opt.label,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: opt.code == current
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: AppColors.border,
                              size: 18,
                            ),
                      onTap: () async {
                        await svc.setLanguage(opt.code);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/// App UI language + tutorial voice section.
void showLanguagePickerSheet(BuildContext context) {
  final provider = AppLocaleScope.of(context);
  final currentCode = provider.locale.languageCode;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final maxHeight = MediaQuery.of(ctx).size.height * 0.75;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.selectLanguage,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              for (final lang in LocaleProvider.supportedLanguages)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: lang.code == currentCode
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.inputFill,
                    child: Text(
                      lang.nativeName.characters.first,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: lang.code == currentCode
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight: lang.code == currentCode
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: lang.code == currentCode
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    lang.name,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: lang.code == currentCode
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: AppColors.border,
                          size: 18,
                        ),
                  onTap: () {
                    provider.setLocale(Locale(lang.code));
                    Navigator.of(ctx).pop();
                  },
                ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tutorial voice',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showTutorialVoicePickerSheet(context);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: TutorialService(),
                builder: (context, _) {
                  final code = TutorialService().currentLang;
                  var label = code.toUpperCase();
                  for (final o in TutorialService.voiceLanguageOptions) {
                    if (o.code == code) {
                      label = o.native;
                      break;
                    }
                  }
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    title: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Spoken screen hints (separate from app language)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      showTutorialVoicePickerSheet(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
