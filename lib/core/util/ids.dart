import 'dart:math';

/// Identifiers for rows the user creates.
///
/// A timestamp prefix keeps ids roughly sortable by creation, which makes a
/// corrupted `position` column recoverable, and the random suffix keeps two
/// rows made in the same millisecond apart. No package needed for this.
final Random _random = Random();

String newId() {
  final int now = DateTime.now().microsecondsSinceEpoch;
  final int salt = _random.nextInt(1 << 20);
  return '${now.toRadixString(36)}${salt.toRadixString(36).padLeft(4, '0')}';
}
