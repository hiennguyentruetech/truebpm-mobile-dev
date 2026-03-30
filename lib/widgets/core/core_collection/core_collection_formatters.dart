part of 'core_collection.dart';

/// Number and datetime formatting helpers for CoreCollection
extension _CoreCollectionFormattersExt on _CoreCollectionState {
  /// Format datetime value for display in collection summary
  String _formatDateTimeValue(
    String value,
    String? datetimeType,
    String? displayFormat,
  ) {
    try {
      DateTime? dateTime;

      // Try to parse the datetime string and force UTC handling
      if (value.contains('T')) {
        // ISO format: 2023-12-25T10:30:00.000Z
        dateTime = DateTime.tryParse(value);
        if (dateTime != null) {
          // If it's not already UTC, treat it as UTC to avoid timezone conversion
          if (!dateTime.isUtc) {
            dateTime = DateTime.utc(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
              dateTime.millisecond,
            );
          }
        }
      } else if (value.contains('/')) {
        // Format: 25/12/2023 or 25/12/2023 10:30
        final parts = value.split(' ');
        final datePart = parts[0];
        final timePart = parts.length > 1 ? parts[1] : null;

        final dateComponents = datePart.split('/');
        if (dateComponents.length == 3) {
          final day = int.tryParse(dateComponents[0]);
          final month = int.tryParse(dateComponents[1]);
          final year = int.tryParse(dateComponents[2]);

          if (day != null && month != null && year != null) {
            if (timePart != null) {
              final timeComponents = timePart.split(':');
              final hour = int.tryParse(timeComponents[0]) ?? 0;
              final minute = timeComponents.length > 1
                  ? (int.tryParse(timeComponents[1]) ?? 0)
                  : 0;
              // Create as UTC to avoid timezone issues
              dateTime = DateTime.utc(year, month, day, hour, minute);
            } else {
              // Create as UTC to avoid timezone issues
              dateTime = DateTime.utc(year, month, day);
            }
          }
        }
      } else {
        // Try direct parsing and force UTC
        dateTime = DateTime.tryParse(value);
        if (dateTime != null && !dateTime.isUtc) {
          dateTime = DateTime.utc(
            dateTime.year,
            dateTime.month,
            dateTime.day,
            dateTime.hour,
            dateTime.minute,
            dateTime.second,
            dateTime.millisecond,
          );
        }
      }

      if (dateTime == null) return value; // Return original if parsing fails

      // Format based on datetime type - always display as intended UTC time
      switch (datetimeType) {
        case 'time':
          return DateFormat('HH:mm').format(dateTime.toUtc());
        case 'date':
          return displayFormat != null && displayFormat == 'ddMMyyyy'
              ? DateFormat('dd/MM/yyyy').format(dateTime.toUtc())
              : DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        case 'datetime':
          return displayFormat != null && displayFormat == 'ddMMyyyy'
              ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc())
              : DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
        case 'daterange':
          // For daterange, this would be handled differently
          return DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        default:
          // Default datetime format - display UTC time
          return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
      }
    } catch (e) {
      // If any error occurs, return original value
      return value;
    }
  }

  /// Format number for display (EU style: thousand '.' and decimal ',')
  String _formatNumberDisplay(dynamic value, {int decimalPlaces = -1}) {
    if (value == null) return '';
    String s = value is num ? value.toString() : value.toString().trim();
    if (s.isEmpty) return '';

    String intRaw = '';
    String decRaw = '';

    if (s.contains(',')) {
      // EU-style input: remove thousand dots, comma is decimal
      final cleaned = s.replaceAll('.', '');
      final idx = cleaned.indexOf(',');
      intRaw = (idx >= 0 ? cleaned.substring(0, idx) : cleaned);
      decRaw = (idx >= 0 ? cleaned.substring(idx + 1) : '');
    } else if (s.contains('.') &&
        !s.contains(',') &&
        s.split('.').length == 2) {
      // Treat single dot as decimal separator (common machine format like 342432.0)
      final parts = s.split('.');
      intRaw = parts[0];
      decRaw = parts[1];
    } else {
      // Pure integer or treat dots as thousand separators
      intRaw = s.replaceAll('.', '');
      decRaw = '';
    }

    // Keep digits only
    intRaw = intRaw.replaceAll(RegExp(r'[^0-9]'), '');
    decRaw = decRaw.replaceAll(RegExp(r'[^0-9]'), '');

    if (intRaw.isEmpty) return '';

    // Handle decimal places
    if (decimalPlaces >= 0) {
      if (decimalPlaces == 0 && decRaw.isNotEmpty) {
        // Round based on first decimal digit then drop decimals
        final first = int.tryParse(decRaw[0]) ?? 0;
        if (first >= 5) {
          final intVal = int.parse(intRaw) + 1;
          intRaw = intVal.toString();
        }
        decRaw = '';
      } else if (decimalPlaces > 0) {
        if (decRaw.length > decimalPlaces) {
          decRaw = decRaw.substring(0, decimalPlaces);
        } else if (decRaw.length < decimalPlaces) {
          decRaw = decRaw.padRight(decimalPlaces, '0');
        }
      }
    }

    final grouped = _groupThousands(intRaw);

    if (decimalPlaces > 0 || (decimalPlaces == -1 && decRaw.isNotEmpty)) {
      return '$grouped,$decRaw';
    }
    return grouped;
  }

  /// Group digits with thousand separators using EU format (dot)
  String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Parse color from dynamic value (Color, int, or hex string)
  Color? _parseColor(dynamic color) {
    if (color == null) return null;
    if (color is Color) return color;
    if (color is int) return Color(color);
    if (color is String) {
      String hex = color.trim();
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) return Color(intVal);
    }
    return null;
  }

  /// Get value from nested map using dot notation
  dynamic _getByPath(Map<String, dynamic> map, String path) {
    dynamic curr = map;
    for (final segment in path.split('.')) {
      if (segment == 'length' && curr is List) {
        return curr.length;
      }
      if (curr is Map && curr.containsKey(segment)) {
        curr = curr[segment];
      } else {
        return null;
      }
    }
    return curr;
  }

  /// Evaluate visibility conditions based on context
  bool _evaluateVisibility(dynamic visibleWhen, Map<String, dynamic> context) {
    final List conditions = visibleWhen is List ? visibleWhen : [visibleWhen];
    for (final cond in conditions) {
      if (cond is! Map) continue;
      final String key = cond['key']?.toString() ?? '';
      final String op = (cond['operator'] ?? cond['op'] ?? 'eq').toString();
      final dynamic expected = cond['value'];
      final dynamic actual = _getByPath(context, key);
      switch (op) {
        case 'eq':
          if (actual != expected) return false;
          break;
        case 'ne':
          if (actual == expected) return false;
          break;
        case 'in':
          if (expected is List) {
            if (!expected.contains(actual)) return false;
          } else {
            return false;
          }
          break;
        case 'notEmpty':
          if (actual == null || (actual is String && actual.trim().isEmpty))
            return false;
          break;
        case 'empty':
          if (!(actual == null || (actual is String && actual.trim().isEmpty)))
            return false;
          break;
        case 'exists':
          if (actual == null) return false;
          break;
        case 'notExists':
          if (actual != null) return false;
          break;
        default:
          break;
      }
    }
    return true;
  }
}
