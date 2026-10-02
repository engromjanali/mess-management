import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/common_labeled_input_item_widget.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Edit the signed-in user's photo, name, email, phone and address.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, UserEntity?>((bloc) => bloc.state.maybeWhen(authenticated: (user) => user, orElse: () => null));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: user == null ? const Center(child: CircularProgressIndicator.adaptive()) : _EditProfileForm(user: user),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.user});
  final UserEntity user;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  /// Brand green kept identical in light and dark mode, matching the auth forms.
  static const Color _prefixIconColor = Color(0xFF1FA463);
  static final RegExp _phonePattern = RegExp(r'^\+?\d{10,15}$');

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  late final _phoneController = TextEditingController(text: widget.user.phone ?? '');
  late final _addressController = TextEditingController(text: widget.user.address ?? '');
  bool _saving = false;
  Uint8List? _photoBytes;
  String? _photoName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'Phone ${context.local.validation_is_required}';
    return _phonePattern.hasMatch(phone) ? null : context.local.validation_invalid_phone;
  }

  /// Picks a downscaled gallery image; it is uploaded only when the form is saved.
  Future<void> _pickPhoto() async {
    if (_saving) return;
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
      });
    } catch (_) {
      if (mounted) context.showErrorSnackBar('Could not open your photos. Please allow photo access and try again.');
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final result = await getIt<UpdateProfileUseCase>()(
      UpdateProfileParams(fullName: _nameController.text.trim(), email: _emailController.text.trim(), phone: _phoneController.text.trim(), address: _addressController.text.trim(), photoBytes: _photoBytes, photoName: _photoName),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (success) {
        context.read<AuthBloc>().add(AuthEvent.userUpdated(success.data));
        context.showSuccessSnackBar('Profile updated');
        context.pop();
      },
      failure: (failure) => context.showErrorSnackBar(failure.message.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            children: [
              Center(child: _PhotoPicker(photoUrl: widget.user.photoUrl, pickedBytes: _photoBytes, onTap: _saving ? null : _pickPhoto)),
              const SizedBox(height: Dimensions.spaceLarge),
              CommonLabeledInputItemWidget(
                label: 'Full name',
                hintText: 'Full name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                prefixIconColor: _prefixIconColor,
                borderRadius: Dimensions.radiusLarge,
                isRequired: true,
              ),
              const SizedBox(height: Dimensions.spaceDefault),
              CommonLabeledInputItemWidget(
                label: context.local.email,
                hintText: context.local.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                prefixIconColor: _prefixIconColor,
                borderRadius: Dimensions.radiusLarge,
                isRequired: true,
              ),
              const SizedBox(height: Dimensions.spaceDefault),
              // Stored numbers may already include a country code, so no picker here.
              CommonLabeledInputItemWidget(
                label: 'Phone',
                hintText: 'Phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                isPhoneField: false,
                validator: _validatePhone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined),
                prefixIconColor: _prefixIconColor,
                borderRadius: Dimensions.radiusLarge,
                isRequired: true,
              ),
              const SizedBox(height: Dimensions.spaceDefault),
              CommonLabeledInputItemWidget(
                label: 'Address',
                hintText: 'Address (optional)',
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                maxLines: 3,
                minLines: 1,
                prefixIcon: const Icon(Icons.location_on_outlined),
                prefixIconColor: _prefixIconColor,
                borderRadius: Dimensions.radiusLarge,
              ),
              const SizedBox(height: Dimensions.spaceLarge),
              SizedBox(
                height: Dimensions.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge))),
                  child: _saving
                      ? const SizedBox(height: Dimensions.iconSizeDefault, width: Dimensions.iconSizeDefault, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text('Save changes', style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar with a camera badge; shows the picked image, else the saved photo, else a person icon.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoUrl, required this.pickedBytes, required this.onTap});
  final String? photoUrl;
  final Uint8List? pickedBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final image = pickedBytes != null ? MemoryImage(pickedBytes!) as ImageProvider : (photoUrl?.isNotEmpty ?? false) ? NetworkImage(photoUrl!) : null;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
              backgroundImage: image,
              child: image == null ? Icon(Icons.person_rounded, size: 48, color: colors.primaryColor) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colors.primaryColor,
                child: const Icon(Icons.camera_alt_rounded, size: Dimensions.iconSizeSmall, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
