import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_formatters.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations local;

  setUpAll(() async {
    local = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('PollFormatters', () {
    test('formats short and deadline dates', () {
      final date = DateTime(2026, 11, 20);

      expect(PollFormatters.day(date), 'Fri, 20 Nov 2026');
      expect(PollFormatters.deadline(DateTime(2026, 11, 20, 23, 59)), '20 Nov 2026 · 11:59 PM');
    });

    test('uses relative labels for today and tomorrow', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final later = today.add(const Duration(days: 5));

      expect(PollFormatters.relativeDay(local, today), local.pollToday);
      expect(PollFormatters.relativeDay(local, tomorrow), local.pollTomorrow);
      expect(PollFormatters.relativeDay(local, later), PollFormatters.day(later));
    });

    test('formats participation and vote counts', () {
      expect(PollFormatters.participation(local, 5, 8), '5 of 8 members voted');
      expect(local.pollVotesCount(1), '1 vote');
      expect(local.pollVotesCount(3), '3 votes');
    });
  });
}
