import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/core_datetime/datetime_picker_factory.dart';
import 'core/core_select/components/clear_button.dart';

/// DateTime types enum for CoreDateTime
enum CoreDateTimeType {
  date,        // YYYY-MM-DD
  datetime,    // YYYY-MM-DD HH:mm
  time,        // HH:mm
  daterange,   // Date range with start and end
}

/// Date format display options
enum DateDisplayFormat {
  ddMMyyyy,    // 08/01/2025
  yyyyMMdd,    // 2025/01/08
  mmddyyyy,    // 01/08/2025 (renamed from MMddyyyy)
}

/// Core DateTime widget with dynamic data binding and professional design
/// 
/// Features:
/// - Multiple datetime types (date, datetime, time, daterange)
/// - ISO string format support (2025-01-08T16:11:52Z)
/// - Dynamic data binding with itemDetail
/// - Auto-hide/disable based on attributes
/// - Customizable date display formats
/// - Min/Max date restrictions
/// - Default date support
/// - Clear button functionality
/// - Professional and modern design
class CoreDateTime extends StatefulWidget {
  /// Minimum selectable time (for type: time)
  final TimeOfDay? minTime;
  /// Maximum selectable time (for type: time)
  final TimeOfDay? maxTime;
  /// Default time when opening time picker (for type: time)
  final TimeOfDay? defaultTime;
  /// Manually specify if the field is required (overrides API if set)
  final bool? required;
  
  /// The key to bind value from itemDetail.value.dataKey
  final String dataKey;
  
  /// For daterange type: start date key
  final String? startDateKey;
  
  /// For daterange type: end date key
  final String? endDateKey;
  
  /// The complete item detail response containing value, attribute, etc.
  final Map<String, dynamic> itemDetail;
  
  /// Display label for the input (defaults to dataKey if not provided)
  final String? label;
  
  /// DateTime type (date, datetime, time, year, month, dayOfWeek, daterange)
  final CoreDateTimeType type;
  
  /// Date display format for UI
  final DateDisplayFormat displayFormat;
  
  /// Minimum selectable date
  final DateTime? minDate;
  
  /// Maximum selectable date
  final DateTime? maxDate;
  
  /// Default date when opening picker (defaults to today)
  final DateTime? defaultDate;
  
  /// Callback when value changes
  final ValueChanged<String?>? onChanged;
  
  /// For daterange: callback when start date changes
  final ValueChanged<String?>? onStartDateChanged;
  
  /// For daterange: callback when end date changes
  final ValueChanged<String?>? onEndDateChanged;
  
  /// Hint text for the input
  final String? hintText;
  
  /// Custom text style
  final TextStyle? textStyle;
  
  /// Custom input decoration
  final InputDecoration? decoration;
  
  /// Focus node for the input
  final FocusNode? focusNode;

  /// Force-disable override. When set, takes precedence over attribute.disabled.
  final bool? disabled;

  /// Force-hidden override. When set, takes precedence over attribute.hidden.
  final bool? hidden;

  const CoreDateTime({
    super.key,
    required this.dataKey,
    required this.itemDetail,
    this.startDateKey,
    this.endDateKey,
    this.label,
    this.type = CoreDateTimeType.date,
    this.displayFormat = DateDisplayFormat.ddMMyyyy,
    this.minDate,
    this.maxDate,
    this.defaultDate,
    this.onChanged,
    this.onStartDateChanged,
    this.onEndDateChanged,
    this.hintText,
    this.textStyle,
    this.decoration,
    this.focusNode,
    this.required,
    this.minTime,
    this.maxTime,
    this.defaultTime,
    this.disabled,
    this.hidden,
  });

  @override
  State<CoreDateTime> createState() => _CoreDateTimeState();
}

class _CoreDateTimeState extends State<CoreDateTime> {
  late TextEditingController _controller;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late FocusNode _focusNode;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool get _isRequired {
    if (widget.required != null) return widget.required!;
    // Fallback to API attribute if available
    final requiredAttr = widget.itemDetail['attribute']?['required']?[widget.dataKey];
    return requiredAttr == true;
  }
  
  bool get _isDisabled {
  if (widget.disabled != null) return widget.disabled!;
  final disabledAttr = widget.itemDetail['attribute']?['disabled']?[widget.dataKey];
  return disabledAttr == true;
  }
  
  bool get _isHidden {
  if (widget.hidden != null) return widget.hidden!;
  final hiddenAttr = widget.itemDetail['attribute']?['hidden']?[widget.dataKey];
  return hiddenAttr == true;
  }
  
  String get _displayLabel {
    return widget.label ?? _formatLabel(widget.dataKey);
  }
  
  Widget get _buildLabel {
    final labelText = _displayLabel;
    if (_isRequired) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: labelText,
              style: TextStyle(
                color: _isDisabled
                    ? const Color.fromARGB(255, 180, 180, 180)
                    : const Color.fromARGB(255, 91, 91, 91),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        labelText,
        style: TextStyle(
          color: _isDisabled
              ? const Color.fromARGB(255, 180, 180, 180)
              : const Color.fromARGB(255, 91, 91, 91),
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
  
  String _formatLabel(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _startController = TextEditingController();
    _endController = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _initializeValues();
  }

  @override
  void didUpdateWidget(CoreDateTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update values when itemDetail changes
    if (oldWidget.itemDetail != widget.itemDetail || 
        oldWidget.dataKey != widget.dataKey ||
        oldWidget.startDateKey != widget.startDateKey ||
        oldWidget.endDateKey != widget.endDateKey) {
      _initializeValues();
    }
  }
  
  void _initializeValues() {
    if (widget.type == CoreDateTimeType.daterange) {
      _initializeDateRange();
    } else {
      _initializeSingleValue();
    }
  }
  
  void _initializeSingleValue() {
    final value = widget.itemDetail['value']?[widget.dataKey]?.toString();
    if (value != null && value.isNotEmpty) {
      _parseAndSetValue(value);
    }
  }
  
  void _initializeDateRange() {
    final startValue = widget.itemDetail['value']?[widget.startDateKey]?.toString();
    final endValue = widget.itemDetail['value']?[widget.endDateKey]?.toString();
    
    if (startValue != null && startValue.isNotEmpty) {
      _startDate = _parseISOString(startValue);
      _startController.text = _formatDateForDisplay(_startDate!);
    }
    
    if (endValue != null && endValue.isNotEmpty) {
      _endDate = _parseISOString(endValue);
      _endController.text = _formatDateForDisplay(_endDate!);
    }
    
    _updateDateRangeDisplay();
  }
  
  void _parseAndSetValue(String value) {
    switch (widget.type) {
      case CoreDateTimeType.date:
      case CoreDateTimeType.datetime:
        _selectedDate = _parseISOString(value);
        if (_selectedDate != null) {
          _controller.text = _formatDateTimeForDisplay(_selectedDate!, widget.type);
        }
        break;
      case CoreDateTimeType.time:
        _selectedTime = _parseTimeString(value);
        if (_selectedTime != null) {
          _controller.text = _formatTimeForDisplay(_selectedTime!);
        }
        break;
      case CoreDateTimeType.daterange:
        // Handled in _initializeDateRange()
        break;
    }
  }
  
  DateTime? _parseISOString(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      // Normalize to UTC without shifting wall time if source was local
      return parsed.isUtc
          ? parsed
          : DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
              parsed.millisecond,
              parsed.microsecond,
            );
    } catch (e) {
      return null;
    }
  }
  
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      // Handle both HH:mm and full ISO format
      if (timeString.contains('T')) {
        final dateTime = DateTime.parse(timeString);
        return TimeOfDay.fromDateTime(dateTime);
      } else {
        final parts = timeString.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      return null;
    }
  }
  
  String _formatDateTimeForDisplay(DateTime dateTime, CoreDateTimeType type) {
    final dt = dateTime.isUtc ? dateTime : DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
    switch (type) {
      case CoreDateTimeType.date:
        return _formatDateForDisplay(dt);
      case CoreDateTimeType.datetime:
        return '${_formatDateForDisplay(dt)} ${_formatTimeForDisplay(TimeOfDay.fromDateTime(dt))}';
      default:
        return _formatDateForDisplay(dt);
    }
  }
  
  String _formatDateForDisplay(DateTime dateTime) {
    final dt = dateTime.isUtc ? dateTime : DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
    switch (widget.displayFormat) {
      case DateDisplayFormat.ddMMyyyy:
        return DateFormat('dd/MM/yyyy').format(dt);
      case DateDisplayFormat.yyyyMMdd:
        return DateFormat('yyyy/MM/dd').format(dt);
      case DateDisplayFormat.mmddyyyy:
        return DateFormat('MM/dd/yyyy').format(dt);
    }
  }
  
  String _formatTimeForDisplay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  String? _getHelperText() {
    // Bỏ helper text để không hiển thị format bên dưới
    return null;
  }
  
  String _formatToISOString(DateTime dateTime, {TimeOfDay? time}) {
    if (time != null) {
      // Construct UTC from wall-time components to avoid local shift
      final combinedUtc = DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        time.hour,
        time.minute,
      );
      return combinedUtc.toIso8601String();
    }
    
    switch (widget.type) {
      case CoreDateTimeType.date:
        // Use midnight UTC without local conversion
        final dateOnlyUtc = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
        return dateOnlyUtc.toIso8601String();
      case CoreDateTimeType.datetime:
        // Build UTC from wall-time components
        final dtUtc = DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
        return dtUtc.toIso8601String();
      case CoreDateTimeType.time:
      case CoreDateTimeType.daterange:
        final utc = DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
        return utc.toIso8601String();
    }
  }
  
  String _formatTimeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  void _updateDateRangeDisplay() {
    if (_startDate != null && _endDate != null) {
      _controller.text = '${_formatDateForDisplay(_startDate!)} - ${_formatDateForDisplay(_endDate!)}';
    } else if (_startDate != null) {
      _controller.text = '${_formatDateForDisplay(_startDate!)} - ...';
    } else if (_endDate != null) {
      _controller.text = '... - ${_formatDateForDisplay(_endDate!)}';
    } else {
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _startController.dispose();
    _endController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.type == CoreDateTimeType.daterange)
          _buildDateRangeInput()
        else
          _buildSingleInput(),
      ],
    );
  }
  
  Widget _buildSingleInput() {
    return _buildInputField(
      controller: _controller,
      onTap: _showDateTimePicker,
      hintText: _getHintText(),
    );
  }
  
  Widget _buildDateRangeInput() {
    return Column(
      children: [
        _buildInputField(
          controller: _controller,
          onTap: _showDateRangePicker,
          hintText: widget.hintText ?? 'Select date range...',
        ),
      ],
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required VoidCallback onTap,
    required String hintText,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final hasValue = controller.text.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        focusNode: _focusNode,
        enabled: !_isDisabled,
        readOnly: true, // Tất cả đều readonly, chỉ popup
        canRequestFocus: false, // Disable focus cho tất cả
        onTap: _isDisabled ? null : onTap, // Tất cả đều có thể tap để popup
        onChanged: null, // Disable onChanged vì tất cả đều popup-only
        style: widget.textStyle ?? const TextStyle(fontSize: 14),
        decoration: widget.decoration ?? InputDecoration(
          // Dùng RichText để hiển thị dấu * màu đỏ khi required (đồng bộ với CoreInput)
          label: _buildLabel,
          floatingLabelStyle: TextStyle(
            fontSize: 17, // Match CoreInput
            fontWeight: FontWeight.w500, // Match CoreInput
            color: _isDisabled 
              ? const Color.fromARGB(255, 165, 165, 165) // Disabled floating like CoreInput
              : const Color.fromARGB(255, 91, 91, 91), // Normal grey color like CoreInput (not blue)
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always, // Label luôn floating
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          helperText: _getHelperText(),
          // Icon date ở đầu (prefixIcon)
          prefixIcon: IconButton(
            icon: Icon(
              _getDateTimeIconData(), 
              color: _isDisabled ? Colors.grey.shade400 : primaryColor
            ),
            onPressed: _isDisabled ? null : onTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          // Chỉ nút X ở suffixIcon với style CoreSelect
          suffixIcon: hasValue && !_isDisabled ? _buildClearButton() : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          filled: true,
          fillColor: _isDisabled ? Colors.grey.shade50 : Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(6, 12, 16, 12), // Dịch label sang trái bằng cách giảm left padding
        ),
      ),
    );
  }
  
  Widget _buildClearButton() {
    return GestureDetector(
      onLongPress: () {}, // Empty handler để disable context menu và tránh lỗi TextInput
      child: Container(
        padding: const EdgeInsets.all(12), // Tùy chỉnh padding tại đây
        child: ClearButtonWithAnimation(onTap: _clearValue),
      ),
    );
  }
  
  void _clearValue() {
    setState(() {
      _controller.clear();
      _startController.clear();
      _endController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _startDate = null;
      _endDate = null;
    });
    
    if (widget.type == CoreDateTimeType.daterange) {
      if (widget.onStartDateChanged != null) {
        widget.onStartDateChanged!(null);
      }
      if (widget.onEndDateChanged != null) {
        widget.onEndDateChanged!(null);
      }
    } else {
      if (widget.onChanged != null) {
        widget.onChanged!(null);
      }
    }
  }
  
  IconData _getDateTimeIconData() {
    switch (widget.type) {
      case CoreDateTimeType.date:
        return Icons.calendar_today;
      case CoreDateTimeType.datetime:
        return Icons.access_time;
      case CoreDateTimeType.time:
        return Icons.schedule;
      case CoreDateTimeType.daterange:
        return Icons.date_range;
    }
  }
  
  String _getHintText() {
    switch (widget.type) {
      case CoreDateTimeType.date:
        return widget.hintText ?? 'Select date...';
      case CoreDateTimeType.datetime:
        return widget.hintText ?? 'Select date and time...';
      case CoreDateTimeType.time:
        return widget.hintText ?? 'Select time...';
      case CoreDateTimeType.daterange:
        return widget.hintText ?? 'Select date range...';
    }
  }
  
  Future<void> _showDateTimePicker() async {
    switch (widget.type) {
      case CoreDateTimeType.date:
        await _showDatePicker();
        break;
      case CoreDateTimeType.datetime:
        await _showDateTimePickerCombined();
        break;
      case CoreDateTimeType.time:
        await _showTimePicker();
        break;
      case CoreDateTimeType.daterange:
        await _showDateRangePicker();
        break;
    }
  }
  
  Future<void> _showDatePicker() async {
    final initialDate = _selectedDate ?? widget.defaultDate ?? DateTime.now();
    
    final picked = await DateTimePickerFactory.showDatePicker(
      context: context,
      initialDate: initialDate,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _controller.text = _formatDateForDisplay(DateTime.utc(picked.year, picked.month, picked.day));
      });
      
      final isoString = _formatToISOString(picked);
      if (widget.onChanged != null) {
        widget.onChanged!(isoString);
      }
    }
  }
  
  Future<void> _showDateTimePickerCombined() async {
    final initialDate = _selectedDate ?? widget.defaultDate ?? DateTime.now();
    
    final picked = await DateTimePickerFactory.showDateTimePicker(
      context: context,
      initialDateTime: initialDate,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = TimeOfDay.fromDateTime(picked);
        _controller.text = _formatDateTimeForDisplay(
          DateTime.utc(
            picked.year,
            picked.month,
            picked.day,
            picked.hour,
            picked.minute,
          ),
          CoreDateTimeType.datetime,
        );
      });
      
      final isoString = _formatToISOString(picked, time: TimeOfDay.fromDateTime(picked));
      if (widget.onChanged != null) {
        widget.onChanged!(isoString);
      }
    }
  }
  
  Future<void> _showTimePicker() async {
    final initialTime = _selectedTime ?? widget.defaultTime ?? TimeOfDay(hour: 7, minute: 0);
    final picked = await DateTimePickerFactory.showTimePicker(
      context: context,
      initialTime: initialTime,
      minTime: widget.minTime,
      maxTime: widget.maxTime,
    );
    if (picked != null) {
      // Check minTime/maxTime if provided
      bool isValid = true;
      if (widget.minTime != null) {
        final min = widget.minTime!;
        if (picked.hour < min.hour || (picked.hour == min.hour && picked.minute < min.minute)) {
          isValid = false;
        }
      }
      if (widget.maxTime != null) {
        final max = widget.maxTime!;
        if (picked.hour > max.hour || (picked.hour == max.hour && picked.minute > max.minute)) {
          isValid = false;
        }
      }
      if (!isValid) {
        // Show error and do not update value
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time between '
                '${widget.minTime != null ? _formatTimeForDisplay(widget.minTime!) : '--:--'}'
                ' and '
                '${widget.maxTime != null ? _formatTimeForDisplay(widget.maxTime!) : '--:--'}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _selectedTime = picked;
        _controller.text = _formatTimeForDisplay(picked);
      });
      final timeString = _formatTimeToString(picked);
      if (widget.onChanged != null) {
        widget.onChanged!(timeString);
      }
    }
  }
  
  Future<void> _showDateRangePicker() async {
    final initialStart = _startDate;
    final initialEnd = _endDate;
    
    final picked = await DateTimePickerFactory.showDateRangePicker(
      context: context,
      initialStartDate: initialStart,
      initialEndDate: initialEnd,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _startController.text = _formatDateForDisplay(DateTime.utc(picked.start.year, picked.start.month, picked.start.day));
        _endController.text = _formatDateForDisplay(DateTime.utc(picked.end.year, picked.end.month, picked.end.day));
      });
      
      _updateDateRangeDisplay();
      
      if (widget.onStartDateChanged != null && widget.startDateKey != null) {
        final startIso = _formatToISOString(picked.start);
        widget.onStartDateChanged!(startIso);
      }
      
      if (widget.onEndDateChanged != null && widget.endDateKey != null) {
        final endIso = _formatToISOString(picked.end);
        widget.onEndDateChanged!(endIso);
      }
    }
  }
}
