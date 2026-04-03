import 'package:flutter/material.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import '../core/providers/locale_provider.dart';
import '../main.dart' show AppLocaleScope;
import '../theme/app_theme.dart';

/// Shows the language selection bottom sheet.
/// Can be called from any screen that has access to the widget tree.
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
      // Cap sheet at 75% of screen height so it never overflows
      final maxHeight = MediaQuery.of(ctx).size.height * 0.75;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
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

              // ── Scrollable language list ───────────────────────────────
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: LocaleProvider.supportedLanguages.length,
                  itemBuilder: (_, index) {
                    final lang = LocaleProvider.supportedLanguages[index];
                    final isSelected = lang.code == currentCode;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.inputFill,
                        child: Text(
                          lang.nativeName.characters.first,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      title: Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
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
                      trailing: isSelected
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
