part of 'core_collection.dart';

/// Number and datetime formatting helpers for CoreCollection
extension _CoreCollectionFormattersExt on _CoreCollectionState {
  /// Format datetime value for display in collection summary
  String _formatDateTimeValue(
    String value,
    String? datetimeType,
    String? displayFormat,
  ) {
    return Functions().formatDateTimeValue(value, datetimeType, displayFormat);
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
    return Functions().parseColor(color);
  }

  /// Get value from nested map using dot notation
  dynamic _getByPath(Map<String, dynamic> map, String path) {
    return Functions().getByPath(map, path);
  }

  /// Evaluate visibility conditions based on context
  bool _evaluateVisibility(dynamic visibleWhen, Map<String, dynamic> context) {
    return Functions().evaluateVisibility(visibleWhen, context);
  }
}
