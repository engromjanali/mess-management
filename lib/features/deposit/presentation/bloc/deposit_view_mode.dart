/// How the deposit list is currently filtered.
enum DepositViewMode {
  /// Admin: deposits for one selected member (or all members).
  byMember,

  /// Admin: every member's deposits, scoped by a date filter.
  byDate,

  /// User: the signed-in user's own deposits only.
  mine,
}

/// The date scope used when browsing [DepositViewMode.byDate].
enum DepositDateFilter {
  /// No date constraint — every deposit.
  allTime,

  /// A single calendar day.
  day,

  /// A custom inclusive date range.
  range;

  String get label => switch (this) {
    DepositDateFilter.allTime => 'All time',
    DepositDateFilter.day => 'Day',
    DepositDateFilter.range => 'Range',
  };
}
