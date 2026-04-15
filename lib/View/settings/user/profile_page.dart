import '../../../screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final MediaService _mediaService = MediaService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;
  bool _uploadingPhoto = false;
  String? _error;
  UserModel? _profile;
  String? _gender;
  bool _displayNameTouched = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_syncDisplayNameFromNameParts);
    _lastNameController.addListener(_syncDisplayNameFromNameParts);
    _displayNameController.addListener(_handleDisplayNameEdited);
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
      _dobController.text = _normalizeDate(profile.dateOfBirth);
      _profilePhotoController.text = profile.profilePhotoPath ?? '';
      _remarksController.text = profile.remarks ?? '';
      _gender = profile.gender;
      _displayNameTouched = (profile.displayName ?? '').trim().isNotEmpty;

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
              : _normalizeDate(_dobController.text.trim()),
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
        final messenger = ScaffoldMessenger.of(context);
        await AppSessionService.instance.refreshUserAccess();
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text(response.message)));
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

  Future<void> _uploadProfileImage() async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        if (mounted) setState(() => _uploadingPhoto = isLoading);
      },
      onSuccess: (filePath) {
        if (mounted) {
          setState(() {
            _profilePhotoController.text = filePath;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _error = error);
      },
      module: 'auth',
      documentType: 'users',
      documentId: _profile?.id,
      purpose: 'profile_photo',
      folder: 'users/profile',
      isPublic: true,
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _changingPassword = true;
      _error = null;
    });

    try {
      final response = await _authService.changePassword(
        ChangePasswordRequestModel({
          'current_password': _currentPasswordController.text.trim(),
          'new_password': _newPasswordController.text.trim(),
          'confirm_password': _confirmPasswordController.text.trim(),
        }),
      );

      if (!mounted) {
        return;
      }

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  void _handleDisplayNameEdited() {
    final generated = _generatedDisplayName;
    final current = _displayNameController.text.trim();
    if (current.isEmpty || current == generated) {
      _displayNameTouched = false;
      return;
    }

    _displayNameTouched = true;
  }

  void _syncDisplayNameFromNameParts() {
    if (_displayNameTouched) {
      return;
    }

    final generated = _generatedDisplayName;
    if (_displayNameController.text != generated) {
      _displayNameController.value = _displayNameController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  String get _generatedDisplayName {
    return [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  String _normalizeDate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '';
    }

    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
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
            passwordFormKey: _passwordFormKey,
            currentPasswordController: _currentPasswordController,
            newPasswordController: _newPasswordController,
            confirmPasswordController: _confirmPasswordController,
            changingPassword: _changingPassword,
            uploadingPhoto: _uploadingPhoto,
            onGenderChanged: (value) => setState(() => _gender = value),
            onDisplayNameEdited: _handleDisplayNameEdited,
            onSave: _save,
            onChangePassword: _changePassword,
            onUploadPhoto: _uploadProfileImage,
          );

    if (widget.embedded) {
      return content;
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'Profile',
          branding: branding,
          child: content,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.formKey,
    required this.passwordFormKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.displayNameController,
    required this.emailController,
    required this.mobileController,
    required this.dobController,
    required this.profilePhotoController,
    required this.remarksController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.gender,
    required this.profile,
    required this.error,
    required this.saving,
    required this.changingPassword,
    required this.uploadingPhoto,
    required this.onGenderChanged,
    required this.onDisplayNameEdited,
    required this.onSave,
    required this.onChangePassword,
    required this.onUploadPhoto,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormState> passwordFormKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController dobController;
  final TextEditingController profilePhotoController;
  final TextEditingController remarksController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String? gender;
  final UserModel? profile;
  final String? error;
  final bool saving;
  final bool changingPassword;
  final bool uploadingPhoto;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onDisplayNameEdited;
  final Future<void> Function() onSave;
  final Future<void> Function() onChangePassword;
  final Future<void> Function() onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: AppSectionCard(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                  SettingsFormWrap(
                    children: [
                      AppFormTextField(
                        controller: firstNameController,
                        labelText: 'First Name',
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'First name is required'
                            : null,
                      ),
                      AppFormTextField(
                        controller: lastNameController,
                        labelText: 'Last Name',
                      ),
                      AppFormTextField(
                        controller: displayNameController,
                        labelText: 'Display Name',
                        onChanged: (_) => onDisplayNameEdited(),
                      ),
                      AppFormTextField(
                        initialValue: profile?.username ?? '',
                        enabled: false,
                        labelText: 'Username',
                      ),
                      AppFormTextField(
                        initialValue: profile?.employeeCode ?? '',
                        enabled: false,
                        labelText: 'Employee Code',
                      ),
                      AppDropdownField<String>.fromMapped(
                        initialValue: gender,
                        labelText: 'Gender',
                        mappedItems: const [
                          AppDropdownItem(value: 'male', label: 'Male'),
                          AppDropdownItem(value: 'female', label: 'Female'),
                          AppDropdownItem(value: 'other', label: 'Other'),
                          AppDropdownItem(
                            value: 'prefer_not_to_say',
                            label: 'Prefer not to say',
                          ),
                        ],
                        onChanged: onGenderChanged,
                      ),
                      AppFormTextField(
                        controller: emailController,
                        labelText: 'Email',
                      ),
                      AppFormTextField(
                        controller: mobileController,
                        labelText: 'Mobile',
                      ),
                      AppFormTextField(
                        controller: dobController,
                        labelText: 'Date of Birth',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                      ),
                      UploadPathField(
                        controller: profilePhotoController,
                        labelText: 'Profile Photo Path',
                        isUploading: uploadingPhoto,
                        onUpload: onUploadPhoto,
                        previewUrl: AppConfig.resolvePublicFileUrl(
                          profilePhotoController.text,
                        ),
                        previewIcon: Icons.person_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    controller: remarksController,
                    maxLines: 3,
                    labelText: 'Remarks',
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
                    child: AppActionButton(
                      onPressed: saving ? null : onSave,
                      icon: Icons.save_outlined,
                      label: saving ? 'Saving...' : 'Save Profile',
                      busy: saving,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    'Change Password',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsFormWrap(
                          children: [
                            AppFormTextField(
                              controller: currentPasswordController,
                              labelText: 'Current Password',
                              obscureText: true,
                              validator: Validators.compose([
                                Validators.required('Current Password'),
                                Validators.optionalMaxLength(
                                  100,
                                  'Current Password',
                                ),
                              ]),
                            ),
                            AppFormTextField(
                              controller: newPasswordController,
                              labelText: 'New Password',
                              obscureText: true,
                              validator: (value) {
                                final requiredError = Validators.required(
                                  'New Password',
                                )(value);
                                if (requiredError != null) {
                                  return requiredError;
                                }
                                final trimmed = value!.trim();
                                if (trimmed.length < 6) {
                                  return 'New Password must be at least 6 characters';
                                }
                                if (trimmed.length > 100) {
                                  return 'New Password must be at most 100 characters';
                                }
                                if (trimmed ==
                                    currentPasswordController.text.trim()) {
                                  return 'New Password must be different from Current Password';
                                }
                                return null;
                              },
                            ),
                            AppFormTextField(
                              controller: confirmPasswordController,
                              labelText: 'Confirm Password',
                              obscureText: true,
                              validator: (value) {
                                final requiredError = Validators.required(
                                  'Confirm Password',
                                )(value);
                                if (requiredError != null) {
                                  return requiredError;
                                }
                                if (value!.trim() !=
                                    newPasswordController.text.trim()) {
                                  return 'Confirm Password must match New Password';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppActionButton(
                            onPressed: changingPassword
                                ? null
                                : onChangePassword,
                            icon: Icons.lock_reset_outlined,
                            label: changingPassword
                                ? 'Changing...'
                                : 'Change Password',
                            busy: changingPassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
