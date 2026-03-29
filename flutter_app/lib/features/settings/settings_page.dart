import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
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
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'New password must be at least 6 characters';
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
              child: const Text('Cancel'),
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
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Password updated')),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    currentController.dispose();
    newController.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete Account'),
          content: const Text(
            'This will remove your demo account from local storage and log you out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await widget.onDeleteAccount();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                value: _pushNotifications,
                onChanged: (value) =>
                    setState(() => _pushNotifications = value),
                title: const Text('Push notifications'),
                subtitle: const Text('Receive app alerts for new hotspots'),
              ),
              SwitchListTile(
                value: _emailAlerts,
                onChanged: (value) => setState(() => _emailAlerts = value),
                title: const Text('Email alerts'),
                subtitle: const Text('Get claim and advisory updates by email'),
              ),
              SwitchListTile(
                value: _offlineSync,
                onChanged: (value) => setState(() => _offlineSync = value),
                title: const Text('Offline sync'),
                subtitle: const Text('Cache field data for low connectivity'),
              ),
              const SizedBox(height: 10),
              FeatureCard(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Update your demo account credentials',
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 8),
              FeatureCard(
                icon: Icons.delete_outline,
                title: 'Delete account',
                subtitle: 'Permanently remove this local demo account',
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
