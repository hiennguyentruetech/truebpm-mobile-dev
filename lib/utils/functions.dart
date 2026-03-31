import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Functions {
  static final Functions _instance = Functions._internal();
  Functions._internal();
  factory Functions() {
    return _instance;
  }

  // Format a number to Vietnamese currency style (e.g., 1.234.567 VNĐ)
  String formatVnCurrency(num price) {
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    try {
      final DateTime date = DateTime.parse(dateString);
      String day = date.day.toString().padLeft(2, '0');
      String month = date.month.toString().padLeft(2, '0');
      String year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  String formatDateTimeValue(
    String value,
    String? datetimeType,
    String? displayFormat,
  ) {
    try {
      DateTime? dateTime;

      if (value.contains('T')) {
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
      } else if (value.contains('/')) {
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
              dateTime = DateTime.utc(year, month, day, hour, minute);
            } else {
              dateTime = DateTime.utc(year, month, day);
            }
          }
        }
      } else {
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

      if (dateTime == null) return value;

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
          return DateFormat('dd/MM/yyyy').format(dateTime.toUtc());
        default:
          return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toUtc());
      }
    } catch (_) {
      return value;
    }
  }

  Color? parseColor(dynamic color) {
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

  dynamic getByPath(Map<String, dynamic> map, String path) {
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

  bool evaluateVisibility(dynamic visibleWhen, Map<String, dynamic> context) {
    final List conditions = visibleWhen is List ? visibleWhen : [visibleWhen];
    for (final cond in conditions) {
      if (cond is! Map) continue;
      final String key = cond['key']?.toString() ?? '';
      final String op = (cond['operator'] ?? cond['op'] ?? 'eq').toString();
      final dynamic expected = cond['value'];
      final dynamic actual = getByPath(context, key);
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
          if (actual == null || (actual is String && actual.trim().isEmpty)) {
            return false;
          }
          break;
        case 'empty':
          if (!(actual == null ||
              (actual is String && actual.trim().isEmpty))) {
            return false;
          }
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

  String renderTemplate(String template, Map<String, dynamic> context) {
    if (template.isEmpty) return '';
    final regex = RegExp(r'\{\s*([^}]+)\s*\}');
    return template.replaceAllMapped(regex, (match) {
      final path = match.group(1)!.trim();
      final value = getByPath(context, path);
      return value == null ? '' : value.toString();
    });
  }
}
