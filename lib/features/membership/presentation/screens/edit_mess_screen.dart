import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/code_picker_widget.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class EditMessScreen extends StatefulWidget {
  const EditMessScreen({super.key});

  @override
  State<EditMessScreen> createState() => _EditMessScreenState();
}

class _EditMessScreenState extends State<EditMessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final MembershipApiService _service;
  bool _loading = true;
  bool _saving = false;
  String _dialCode = '+880';
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _service = MembershipApiService(getIt<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final mess = await _service.getMessDetails();
      if (!mounted) return;
      _nameController.text = mess.name;
      _addressController.text = mess.address;
      _emailController.text = mess.email;
      _setPhone(mess.phone);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(_errorMessage(error, context.local.messDetailsLoadFailed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() {
      _saving = true;
      _fieldErrors = const {};
    });
    try {
      final phone = _phoneController.text.trim();
      await _service.updateMess(name: _nameController.text.trim(), address: _addressController.text.trim(), email: _emailController.text.trim(), phone: phone.isEmpty ? '' : '$_dialCode$phone');
      if (!mounted) return;
      context.showSuccessSnackBar(context.local.messDetailsUpdated);
      Navigator.of(context).pop();
    } on ServerException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.statusCode == 400 || error.statusCode == 422 ? {for (final key in ['name', 'address', 'email', 'phone']) if (error.fieldErrors.containsKey(key)) key: error.fieldErrors[key]!} : const {});
      context.showErrorSnackBar(_fieldErrors.isEmpty ? _errorMessage(error, context.local.messDetailsSaveFailed) : context.local.messDetailsCheckFields);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(_errorMessage(error, context.local.messDetailsSaveFailed));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is NoInternetException || error is NetworkException) return context.local.messDetailsConnectionFailed;
    if (error is RequestTimeoutException) return context.local.messDetailsRequestTimedOut;
    if (error is UnauthorizedException || error is ServerException && error.statusCode == 401) return context.local.messDetailsSignInAgain;
    if (error is ServerException && error.statusCode == 403) return context.local.messDetailsPermissionDenied;
    return fallback;
  }

  void _setPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[\s()-]'), '');
    if (!normalized.startsWith('+')) {
      _phoneController.text = normalized.replaceFirst(RegExp(r'^0+'), '');
      return;
    }
    final dialCodes = codes.map((country) => country['dial_code'] ?? '').where((code) => code.isNotEmpty).toSet().toList()..sort((a, b) => b.length.compareTo(a.length));
    _dialCode = dialCodes.firstWhere((code) => normalized.startsWith(code), orElse: () => '+880');
    _phoneController.text = normalized.substring(_dialCode.length).replaceFirst(RegExp(r'^0+'), '');
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return context.local.messNameRequired;
    if (name.length > 100) return context.local.messNameTooLong;
    return null;
  }

  String? _validateAddress(String? value) => (value ?? '').trim().length > 255 ? context.local.messAddressTooLong : null;

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    return EmailValidator.validate(email) ? null : context.local.validation_invalid_email;
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return null;
    try {
      final parsed = PhoneNumber.parse('$_dialCode$phone');
      return parsed.isValid(type: PhoneNumberType.mobile) || parsed.isValid(type: PhoneNumberType.fixedLine) ? null : context.local.validation_invalid_phone;
    } catch (_) {
      return context.local.validation_invalid_phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.editMessDetails)),
      body: MainPageBody(
        title: context.local.editMessDetails,
        child: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(controller: _nameController, decoration: InputDecoration(labelText: context.local.messName, errorMaxLines: 3), forceErrorText: _fieldErrors['name'], onChanged: (_) => _clearFieldError('name'), validator: _validateName, maxLength: 100, textInputAction: TextInputAction.next),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(controller: _addressController, decoration: InputDecoration(labelText: context.local.addressOptional, errorMaxLines: 3), forceErrorText: _fieldErrors['address'], onChanged: (_) => _clearFieldError('address'), validator: _validateAddress, maxLength: 255, maxLines: 3),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(controller: _emailController, decoration: InputDecoration(labelText: context.local.messEmailOptional, errorMaxLines: 3), forceErrorText: _fieldErrors['email'], onChanged: (_) => _clearFieldError('email'), validator: _validateEmail, keyboardType: TextInputType.emailAddress, maxLength: 254, textInputAction: TextInputAction.next, autocorrect: false),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: context.local.messPhoneOptional,
                              errorMaxLines: 3,
                              prefixIcon: Padding(
                                padding: const EdgeInsetsDirectional.only(start: Dimensions.paddingSizeSmall),
                                child: CodePickerWidget(
                                  initialSelection: _dialCode,
                                  favorite: [_dialCode],
                                  showDropDownButton: true,
                                  showFlagMain: true,
                                  flagWidth: 22,
                                  onChanged: (country) {
                                    setState(() => _dialCode = country.dialCode ?? _dialCode);
                                    _formKey.currentState?.validate();
                                  },
                                  dialogBackgroundColor: context.theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ),
                            forceErrorText: _fieldErrors['phone'],
                            onChanged: (_) => _clearFieldError('phone'),
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                            onFieldSubmitted: (_) => _save(),
                          ),
                          const SizedBox(height: Dimensions.spaceLarge),
                          FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: Dimensions.iconSizeSmall, height: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(context.local.saveChanges)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
  }
}
