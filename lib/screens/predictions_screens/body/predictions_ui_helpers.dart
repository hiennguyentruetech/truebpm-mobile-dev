import 'package:intl/intl.dart';

final NumberFormat predictionMoneyFormat = NumberFormat('#,##0', 'vi_VN');
final NumberFormat predictionPercentFormat = NumberFormat('#,##0.#', 'vi_VN');

Map<String, dynamic> predictionMap(dynamic value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> predictionList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

num predictionNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    final isNegative = cleaned.startsWith('-');
    final unsigned = cleaned.replaceAll('-', '');
    final normalizedUnsigned = _normalizePredictionNumber(unsigned);
    final normalized = isNegative ? '-$normalizedUnsigned' : normalizedUnsigned;
    return num.tryParse(normalized) ?? fallback;
  }
  return fallback;
}

String _normalizePredictionNumber(String value) {
  if (value.isEmpty) return value;

  final hasComma = value.contains(',');
  final hasDot = value.contains('.');
  if (hasComma && hasDot) {
    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');
    if (lastComma > lastDot) {
      return value.replaceAll('.', '').replaceAll(',', '.');
    }
    return value.replaceAll(',', '');
  }

  if (hasDot) {
    return _isGroupedThousands(value, '.') ? value.replaceAll('.', '') : value;
  }

  if (hasComma) {
    return _isGroupedThousands(value, ',')
        ? value.replaceAll(',', '')
        : value.replaceAll(',', '.');
  }

  return value;
}

bool _isGroupedThousands(String value, String separator) {
  final parts = value.split(separator);
  if (parts.length <= 1 || parts.first.isEmpty || parts.first.length > 3) {
    return false;
  }
  return parts.skip(1).every((part) => part.length == 3);
}

int predictionInt(dynamic value, {int fallback = 0}) {
  return predictionNum(value, fallback: fallback).round();
}

String predictionMoney(dynamic value, {bool signed = false}) {
  final amount = predictionNum(value);
  final prefix = signed && amount > 0 ? '+' : '';
  return '$prefix${predictionMoneyFormat.format(amount)}';
}

String predictionShortMoney(dynamic value, {bool signed = false}) {
  final amount = predictionNum(value);
  final prefix = signed && amount > 0 ? '+' : '';
  return '$prefix${predictionMoneyFormat.format(amount)}';
}

String predictionPercent(dynamic value, {bool signed = false}) {
  final amount = predictionNum(value);
  final prefix = signed && amount > 0 ? '+' : '';
  return '$prefix${predictionPercentFormat.format(amount)}%';
}

String predictionDateTime(dynamic value) {
  if (value == null) return '--';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('HH:mm dd/MM/yyyy').format(parsed);
}

String predictionText(dynamic value, {String fallback = '--'}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String predictionScoreLabel(Map<String, dynamic> data) {
  return '${predictionInt(data['predictHomeScore'])} - ${predictionInt(data['predictAwayScore'])}';
}

String predictionWinnerKey(Map<String, dynamic> data) {
  if (data['homeWin'] == true) return 'home';
  if (data['awayWin'] == true) return 'away';
  if (data['draw'] == true) return 'draw';
  return 'none';
}
