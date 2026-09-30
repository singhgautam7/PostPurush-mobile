/// Every number and date the interface prints comes through here, so two
/// screens can never disagree about what "1,391 ms" or "2 min ago" looks like.
abstract final class Fmt {
  /// `1391` becomes `1,391`.
  static String thousands(num value) {
    final String digits = value.abs().truncate().toString();
    final String grouped = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (Match m) => '${m[1]},',
    );
    return value < 0 ? '-$grouped' : grouped;
  }

  /// `1391` becomes `1,391 ms`; anything past ten seconds becomes `12.4 s`,
  /// because milliseconds stop being readable there.
  static String duration(int ms) =>
      ms >= 10000 ? '${(ms / 1000).toStringAsFixed(1)} s' : '${thousands(ms)} ms';

  /// The dock's counter while a request is in flight: `0.84 s`.
  static String elapsed(int ms) => '${(ms / 1000).toStringAsFixed(2)} s';

  /// `79 B`, `5.6 KB`, `2.1 MB`.
  static String bytes(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// `94.2%`, one decimal, which is what the analytics cards show.
  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(1)}%';

  /// `2 min ago`, `1 h ago`, `18:42`, `29 Sep`. Today's times stay absolute
  /// past six hours, because "7 h ago" is harder to place than "14:07".
  static String relative(DateTime when, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration gap = reference.difference(when);
    if (gap.inSeconds < 45) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes} min ago';
    if (gap.inHours < 6) return '${gap.inHours} h ago';
    if (_sameDay(when, reference)) return clock(when);
    if (gap.inDays < 7) return '${_weekday(when)} ${clock(when)}';
    return '${when.day} ${_month(when)}';
  }

  /// `14:07`, twenty-four hour, because that is what the board prints.
  static String clock(DateTime when) =>
      '${when.hour.toString().padLeft(2, '0')}:'
      '${when.minute.toString().padLeft(2, '0')}';

  /// The history list's day headers.
  static String dayLabel(DateTime when, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    if (_sameDay(when, reference)) return 'Today';
    if (_sameDay(when, reference.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    if (reference.difference(when).inDays < 7) return _weekdayLong(when);
    return '${when.day} ${_month(when)}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdaysLong = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _weekday(DateTime when) => _weekdays[when.weekday - 1];
  static String _weekdayLong(DateTime when) => _weekdaysLong[when.weekday - 1];
  static String _month(DateTime when) => _months[when.month - 1];

  /// `Mon`..`Sun`, for the response-time chart's axis.
  static String weekdayShort(DateTime when) => _weekday(when);

  /// `1,284` requests, `48.1` req/s: one decimal only when it is small enough
  /// for the decimal to matter.
  static String rate(double value) =>
      value >= 100 ? thousands(value.round()) : value.toStringAsFixed(1);

  /// "3 open · 1 unsaved", "5 requests", "1 variable". One place for the
  /// singular, because getting it wrong is the kind of thing that reads as
  /// sloppiness everywhere else.
  static String count(int n, String singular, [String? plural]) =>
      '$n ${n == 1 ? singular : plural ?? '${singular}s'}';
}
