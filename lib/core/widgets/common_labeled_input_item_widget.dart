import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/common_extensions.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/code_picker_widget.dart';
import 'package:clean_boilerplate/core/widgets/input_suffix_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class CommonLabeledInputItemWidget extends StatefulWidget {
  final String? label;
  final Widget? labelSuffixWidget;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final String? countryDialCode;
  final ValueChanged<CountryCode>? onCountryChanged;
  final bool showLabel;
  final int? maxLines;
  final int? minLines;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final bool? readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String?>? onErrorChanged;
  final int? passwordLength;
  final FocusNode? focusNode;
  final VoidCallback? onUnfocus;
  final double? hintOpacity;
  final Color? prefixIconColor;
  final double? prefixIconSize;
  final Color? suffixIconColor;
  final double? suffixIconSize;
  final Color? fillColor;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const CommonLabeledInputItemWidget({
    required this.hintText,
    required this.controller,
    super.key,
    this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.countryDialCode,
    this.onCountryChanged,
    this.labelSuffixWidget,
    this.showLabel = true,
    this.maxLines,
    this.contentPadding,
    this.minLines,
    this.borderRadius,
    this.readOnly,
    this.onChanged,
    this.onErrorChanged,
    this.passwordLength,
    this.onUnfocus,
    this.focusNode,
    this.hintOpacity,
    this.prefixIconColor,
    this.prefixIconSize,
    this.suffixIconColor,
    this.suffixIconSize,
    this.fillColor,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<CommonLabeledInputItemWidget> createState() => _CommonLabeledInputItemWidgetState();
}

class _CommonLabeledInputItemWidgetState extends State<CommonLabeledInputItemWidget> {
  bool _obscurePassword = true;
  String? _errorText;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;

  bool get _isPasswordField => widget.keyboardType == TextInputType.visiblePassword || (widget.label ?? "").toLowerCase().contains('password') || widget.hintText.toLowerCase().contains('password');

  @override
  void initState() {
    super.initState();
    _initFocusNode();
    widget.controller.addListener(_validateInput);
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _isInternalFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onUnfocus?.call();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    String? newErrorText;
    if (widget.validator != null) {
      newErrorText = widget.validator!(widget.controller.text);
    } else {
      newErrorText = _getBasicValidationError(widget.controller.text);
    }

    setState(() {
      _errorText = newErrorText;
      if (_autovalidateMode == AutovalidateMode.disabled) {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      }
    });

    if (widget.onErrorChanged != null) {
      widget.onErrorChanged!(_errorText);
    }
  }

  String? _getBasicValidationError(String value) {
    if (widget.isRequired && value.trim().isEmpty) {
      return '${widget.label} ${context.local.validation_is_required}';
    }

    if (widget.keyboardType == TextInputType.emailAddress) {
      if (value.isNotEmpty && !(value.isValidEmail)) {
        return context.local.validation_invalid_email;
      }
    }

    if (_isPasswordField && value.isNotEmpty) {
      if (value.length < (widget.passwordLength ?? 6)) {
        return context.local.validation_password_min_length;
      }
    }

    if (widget.keyboardType == TextInputType.phone) {
      if ((value.isNotEmpty && value.length < 10) || int.tryParse(widget.controller.text) == null) {
        return context.local.validation_invalid_phone;
      }
    }

    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);
    _validateInput();
  }

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(widget.label ?? '', style: AppTextStyles.sfProRoundedMedium),
                  if (widget.isRequired) Text(' *', style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: widget.enabled ? Theme.of(context).colorScheme.error : disabledColor)),
                ],
              ),
              widget.labelSuffixWidget ?? const SizedBox(),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
        TextFormField(
          onChanged: _onTextChanged,
          controller: widget.controller,
          focusNode: _focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          keyboardType: widget.keyboardType,
          obscureText: _isPasswordField ? _obscurePassword : false,
          enabled: widget.enabled,
          style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
          maxLines: _isPasswordField ? 1 : widget.maxLines,
          minLines: _isPasswordField ? 1 : widget.minLines,
          readOnly: widget.readOnly ?? false,
          autovalidateMode: _autovalidateMode,
          onTapOutside: (_) {
            if (widget.keyboardType == TextInputType.phone) {
              final num = int.tryParse(widget.controller.text);
              widget.controller.text = num?.toString() ?? widget.controller.text;
            }
          },
          validator: (value) {
            if (widget.validator != null) {
              return widget.validator!(value);
            }
            return _getBasicValidationError(value ?? '');
          },
          decoration: InputDecoration(
            hintText: widget.hintText,

            filled: true,
            fillColor: widget.fillColor ?? (widget.enabled ? Theme.of(context).cardColor : Colors.grey.withValues(alpha: 0.1)),
            // contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
            //   vertical: Dimensions.paddingSizeExtraSmall,
            //   horizontal: Dimensions.paddingSizeDefault,
            // ),
            contentPadding: widget.contentPadding ?? EdgeInsets.zero,
            prefix: Padding(padding: EdgeInsets.only(left: widget.keyboardType == TextInputType.phone ? 0 : Dimensions.paddingSizeDefault)),
            prefixIcon: widget.keyboardType == TextInputType.phone
                ? Padding(
                    padding: EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                    child: CodePickerWidget(
                      onChanged: widget.onCountryChanged,
                      initialSelection: widget.countryDialCode,
                      favorite: widget.countryDialCode != null ? [widget.countryDialCode!] : const [],
                      showDropDownButton: true,
                      showFlagMain: true,
                      dialogBackgroundColor: context.theme.scaffoldBackgroundColor,
                    ),
                  )
                : widget.prefixIcon != null
                ? IconTheme(
                    data: IconThemeData(color: widget.prefixIconColor ?? Theme.of(context).primaryColor, size: widget.prefixIconSize ?? 24),
                    child: widget.prefixIcon!,
                  )
                : null,
            suffixIcon: _isPasswordField
                ? InputSuffixIconWidget(
                    isPasswordField: _isPasswordField,
                    obscurePassword: _obscurePassword,
                    enabled: widget.enabled,
                    customSuffixIcon: widget.suffixIcon != null
                        ? IconTheme(
                            data: IconThemeData(color: widget.suffixIconColor ?? Theme.of(context).primaryColor, size: widget.suffixIconSize ?? 24),
                            child: widget.suffixIcon!,
                          )
                        : null,
                    onTogglePasswordVisibility: _togglePasswordVisibility,
                  )
                : widget.suffixIcon != null
                ? IconTheme(
                    data: IconThemeData(color: widget.suffixIconColor ?? Theme.of(context).primaryColor, size: widget.suffixIconSize ?? 24),
                    child: widget.suffixIcon!,
                  )
                : null,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall),
              borderSide: BorderSide(color: context.customThemeColors.borderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall),
              borderSide: BorderSide(color: disabledColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? Dimensions.radiusSmall),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
            ),
            hintStyle: AppTextStyles.sfProRoundedRegular.copyWith(
              color: widget.enabled ? Theme.of(context).textTheme.titleLarge!.color!.withValues(alpha: widget.hintOpacity ?? 0.7) : disabledColor.withValues(alpha: widget.hintOpacity ?? 0.5),
            ),
            errorStyle: AppTextStyles.sfProRoundedRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: widget.borderRadius ?? Dimensions.fontSizeSmall),
          ),
        ),
      ],
    );
  }
}
