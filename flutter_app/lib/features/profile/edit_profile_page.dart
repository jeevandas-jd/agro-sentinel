import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_models.dart';
import '../auth/auth_validators.dart';

class EditProfilePage extends StatefulWidget {
  final DemoUser user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _regionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _regionController = TextEditingController(text: widget.user.region);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      widget.user.copyWith(
        name: _nameController.text.trim(),
        region: _regionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                validator: (value) =>
                    AuthValidators.requiredField(value, label: 'Name'),
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _regionController,
                validator: (value) =>
                    AuthValidators.requiredField(value, label: 'Region'),
                decoration: const InputDecoration(
                  labelText: 'Region',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
