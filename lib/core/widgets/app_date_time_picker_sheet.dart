import 'package:flutter/material.dart';
import 'package:mess_pilot/config/theme/custom_theme_colors.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';

/// Combined date + time picker sheet (calendar card + drum time picker with
/// AM/PM toggle). Presented through [BuildContext.showAdaptiveSheet], so it
/// renders as a bottom sheet on phones and a dialog on tablet/desktop.
class AppDateTimePickerSheet extends StatefulWidget {
  const AppDateTimePickerSheet({super.key, required this.initial, this.minDate, this.maxDate, this.title, this.subtitle, this.timeLabel});

  final DateTime initial;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String? title;
  final String? subtitle;
  final String? timeLabel;

  static Future<DateTime?> show(BuildContext context, {required DateTime initial, DateTime? minDate, DateTime? maxDate, String? title, String? subtitle, String? timeLabel}) {
    return context.showAdaptiveSheet<DateTime>(
      child: AppDateTimePickerSheet(initial: initial, minDate: minDate, maxDate: maxDate, title: title, subtitle: subtitle, timeLabel: timeLabel),
    );
  }

  @override
  State<AppDateTimePickerSheet> createState() => _AppDateTimePickerSheetState();
}

List<DateTime> _calendarDays(DateTime month) {
  final leadingCount = (month.weekday - 1) % 7;
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final days = <DateTime>[];
  for (var i = leadingCount; i > 0; i--) {
    days.add(DateTime(month.year, month.month, 1 - i));
  }
  for (var i = 1; i <= daysInMonth; i++) {
    days.add(DateTime(month.year, month.month, i));
  }
  final trailing = (7 - days.length % 7) % 7;
  for (var i = 1; i <= trailing; i++) {
    days.add(DateTime(month.year, month.month + 1, i));
  }
  return days;
}

class _AppDateTimePickerSheetState extends State<AppDateTimePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late int _hour;
  late int _minute;
  late bool _isPM;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  bool _yearPickerOpen = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _displayedMonth = DateTime(initial.year, initial.month);
    final hour12 = initial.hour % 12;
    _hour = hour12 == 0 ? 12 : hour12;
    _minute = initial.minute;
    _isPM = initial.hour >= 12;
    _hourController = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  bool _isDisabled(DateTime date) {
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && date.isBefore(min)) return true;
    if (max != null && date.isAfter(max)) return true;
    return false;
  }

  int get _firstYear => widget.minDate?.year ?? widget.initial.year - 5;

  int get _lastYear => widget.maxDate?.year ?? widget.initial.year + 5;

  /// Moves the selection into [month], clamping the day and the min/max range
  /// so saving right after a year change never returns a hidden stale date.
  void _onYearSelected(int year) {
    final month = DateTime(year, _displayedMonth.month);
    final day = _selectedDate.day > DateUtils.getDaysInMonth(month.year, month.month) ? DateUtils.getDaysInMonth(month.year, month.month) : _selectedDate.day;
    var date = DateTime(month.year, month.month, day);
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && date.isBefore(min)) date = min;
    if (max != null && date.isAfter(max)) date = max;
    setState(() {
      _displayedMonth = month;
      _selectedDate = date;
      _yearPickerOpen = false;
    });
  }

  void _save() {
    final hour24 = _isPM ? (_hour % 12) + 12 : _hour % 12;
    Navigator.of(context).pop(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour24, _minute));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: widget.title ?? context.local.dateTimePickerTitle, subtitle: widget.subtitle ?? context.local.dateTimePickerSubtitle),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        _CalendarCard(
          month: _displayedMonth,
          selectedDate: _selectedDate,
          isDisabled: _isDisabled,
          yearPickerOpen: _yearPickerOpen,
          firstYear: _firstYear,
          lastYear: _lastYear,
          onToggleYearPicker: () => setState(() => _yearPickerOpen = !_yearPickerOpen),
          onYearSelected: _onYearSelected,
          onPrevMonth: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1)),
          onNextMonth: () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1)),
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _TimePickerCard(
          label: widget.timeLabel,
          hour: _hour,
          minute: _minute,
          isPM: _isPM,
          hourController: _hourController,
          minuteController: _minuteController,
          onHourChanged: (i) => setState(() => _hour = i + 1),
          onMinuteChanged: (i) => setState(() => _minute = i),
          onPeriodChanged: (isPM) => setState(() => _isPM = isPM),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                child: Text(context.local.cancel),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                child: Text(context.local.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor, height: 1.4)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.surfaceColor, shape: BoxShape.circle),
            child: Icon(Icons.close_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
          ),
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.month,
    required this.selectedDate,
    required this.isDisabled,
    required this.yearPickerOpen,
    required this.firstYear,
    required this.lastYear,
    required this.onToggleYearPicker,
    required this.onYearSelected,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final bool Function(DateTime) isDisabled;
  final bool yearPickerOpen;
  final int firstYear;
  final int lastYear;
  final VoidCallback onToggleYearPicker;
  final void Function(int) onYearSelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: yearPickerOpen ? _buildYearPicker(colors) : _buildCalendar(context, colors),
    );
  }

  Widget _buildYearPicker(CustomThemeColors colors) {
    final selectedYear = selectedDate.year;

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onToggleYearPicker,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.arrow_back_ios_rounded, size: 14, color: colors.textHintColor),
              ),
            ),
            Expanded(
              child: Text(
                '$firstYear - $lastYear',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          children: [
            for (var year = lastYear; year >= firstYear; year--)
              GestureDetector(
                onTap: () => onYearSelected(year),
                child: Container(
                  width: 56,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: year == selectedYear ? colors.primaryColor : null,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Text(
                    '$year',
                    style: AppTextStyles.sfProRoundedRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: year == selectedYear ? FontWeight.w600 : FontWeight.w400,
                      color: year == selectedYear ? Colors.white : colors.textPrimaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, CustomThemeColors colors) {
    final localizations = MaterialLocalizations.of(context);
    final days = _calendarDays(month);
    // narrowWeekdays starts with Sunday; the grid starts with Monday.
    final headers = List.generate(7, (i) => localizations.narrowWeekdays[(i + 1) % 7]);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onPrevMonth,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.arrow_back_ios_rounded, size: 14, color: colors.textHintColor),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onToggleYearPicker,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  localizations.formatMonthYear(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor),
                ),
              ),
            ),
            GestureDetector(
              onTap: onNextMonth,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textHintColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Row(
          children: [
            for (final day in headers)
              Expanded(
                child: Center(
                  child: Text(day, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
                ),
              ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        for (int row = 0; row < days.length ~/ 7; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: List.generate(7, (col) {
                final date = days[row * 7 + col];
                final disabled = isDisabled(date);
                final selected = DateUtils.isSameDay(date, selectedDate);

                BoxDecoration? decoration;
                if (selected) {
                  decoration = BoxDecoration(color: colors.primaryColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault));
                } else if (disabled) {
                  decoration = BoxDecoration(color: colors.textHintColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusDefault));
                }

                return Expanded(
                  child: GestureDetector(
                    // An undecorated cell only hit-tests its digits, so taps around the number were lost.
                    behavior: HitTestBehavior.opaque,
                    onTap: disabled ? null : () => onDateSelected(date),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: decoration,
                        child: Text(
                          '${date.day}',
                          style: AppTextStyles.sfProRoundedRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? Colors.white : disabled ? colors.textHintColor : colors.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({
    required this.label,
    required this.hour,
    required this.minute,
    required this.isPM,
    required this.hourController,
    required this.minuteController,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
  });

  final String? label;
  final int hour;
  final int minute;
  final bool isPM;
  final FixedExtentScrollController hourController;
  final FixedExtentScrollController minuteController;
  final void Function(int) onHourChanged;
  final void Function(int) onMinuteChanged;
  final void Function(bool) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Row(
        children: [
          if (label != null)
            Expanded(
              child: Text(label!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor)),
            )
          else
            const Spacer(),
          _DrumPicker(
            controller: hourController,
            itemCount: 12,
            selectedIndex: hour - 1,
            labelBuilder: (i) => (i + 1).toString().padLeft(2, '0'),
            onChanged: onHourChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Text(':', style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
          ),
          _DrumPicker(
            controller: minuteController,
            itemCount: 60,
            selectedIndex: minute,
            labelBuilder: (i) => i.toString().padLeft(2, '0'),
            onChanged: onMinuteChanged,
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          _AmPmToggle(isPM: isPM, onChanged: onPeriodChanged),
        ],
      ),
    );
  }
}

class _DrumPicker extends StatelessWidget {
  const _DrumPicker({required this.controller, required this.itemCount, required this.selectedIndex, required this.labelBuilder, required this.onChanged});

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int) labelBuilder;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return SizedBox(
      width: 40,
      height: 90,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 30,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (_, i) {
            final selected = i == selectedIndex;
            return Center(
              child: Text(
                labelBuilder(i),
                style: (selected ? AppTextStyles.sfProRoundedBold : AppTextStyles.sfProRoundedRegular).copyWith(
                  fontSize: selected ? Dimensions.fontSizeExtraLarge : Dimensions.fontSizeSmall,
                  color: selected ? colors.textPrimaryColor : colors.textHintColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  const _AmPmToggle({required this.isPM, required this.onChanged});

  final bool isPM;
  final void Function(bool) onChanged;

  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const double _segmentWidth = 45;
  static const double _segmentHeight = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final localizations = MaterialLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
      child: SizedBox(
        width: _segmentWidth * 2,
        height: _segmentHeight,
        child: Stack(
          children: [
            // Sliding pill that animates behind the selected segment.
            AnimatedPositioned(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              left: isPM ? _segmentWidth : 0,
              top: 0,
              child: Container(
                width: _segmentWidth,
                height: _segmentHeight,
                decoration: BoxDecoration(color: colors.primaryColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
            ),
            Row(
              children: [
                _PeriodButton(
                  label: localizations.anteMeridiemAbbreviation,
                  isSelected: !isPM,
                  duration: _animationDuration,
                  onTap: () => onChanged(false),
                ),
                _PeriodButton(
                  label: localizations.postMeridiemAbbreviation,
                  isSelected: isPM,
                  duration: _animationDuration,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.label, required this.isSelected, required this.duration, required this.onTap});

  final String label;
  final bool isSelected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _AmPmToggle._segmentWidth,
        height: _AmPmToggle._segmentHeight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOutCubic,
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: isSelected ? Colors.white : colors.textSecondaryColor),
                child: Text(label, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
