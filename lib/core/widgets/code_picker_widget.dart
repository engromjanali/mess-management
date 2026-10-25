import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:collection/collection.dart';

class CodePickerWidget extends StatefulWidget {
  final ValueChanged<CountryCode>? onChanged;
  final ValueChanged<CountryCode>? onInit;
  final String? initialSelection;
  final List<String>? favorite;
  final TextStyle? textStyle;
  final bool? showCountryOnly;
  final InputDecoration? searchDecoration;
  final TextStyle? searchStyle;
  final TextStyle? dialogTextStyle;
  final WidgetBuilder? emptySearchBuilder;
  final Function(CountryCode)? builder;
  final bool? enabled;
  final TextOverflow? textOverflow;
  final Icon? closeIcon;
  final Color? barrierColor;
  final BoxDecoration? boxDecoration;
  final Size? dialogSize;
  final Color? dialogBackgroundColor;
  final List<String>? countryFilter;
  final bool? showOnlyCountryWhenClosed;
  final bool? alignLeft;
  final bool? showFlag;
  final bool? hideMainText;
  final bool? showFlagMain;
  final bool? showFlagDialog;
  final double? flagWidth;
  final Comparator<CountryCode>? comparator;
  final bool? hideSearch;
  final bool? showDropDownButton;
  final Decoration? flagDecoration;
  final List<Map<String, String>>? countryList;
  const CodePickerWidget({
    this.onChanged,
    this.onInit,
    this.initialSelection,
    this.favorite = const [],
    this.textStyle,
    this.showCountryOnly = false,
    this.searchDecoration = const InputDecoration(),
    this.searchStyle,
    this.dialogTextStyle,
    this.emptySearchBuilder,
    this.showOnlyCountryWhenClosed = false,
    this.alignLeft = false,
    this.showFlag = true,
    this.showFlagDialog,
    this.hideMainText = false,
    this.showFlagMain,
    this.flagDecoration,
    this.builder,
    this.flagWidth = 25.0,
    this.enabled = true,
    this.textOverflow = TextOverflow.ellipsis,
    this.barrierColor,
    this.boxDecoration,
    this.comparator,
    this.countryFilter,
    this.hideSearch = false,
    this.showDropDownButton = false,
    this.dialogSize,
    this.dialogBackgroundColor,
    this.closeIcon = const Icon(Icons.close),
    this.countryList = codes,
    super.key,
  });
  @override
  State<CodePickerWidget> createState() => _CodePickerWidgetState();
}

class _CodePickerWidgetState extends State<CodePickerWidget> {
  CountryCode? selectedItem;
  List<CountryCode>? elements = [];
  List<CountryCode>? favoriteElements = [];

  List<CountryCode> getCountryList() {
    List<Map<String, String>> jsonList = widget.countryList != null ? widget.countryList! : [];
    List<CountryCode> elements = jsonList.map((json) => CountryCode.fromJson(json)).toList();
    if (widget.comparator != null) {
      elements.sort(widget.comparator);
    }
    if (widget.countryFilter != null && widget.countryFilter!.isNotEmpty) {
      final uppercaseCustomList = widget.countryFilter!.map((c) => c.toUpperCase()).toList();
      elements = elements.where((c) => uppercaseCustomList.contains(c.code) || uppercaseCustomList.contains(c.name) || uppercaseCustomList.contains(c.dialCode)).toList();
    }
    return elements;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    elements = elements!.map((e) => e.localize(context)).toList();
    _onInit(selectedItem!);
  }

  @override
  void didUpdateWidget(CodePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection != widget.initialSelection) {
      if (widget.initialSelection != null) {
        selectedItem = elements!.firstWhere(
          (e) => (e.code!.toUpperCase() == widget.initialSelection!.toUpperCase()) || (e.dialCode == widget.initialSelection) || (e.name!.toUpperCase() == widget.initialSelection!.toUpperCase()),
          orElse: () => elements![0],
        );
      } else {
        selectedItem = elements![0];
      }
      _onInit(selectedItem!);
    }
  }

  @override
  void initState() {
    super.initState();
    elements = getCountryList();
    if (widget.countryList != null && widget.countryList!.isNotEmpty) {
      if (widget.initialSelection != null) {
        selectedItem = elements!.firstWhere(
          (e) => (e.code!.toUpperCase() == widget.initialSelection!.toUpperCase()) || (e.dialCode == widget.initialSelection) || (e.name!.toUpperCase() == widget.initialSelection!.toUpperCase()),
          orElse: () => elements![0],
        );
      } else {
        selectedItem = elements![0];
      }
      favoriteElements = elements!
          .where((e) => widget.favorite!.firstWhereOrNull((f) => e.code!.toUpperCase() == f.toUpperCase() || e.dialCode == f || e.name!.toUpperCase() == f.toUpperCase()) != null)
          .toList();
    }
  }

  bool get _isMobile => !kIsWeb && (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS);

  void showCountryCodePickerDialog() {
    if (!_isMobile) {
      showDialog(
        barrierColor: widget.barrierColor ?? Colors.grey.withValues(alpha: 0.5),
        context: context,
        builder: (context) => Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
            child: Dialog(
              child: SelectionDialog(
                elements!,
                favoriteElements!,
                showCountryOnly: widget.showCountryOnly,
                emptySearchBuilder: widget.emptySearchBuilder,
                searchDecoration: widget.searchDecoration!,
                searchStyle: widget.searchStyle,
                textStyle: widget.dialogTextStyle,
                boxDecoration: widget.boxDecoration,
                showFlag: widget.showFlagDialog ?? widget.showFlag,
                flagWidth: widget.flagWidth!,
                size: widget.dialogSize,
                backgroundColor: widget.dialogBackgroundColor,
                barrierColor: widget.barrierColor,
                hideSearch: widget.hideSearch!,
                closeIcon: widget.closeIcon,
                flagDecoration: widget.flagDecoration,
                hideHeaderText: true,
                hideCloseIcon: false,
                headerAlignment: MainAxisAlignment.end,
                headerTextStyle: AppTextStyles.sfProRoundedRegular,
                topBarPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ).then((e) {
        if (e != null) {
          setState(() {
            selectedItem = e;
          });
          _publishSelection(e);
        }
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: Theme(
              data: context.theme.copyWith(dividerTheme: DividerThemeData(color: context.theme.dividerColor)),
              child: SelectionDialog(
                elements!,
                favoriteElements!,
                showCountryOnly: widget.showCountryOnly,
                emptySearchBuilder: widget.emptySearchBuilder,
                searchDecoration: widget.searchDecoration!,
                searchStyle: widget.searchStyle,
                textStyle: widget.dialogTextStyle,
                boxDecoration: widget.boxDecoration,
                showFlag: widget.showFlagDialog ?? widget.showFlag,
                flagWidth: widget.flagWidth!,
                flagDecoration: widget.flagDecoration,
                size: widget.dialogSize,
                backgroundColor: widget.dialogBackgroundColor,
                barrierColor: widget.barrierColor,
                hideSearch: widget.hideSearch!,
                closeIcon: widget.closeIcon,
                hideHeaderText: true,
                hideCloseIcon: false,
                headerAlignment: MainAxisAlignment.end,
                headerTextStyle: AppTextStyles.sfProRoundedRegular,
                topBarPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ).then((e) {
        if (e != null) {
          setState(() {
            selectedItem = e;
          });
          _publishSelection(e);
        }
      });
    }
  }

  void _publishSelection(CountryCode e) {
    if (widget.onChanged != null) {
      widget.onChanged!(e);
    }
  }

  void _onInit(CountryCode e) {
    if (widget.onInit != null) {
      widget.onInit!(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.builder != null) {
      child = InkWell(onTap: showCountryCodePickerDialog, child: widget.builder!(selectedItem!));
    } else {
      child = InkWell(
        onTap: widget.enabled! ? showCountryCodePickerDialog : null,
        child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.showFlagMain != null ? widget.showFlagMain! : widget.showFlag!)
              Flexible(
                flex: 0,
                fit: widget.alignLeft! ? FlexFit.tight : FlexFit.loose,
                child: Container(
                  clipBehavior: widget.flagDecoration == null ? Clip.none : Clip.hardEdge,
                  decoration: widget.flagDecoration,
                  margin: widget.alignLeft! ? const EdgeInsets.only(right: 7.0, left: 0) : const EdgeInsets.only(right: 7.0, left: 0),
                  child: Image.asset(selectedItem!.flagUri!, package: 'country_code_picker', width: widget.flagWidth),
                ),
              ),
            if (!widget.hideMainText!)
              Flexible(
                fit: widget.alignLeft! ? FlexFit.tight : FlexFit.loose,
                child: Text(
                  widget.showOnlyCountryWhenClosed! ? selectedItem!.toCountryStringOnly() : selectedItem.toString(),
                  style: widget.textStyle ?? Theme.of(context).textTheme.labelLarge,
                  overflow: widget.textOverflow,
                ),
              ),
            if (widget.showDropDownButton!) const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 35),
          ],
        ),
      );
    }
    return child;
  }
}
