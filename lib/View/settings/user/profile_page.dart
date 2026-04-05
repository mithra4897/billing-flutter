import 'package:flutter/material.dart';

import '../../../app/constants/app_ui_constants.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../components/adaptive_shell.dart';
import '../../../components/app_loading_view.dart';
import '../../../core/storage/session_storage.dart';
import '../../../model/admin/user_model.dart';
import '../../../model/app/public_branding_model.dart';
import '../../../service/app/app_session_service.dart';
import '../../../service/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  UserModel? _profile;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _profilePhotoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _authService.profile();
      final profile = response.data;

      if (profile == null) {
        setState(() {
          _error = response.message.isEmpty
              ? 'Unable to load profile.'
              : response.message;
          _loading = false;
        });
        return;
      }

      _profile = profile;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _displayNameController.text = profile.displayName ?? '';
      _emailController.text = profile.email ?? '';
      _mobileController.text = profile.mobile ?? '';
      _dobController.text = profile.dateOfBirth ?? '';
      _profilePhotoController.text = profile.profilePhotoPath ?? '';
      _remarksController.text = profile.remarks ?? '';
      _gender = profile.gender;

      setState(() {
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await _authService.updateProfile(
        UserModel(
          id: _profile!.id,
          employeeCode: _profile!.employeeCode,
          username: _profile!.username,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim().isEmpty
              ? null
              : _lastNameController.text.trim(),
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty
              ? null
              : _mobileController.text.trim(),
          gender: _gender,
          dateOfBirth: _dobController.text.trim().isEmpty
              ? null
              : _dobController.text.trim(),
          profilePhotoPath: _profilePhotoController.text.trim().isEmpty
              ? null
              : _profilePhotoController.text.trim(),
          remarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      if (response.data != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        await _loadProfile();
      } else {
        setState(() {
          _error = response.message;
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AppSessionService.instance.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'Profile',
          branding: branding,
          onLogout: () => _logout(context),
          child: _loading
              ? const AppLoadingView(message: 'Loading profile...')
              : _ProfileContent(
                  formKey: _formKey,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  displayNameController: _displayNameController,
                  emailController: _emailController,
                  mobileController: _mobileController,
                  dobController: _dobController,
                  profilePhotoController: _profilePhotoController,
                  remarksController: _remarksController,
                  gender: _gender,
                  profile: _profile,
                  error: _error,
                  saving: _saving,
                  onGenderChanged: (value) => setState(() => _gender = value),
                  onSave: _save,
                ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.displayNameController,
    required this.emailController,
    required this.mobileController,
    required this.dobController,
    required this.profilePhotoController,
    required this.remarksController,
    required this.gender,
    required this.profile,
    required this.error,
    required this.saving,
    required this.onGenderChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController dobController;
  final TextEditingController profilePhotoController;
  final TextEditingController remarksController;
  final String? gender;
  final UserModel? profile;
  final String? error;
  final bool saving;
  final ValueChanged<String?> onGenderChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: appTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: appTheme.cardShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppUiConstants.cardPadding),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can update your personal details here. Sensitive fields like role, status, and access rights stay under user administration.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appTheme.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      runSpacing: 16,
                      spacing: 16,
                      children: [
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            initialValue: profile?.username ?? '',
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            initialValue: profile?.employeeCode ?? '',
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Employee Code',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: DropdownButtonFormField<String>(
                            initialValue: gender,
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                              DropdownMenuItem(
                                value: 'prefer_not_to_say',
                                child: Text('Prefer not to say'),
                              ),
                            ],
                            onChanged: onGenderChanged,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 260,
                          child: TextFormField(
                            controller: dobController,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              hintText: 'YYYY-MM-DD',
                            ),
                          ),
                        ),
                        _FormFieldBox(
                          width: 536,
                          child: TextFormField(
                            controller: profilePhotoController,
                            decoration: const InputDecoration(
                              labelText: 'Profile Photo Path',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: remarksController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Remarks'),
                    ),
                    if (error != null && error!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: saving ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(saving ? 'Saving...' : 'Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormFieldBox extends StatelessWidget {
  const _FormFieldBox({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
