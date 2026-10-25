import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:flutter/material.dart';

/// Asks the manager which running season a new member joins and returns its
/// id (`null` when dismissed). [initialSeasonId] is preselected when it can be
/// chosen; seasons in [joinedSeasonIds] are listed but can't be chosen.
Future<String?> showSeasonPickerDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required List<SeasonEntity> seasons,
  String? initialSeasonId,
  Set<String> joinedSeasonIds = const {},
}) => showDialog<String>(
  context: context,
  builder: (_) => SeasonPickerDialog(title: title, message: message, confirmLabel: confirmLabel, seasons: seasons, initialSeasonId: initialSeasonId, joinedSeasonIds: joinedSeasonIds),
);

class SeasonPickerDialog extends StatefulWidget {
  const SeasonPickerDialog({required this.title, required this.message, required this.confirmLabel, required this.seasons, this.initialSeasonId, this.joinedSeasonIds = const {}, super.key});

  final String title;
  final String message;
  final String confirmLabel;

  /// The running seasons, in display order.
  final List<SeasonEntity> seasons;
  final String? initialSeasonId;
  final Set<String> joinedSeasonIds;

  @override
  State<SeasonPickerDialog> createState() => _SeasonPickerDialogState();
}

class _SeasonPickerDialogState extends State<SeasonPickerDialog> {
  late String? _selectedId = _initialId();

  @override
  Widget build(BuildContext context) {
    final local = context.local;
    final colors = context.customThemeColors;
    final hint = widget.seasons.isEmpty
        ? local.noRunningSeason
        : _selectedId == null
        ? local.inAllRunningSeasons
        : null;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (widget.seasons.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedId,
              isExpanded: true,
              decoration: InputDecoration(labelText: local.seasonFieldLabel, prefixIcon: const Icon(Icons.event_note_rounded)),
              items: [
                for (final season in widget.seasons)
                  DropdownMenuItem(
                    value: season.id,
                    enabled: !widget.joinedSeasonIds.contains(season.id),
                    child: Text(
                      widget.joinedSeasonIds.contains(season.id) ? local.alreadyInSeason(season.name) : season.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.joinedSeasonIds.contains(season.id) ? TextStyle(color: colors.textHintColor) : null,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedId = value),
            ),
          if (hint != null) ...[
            if (widget.seasons.isNotEmpty) const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(hint, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.errorColor)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(local.cancel)),
        FilledButton(onPressed: _selectedId == null ? null : () => Navigator.of(context).pop(_selectedId), child: Text(widget.confirmLabel)),
      ],
    );
  }

  /// [SeasonPickerDialog.initialSeasonId] if it can be chosen, else the first season that can.
  String? _initialId() {
    final selectable = widget.seasons.where((season) => !widget.joinedSeasonIds.contains(season.id));
    return selectable.any((season) => season.id == widget.initialSeasonId) ? widget.initialSeasonId : selectable.firstOrNull?.id;
  }
}
