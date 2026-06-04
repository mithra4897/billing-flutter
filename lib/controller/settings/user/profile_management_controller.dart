import '../../../screen.dart';

class ProfileManagementController extends GetxController {
  ProfileManagementController();

  final AuthService _authService = AuthService();
  final MediaService _mediaService = MediaService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController profilePhotoController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = true;
  bool saving = false;
  bool changingPassword = false;
  bool uploadingPhoto = false;
  String? error;
  UserModel? profile;
  String? gender;
  bool displayNameTouched = false;

  @override
  void onInit() {
    super.onInit();
    firstNameController.addListener(_syncDisplayNameFromNameParts);
    lastNameController.addListener(_syncDisplayNameFromNameParts);
    displayNameController.addListener(handleDisplayNameEdited);
    loadProfile();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    dobController.dispose();
    profilePhotoController.dispose();
    remarksController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    loading = true;
    error = null;
    update();

    try {
      final response = await _authService.profile();
      final loadedProfile = response.data;

      if (loadedProfile == null) {
        error = response.message.isEmpty
            ? 'Unable to load profile.'
            : response.message;
        loading = false;
        update();
        return;
      }

      profile = loadedProfile;
      firstNameController.text = loadedProfile.firstName ?? '';
      lastNameController.text = loadedProfile.lastName ?? '';
      displayNameController.text = loadedProfile.displayName ?? '';
      emailController.text = loadedProfile.email ?? '';
      mobileController.text = loadedProfile.mobile ?? '';
      dobController.text = normalizeDateValue(loadedProfile.dateOfBirth);
      profilePhotoController.text = loadedProfile.profilePhotoPath ?? '';
      remarksController.text = loadedProfile.remarks ?? '';
      gender = loadedProfile.gender;
      displayNameTouched = (loadedProfile.displayName ?? '').trim().isNotEmpty;
      loading = false;
    } catch (errorValue) {
      error = errorValue.toString();
      loading = false;
    }

    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || profile == null) {
      return;
    }

    saving = true;
    error = null;
    update();

    try {
      final response = await _authService.updateProfile(
        UserModel(
          id: profile!.id,
          employeeCode: profile!.employeeCode,
          username: profile!.username,
          firstName: firstNameController.text.trim(),
          lastName: nullIfEmpty(lastNameController.text),
          displayName: nullIfEmpty(displayNameController.text),
          email: nullIfEmpty(emailController.text),
          mobile: nullIfEmpty(mobileController.text),
          gender: gender,
          dateOfBirth: dobController.text.trim().isEmpty
              ? null
              : normalizeDateValue(dobController.text.trim()),
          profilePhotoPath: nullIfEmpty(profilePhotoController.text),
          remarks: nullIfEmpty(remarksController.text),
        ),
      );

      if (response.data != null) {
        await AppSessionService.instance.refreshUserAccess();
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        await loadProfile();
      } else {
        error = response.message;
        update();
      }
    } catch (errorValue) {
      error = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> uploadProfileImage(BuildContext context) async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (isLoading) {
        uploadingPhoto = isLoading;
        update();
      },
      onSuccess: (filePath) {
        profilePhotoController.text = filePath;
        error = null;
        update();
      },
      onError: (errorValue) {
        error = errorValue;
        update();
      },
      module: 'auth',
      documentType: 'users',
      documentId: profile?.id,
      purpose: 'profile_photo',
      folder: 'users/profile',
      isPublic: true,
    );
  }

  Future<void> changePassword() async {
    if (!passwordFormKey.currentState!.validate()) {
      return;
    }

    changingPassword = true;
    error = null;
    update();

    try {
      final response = await _authService.changePassword(
        ChangePasswordRequestModel(
          currentPassword: currentPasswordController.text.trim(),
          newPassword: newPasswordController.text.trim(),
          confirmPassword: confirmPasswordController.text.trim(),
        ),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (errorValue) {
      error = errorValue.toString();
      update();
    } finally {
      changingPassword = false;
      update();
    }
  }

  void setGender(String? value) {
    gender = value;
    update();
  }

  void handleDisplayNameEdited() {
    final generated = generatedDisplayName;
    final current = displayNameController.text.trim();
    if (current.isEmpty || current == generated) {
      displayNameTouched = false;
      return;
    }

    displayNameTouched = true;
  }

  void _syncDisplayNameFromNameParts() {
    if (displayNameTouched) {
      return;
    }

    final generated = generatedDisplayName;
    if (displayNameController.text != generated) {
      displayNameController.value = displayNameController.value.copyWith(
        text: generated,
        selection: TextSelection.collapsed(offset: generated.length),
      );
    }
  }

  String get generatedDisplayName {
    return [
      firstNameController.text.trim(),
      lastNameController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }
}
