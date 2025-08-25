/// Core DateTime Models
/// 
/// This file contains models and enums used by the CoreDateTime widget
/// and its modular components.

/// Enum for different types of date/time pickers
enum DateTimePickerType {
  date,
  dateTime,
  time,
  year,
  month,
  dayOfWeek,
  dateRange,
}

/// Enum for day of the week
enum DayOfWeek {
  monday(1, 'Thứ Hai'),
  tuesday(2, 'Thứ Ba'),
  wednesday(3, 'Thứ Tư'),
  thursday(4, 'Thứ Năm'),
  friday(5, 'Thứ Sáu'),
  saturday(6, 'Thứ Bảy'),
  sunday(7, 'Chủ Nhật');

  const DayOfWeek(this.value, this.displayName);
  
  final int value;
  final String displayName;
  
  static DayOfWeek fromValue(int value) {
    return DayOfWeek.values.firstWhere(
      (day) => day.value == value,
      orElse: () => DayOfWeek.monday,
    );
  }
}

/// Model for date range selection
class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;
  
  const DateRange({
    this.startDate,
    this.endDate,
  });
  
  DateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
  
  bool get isValid => startDate != null && endDate != null;
  
  bool get isComplete => isValid && !endDate!.isBefore(startDate!);
  
  @override
  String toString() {
    if (startDate == null && endDate == null) return '';
    if (startDate == null) return 'Đến: ${_formatDate(endDate!)}';
    if (endDate == null) return 'Từ: ${_formatDate(startDate!)}';
    return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }
  
  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// Configuration for datetime picker dialog
class DateTimePickerConfig {
  final String title;
  final String confirmText;
  final String cancelText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool use24HourFormat;
  final DateTimePickerType type;
  
  const DateTimePickerConfig({
    this.title = 'Chọn thời gian',
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.use24HourFormat = true,
    this.type = DateTimePickerType.dateTime,
  });
  
  DateTimePickerConfig copyWith({
    String? title,
    String? confirmText,
    String? cancelText,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool? use24HourFormat,
    DateTimePickerType? type,
  }) {
    return DateTimePickerConfig(
      title: title ?? this.title,
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      initialDate: initialDate ?? this.initialDate,
      firstDate: firstDate ?? this.firstDate,
      lastDate: lastDate ?? this.lastDate,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      type: type ?? this.type,
    );
  }
}

/// Tab configuration for datetime tab navigation
class DateTimeTab {
  final String title;
  final DateTimePickerType type;
  final bool isActive;
  
  const DateTimeTab({
    required this.title,
    required this.type,
    this.isActive = false,
  });
  
  DateTimeTab copyWith({
    String? title,
    DateTimePickerType? type,
    bool? isActive,
  }) {
    return DateTimeTab(
      title: title ?? this.title,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateTimeTab &&
        other.title == title &&
        other.type == type &&
        other.isActive == isActive;
  }
  
  @override
  int get hashCode => title.hashCode ^ type.hashCode ^ isActive.hashCode;
}
