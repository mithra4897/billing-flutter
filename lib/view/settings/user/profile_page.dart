import '../../../controller/settings/user/profile_management_controller.dart';
import '../../../screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('ProfileManagementController');
    Get.put(ProfileManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final content = controller.loading
            ? const AppLoadingView(message: 'Loading profile...')
            : _ProfileContent(controller: controller);

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
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.controller});

  final ProfileManagementController controller;

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
              key: controller.formKey,
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
                        controller: controller.firstNameController,
                        labelText: 'First Name',
                        validator: Validators.required('First name'),
                      ),
                      AppFormTextField(
                        controller: controller.lastNameController,
                        labelText: 'Last Name',
                      ),
                      AppFormTextField(
                        controller: controller.displayNameController,
                        labelText: 'Display Name',
                        onChanged: (_) => controller.handleDisplayNameEdited(),
                      ),
                      AppFormTextField(
                        initialValue: controller.profile?.username ?? '',
                        enabled: false,
                        labelText: 'Username',
                      ),
                      AppFormTextField(
                        initialValue: controller.profile?.employeeCode ?? '',
                        enabled: false,
                        labelText: 'Employee Code',
                      ),
                      AppDropdownField<String>.fromMapped(
                        initialValue: controller.gender,
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
                        onChanged: controller.setGender,
                      ),
                      AppFormTextField(
                        controller: controller.emailController,
                        labelText: 'Email',
                      ),
                      AppFormTextField(
                        controller: controller.mobileController,
                        labelText: 'Mobile',
                      ),
                      AppFormTextField(
                        controller: controller.dobController,
                        labelText: 'Date of Birth',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                      ),
                      UploadPathField(
                        controller: controller.profilePhotoController,
                        labelText: 'Profile Photo Path',
                        isUploading: controller.uploadingPhoto,
                        onUpload: () => controller.uploadProfileImage(context),
                        previewUrl: AppConfig.resolvePublicFileUrl(
                          controller.profilePhotoController.text,
                        ),
                        previewIcon: Icons.person_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    controller: controller.remarksController,
                    maxLines: 3,
                    labelText: 'Remarks',
                  ),
                  if ((controller.error ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AppErrorStateView.inline(message: controller.error!),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppActionButton(
                      onPressed: controller.saving ? null : controller.save,
                      icon: Icons.save_outlined,
                      label: controller.saving ? 'Saving...' : 'Save Profile',
                      busy: controller.saving,
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
                    key: controller.passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsFormWrap(
                          children: [
                            AppFormTextField(
                              controller: controller.currentPasswordController,
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
                              controller: controller.newPasswordController,
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
                                    controller.currentPasswordController.text
                                        .trim()) {
                                  return 'New Password must be different from Current Password';
                                }
                                return null;
                              },
                            ),
                            AppFormTextField(
                              controller: controller.confirmPasswordController,
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
                                    controller.newPasswordController.text
                                        .trim()) {
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
                            onPressed: controller.changingPassword
                                ? null
                                : controller.changePassword,
                            icon: Icons.lock_reset_outlined,
                            label: controller.changingPassword
                                ? 'Changing...'
                                : 'Change Password',
                            busy: controller.changingPassword,
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
