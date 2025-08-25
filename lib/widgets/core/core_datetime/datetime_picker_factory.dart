import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'base_datetime_dialog.dart';
import 'custom_calendar.dart';
import 'custom_time_picker.dart';
import 'custom_date_range_calendar.dart';
import 'datetime_tab_navigation.dart';

/// Factory class để tạo các picker dialog theo type
class DateTimePickerFactory {
  
  /// Tạo date picker dialog
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    DateTime selectedDate = initialDate;
    
    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BaseDateTimeDialog(
            title: 'Select Date',
            headerIcon: Icons.calendar_today,
            subtitle: _formatDateForDisplay(selectedDate),
            height: 520,
            content: CustomCalendar(
              selectedDate: selectedDate,
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
              minDate: minDate,
              maxDate: maxDate,
            ),
            onConfirm: () => Navigator.of(context).pop(selectedDate),
          );
        },
      ),
    );
  }

  /// Tạo datetime picker dialog với tabs
  static Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDateTime,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    DateTime selectedDate = initialDateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(initialDateTime);
    int currentTab = 0;
    
    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BaseDateTimeDialog(
            title: 'Select Date & Time',
            headerIcon: Icons.access_time,
            subtitle: '${_formatDateForDisplay(selectedDate)} ${_formatTimeForDisplay(selectedTime)}',
            height: 550,
            content: Column(
              children: [
                DateTimeTabNavigation(
                  currentTab: currentTab,
                  tabLabels: const ['Date', 'Time'],
                  onTabChanged: (tab) {
                    setState(() {
                      currentTab = tab;
                    });
                  },
                ),
                
                Expanded(
                  child: currentTab == 0
                    ? CustomCalendar(
                        selectedDate: selectedDate,
                        onDateChanged: (date) {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                        minDate: minDate,
                        maxDate: maxDate,
                      )
                    : CustomTimePicker(
                        currentTime: selectedTime,
                        onTimeChanged: (time) {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                      ),
                ),
              ],
            ),
            onConfirm: () {
              final combined = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              Navigator.of(context).pop(combined);
            },
          );
        },
      ),
    );
  }

  /// Tạo time picker dialog
  static Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  }) async {
    TimeOfDay selectedTime = initialTime;
    return await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BaseDateTimeDialog(
            title: 'Select Time',
            headerIcon: Icons.schedule,
            subtitle: _formatTimeForDisplay(selectedTime),
            height: 440,
            content: CustomTimePicker(
              currentTime: selectedTime,
              minTime: minTime,
              maxTime: maxTime,
              onTimeChanged: (time) {
                setState(() {
                  selectedTime = time;
                });
              },
            ),
            onConfirm: () => Navigator.of(context).pop(selectedTime),
          );
        },
      ),
    );
  }

  /// Tạo date range picker dialog
  static Future<DateTimeRange?> showDateRangePicker({
    required BuildContext context,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    DateTime? startDate = initialStartDate;
    DateTime? endDate = initialEndDate;
    
    return await showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String subtitle = '';
          if (startDate != null && endDate != null) {
            subtitle = '${_formatDateForDisplay(startDate!)} - ${_formatDateForDisplay(endDate!)}';
          } else if (startDate != null) {
            subtitle = 'Start: ${_formatDateForDisplay(startDate!)}';
          } else {
            subtitle = 'Select date range';
          }

          return BaseDateTimeDialog(
            title: 'Select Date Range',
            headerIcon: Icons.date_range,
            subtitle: subtitle,
            height: 500,
            width: MediaQuery.of(context).size.width * 0.95,
            content: CustomDateRangeCalendar(
              startDate: startDate,
              endDate: endDate,
              onRangeChanged: (start, end) {
                setState(() {
                  startDate = start;
                  endDate = end;
                });
              },
              minDate: minDate,
              maxDate: maxDate,
            ),
            onConfirm: startDate != null && endDate != null
              ? () => Navigator.of(context).pop(DateTimeRange(start: startDate!, end: endDate!))
              : null,
          );
        },
      ),
    );
  }

  // Helper methods
  static String _formatDateForDisplay(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String _formatTimeForDisplay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
