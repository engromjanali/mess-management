import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// ❓🧹 isNull
/// Checks if a given `value` is considered "null-like".
/// ⚠️ Useful when API responses or user inputs return various falsy values.

/// it's will not work proparly because of, few thing check/metch with object/pointer
// List _nulls = [null, '', 'null', 0, {}, [], File(''), XFile(''), '[]'];
// bool isNull(dynamic value) {
//   return _nulls.contains(value);
// }

bool isNull(dynamic value) {
  if (value == null) return true;

  // String cases
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v.isEmpty || v == 'null' || v == '[]' || v == '{}';
  }

  // Number cases
  if (value is num) return value == 0;

  // File & XFile cases
  if (value is File) return value.path.isEmpty;
  if (value is XFile) return value.path.isEmpty;

  // List & Map cases
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;

  return false;
}

bool isNotNull(dynamic value) {
  return !isNull(value);
}
