import 'package:flutter/material.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import '../../core/providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../main.dart' show AppLocaleScope;
import '../../widgets/language_picker_sheet.dart';
import '../../widgets/feature_card.dart';

class SettingsPage extends StatefulWidget {
  final Future<void> Function(String currentPassword, String newPassword)
  onChangePassword;
  final Future<void> Function() onDeleteAccount;

  const SettingsPage({
    super.key,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _offlineSync = true;
  bool _isProcessing = false;

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(l10n.changePasswordTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.currentPasswordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return l10n.newPasswordMinLength;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop();
                setState(() => _isProcessing = true);
                final messenger = ScaffoldMessenger.of(this.context);
                try {
                  await widget.onChangePassword(
                    currentController.text,
                    newController.text,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.passwordUpdated)),
                  );
                } catch (error) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: Text(l10n.update),
            ),
          ],
        );
      },
    );
    currentController.dispose();
    newController.dispose();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(l10n.deleteAccountTitle),
          content: Text(l10n.deleteAccountConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onDeleteAccount();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLanguagePicker() => showLanguagePickerSheet(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = AppLocaleScope.of(context);
    final currentLang = LocaleProvider.supportedLanguages.firstWhere(
      (l) => l.code == provider.locale.languageCode,
      orElse: () => LocaleProvider.supportedLanguages.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Language ────────────────────────────────────────────────
              FeatureCard(
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: '${currentLang.nativeName} · ${currentLang.name}',
                onTap: _showLanguagePicker,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // ── Notifications ────────────────────────────────────────────
              SwitchListTile(
                value: _pushNotifications,
                onChanged: (value) =>
                    setState(() => _pushNotifications = value),
                title: Text(l10n.pushNotifications),
                subtitle: Text(l10n.pushNotificationsSubtitle),
              ),
              SwitchListTile(
                value: _emailAlerts,
                onChanged: (value) => setState(() => _emailAlerts = value),
                title: Text(l10n.emailAlerts),
                subtitle: Text(l10n.emailAlertsSubtitle),
              ),
              SwitchListTile(
                value: _offlineSync,
                onChanged: (value) => setState(() => _offlineSync = value),
                title: Text(l10n.offlineSync),
                subtitle: Text(l10n.offlineSyncSubtitle),
              ),
              const SizedBox(height: 10),

              // ── Account ──────────────────────────────────────────────────
              FeatureCard(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                subtitle: l10n.changePasswordSubtitle,
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 8),
              FeatureCard(
                icon: Icons.delete_outline,
                title: l10n.deleteAccount,
                subtitle: l10n.deleteAccountSubtitle,
                onTap: _confirmDelete,
                trailing: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.alertHigh,
                ),
              ),
            ],
          ),
          if (_isProcessing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55080E08),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
