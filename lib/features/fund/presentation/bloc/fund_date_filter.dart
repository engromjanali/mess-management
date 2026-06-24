/// The date scope used when browsing fund entries.
///
/// Funds have no member dimension, so the date is the only filter axis.
enum FundDateFilter {
  /// No date constraint — every fund entry.
  allTime,

  /// A single calendar day.
  day,

  /// A custom inclusive date range.
  range;

  String get label => switch (this) {
        FundDateFilter.allTime => 'All time',
        FundDateFilter.day => 'Day',
        FundDateFilter.range => 'Range',
      };
}
