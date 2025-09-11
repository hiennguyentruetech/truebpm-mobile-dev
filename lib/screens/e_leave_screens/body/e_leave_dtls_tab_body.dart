import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tab body for ELEAVE DTLS (Details)
class ELeaveDetailsTabBody extends CoreTabBody {
  const ELeaveDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ELeaveDetailsTabBody> createState() => _ELeaveDetailsTabBodyState();
}

class _ELeaveDetailsTabBodyState extends CoreTabBodyState<ELeaveDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  Map<String, dynamic> _leaveBalance = {};
  bool _isLoadingBalance = false;
  bool _hasLoadedBalance = false;
  // NEW: Stats for selected leaveType (only for NEW records)
  num? _usedLeaveDays; // from ELEAVE.USEDLEAVEDAYS
  num? _totalDayPerYear; // from ELEAVE.LEAVETYPEBYID
  bool _isLoadingLeaveTypeStats = false;

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
    _checkAndLoadLeaveBalance();
  }

  @override
  void didUpdateWidget(ELeaveDetailsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    if (mounted) {
      setState(() {});
      // Only check and load leave balance once when data is first loaded
      if (!_hasLoadedBalance) {
        _checkAndLoadLeaveBalance();
      }
      // NEW: if NEW and leaveType already selected, load stats immediately
      final bool isNew = (_moduleData['id'] == null || _moduleData['id'].toString().isEmpty) &&
                         (_moduleData['code'] == null || _moduleData['code'].toString().isEmpty);
      final dynamic _lt = _moduleData['leaveType'];
      final String? leaveTypeId = (_lt is Map && _lt['id'] != null)
          ? _lt['id'].toString()
          : null;
      if (isNew && leaveTypeId != null && leaveTypeId.isNotEmpty) {
        _loadLeaveTypeStats(leaveTypeId);
      }
    }
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);

      // Auto-calc totalDays when date range or leaveTime changes
      const relatedKeys = {'startDate', 'endDate', 'leaveTime'};
      if (relatedKeys.contains(key)) {
        final total = _calculateTotalDays(_moduleData);
        _moduleData['totalDays'] = total;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }

      // NEW: When leaveType changes and this is a NEW record, load stats
      if (key == 'leaveType') {
        // Clear previous stats
        _usedLeaveDays = null;
        _totalDayPerYear = null;
        // Only load when creating new (no id and no code)
        final isNew = (_moduleData['id'] == null || _moduleData['id'].toString().isEmpty) &&
                      (_moduleData['code'] == null || _moduleData['code'].toString().isEmpty);
        final leaveTypeId = value is Map ? value['id']?.toString() : null;
        if (isNew && leaveTypeId != null && leaveTypeId.isNotEmpty) {
          _loadLeaveTypeStats(leaveTypeId);
        }
      }
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  double? _calculateTotalDays(Map<String, dynamic> data) {
    final startIso = data['startDate']?.toString();
    final endIso = data['endDate']?.toString();
    final leaveTime = data['leaveTime'];
    
    if (startIso == null || endIso == null || leaveTime == null) return null;
    
    final start = _parseIsoDateOnly(startIso);
    final end = _parseIsoDateOnly(endIso);
    
    if (start == null || end == null) return null;

    // Count working days (Mon-Fri), exclude Saturday and Sunday, inclusive range
  final int workingDays = _countWorkingDays(start, end);
  double totalDays = workingDays.toDouble();
    
    // Calculate based on leaveTime type
    final leaveTimeId = leaveTime['id']?.toString();
    if (leaveTimeId == null) return totalDays;
    
    // Map known leaveTime IDs to factors
    final Map<String, double> factors = const {
      'D95FC623-A1D4-4E05-A93C-07BEE433C679': 1.0, // Full day
      '76022664-7E76-497B-A4DF-22CC5EAB7CA6': 0.5, // AM
      'AFB9171B-D653-4576-9C37-A5C01188400B': 0.5, // PM
    };

    final factor = factors[leaveTimeId] ?? 1.0;
    totalDays = totalDays * factor;

    // Normalize to 1 decimal place without rounding up unexpected values
    // e.g., 2.5 stays 2.5, 1 becomes 1.0 for consistent display
    return double.parse(totalDays.toStringAsFixed(1));
  }

  // NEW: Count working days between start and end inclusive, excluding Saturday/Sunday
  int _countWorkingDays(DateTime start, DateTime end) {
    if (end.isBefore(start)) return 0;
    int count = 0;
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
        count++;
      }
    }
    return count;
  }

  DateTime? _parseIsoDateOnly(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso);
      // Use UTC date-only
      return DateTime.utc(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  /// Check if should load leave balance and load if needed
  void _checkAndLoadLeaveBalance() {
    // Check if this is NEW action from list screen
    final isNewAction = widget.initialData?['action'] == 'NEW' || 
                       _response['action'] == 'NEW' ||
                       widget.itemId == null;
    
    // Determine id/code primarily from itemDetail.value (moduleData), fallback to itemDetail root
    final idValue = _moduleData['id']?.toString().trim().isNotEmpty == true
        ? _moduleData['id'].toString()
        : _itemDetail['id']?.toString();
    final codeValue = _moduleData['code']?.toString().trim().isNotEmpty == true
        ? _moduleData['code'].toString()
        : _itemDetail['code']?.toString();

    final hasId = idValue != null && idValue.isNotEmpty;
    final hasCode = codeValue != null && codeValue.isNotEmpty;

    if (isNewAction || (!hasId && !hasCode)) {
      // This is NEW action or new record (no id/code), load leave balance from API
      _loadLeaveBalance();
    } else {
      // This is existing record (has both id and code), use data from itemDetail.value
      _updateLeaveBalanceFromItemDetail();
    }
    
    // Mark as loaded to prevent future calls
    _hasLoadedBalance = true;
  }

  /// Update leave balance from itemDetail.value data
  void _updateLeaveBalanceFromItemDetail() {
    final value = _itemDetail['value'];
    if (value != null && value is Map<String, dynamic>) {
      setState(() {
        _leaveBalance = {
          'TotalRemainLeave': value['totalRemainLeave'] ?? value['TotalRemainLeave'] ?? 0.0,
          'TotalLeaveApplied': value['totalLeaveApplied'] ?? value['TotalLeaveApplied'] ?? 0.0,
        };
      });
    } else {
      // Fallback to default values if no data available
      setState(() {
        _leaveBalance = {
          'TotalRemainLeave': 0.0,
          'TotalLeaveApplied': 0.0,
        };
      });
    }
  }

  /// Format decimal number to maximum 2 decimal places
  String? _formatDecimal(dynamic value) {
    if (value == null) return null;
    
    try {
      final numValue = double.tryParse(value.toString());
      if (numValue == null) return null;
      
      // Format to maximum 2 decimal places
      return numValue.toStringAsFixed(2);
    } catch (_) {
      return null;
    }
  }

  /// Load leave balance from API
  Future<void> _loadLeaveBalance() async {
    if (_isLoadingBalance) return;
    
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        return;
      }

      final userInfo = jsonDecode(userJsonStr);
      final employeeId = userInfo['id']?.toString();
      
      if (employeeId == null || employeeId.isEmpty) {
        return;
      }

      final endpoint = 'ELEAVE.LEAVESTATEBYEMPLOYEEID?employeeId=$employeeId';
      final result = await CoreService.instance.getDropdownData(endpoint);
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is List && data.isNotEmpty) {
          // Lấy phần tử đầu tiên
          final firstItem = data[0];
          setState(() {
            _leaveBalance = Map<String, dynamic>.from(firstItem);
          });
        }
      }
    } catch (e) {
      // Error loading leave balance
    } finally {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  // NEW: Load leave type stats (UsedDay and TotalDayPerYear) for selected leaveType (only when NEW)
  Future<void> _loadLeaveTypeStats(String leaveTypeId) async {
    if (_isLoadingLeaveTypeStats) return;
    setState(() { _isLoadingLeaveTypeStats = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        setState(() { _isLoadingLeaveTypeStats = false; });
        return;
      }
      final userInfo = jsonDecode(userJsonStr);
      final employeeId = userInfo['id']?.toString();
      if (employeeId == null || employeeId.isEmpty) {
        setState(() { _isLoadingLeaveTypeStats = false; });
        return;
      }

      final int currentYear = DateTime.now().year;

      // Prepare locals then commit once to avoid intermediate UI states
      num? nextUsedLeaveDays;
      num? nextTotalDayPerYear;

      // API 1: Used leave days in current year
      final endpoint1 = 'ELEAVE.USEDLEAVEDAYS?leaveTypeId=$leaveTypeId&currentYear=$currentYear&employeeId=$employeeId';
      final res1 = await CoreService.instance.getDropdownData(endpoint1);
      if (res1['success'] == true && res1['data'] != null) {
        final data = res1['data'];
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          nextUsedLeaveDays = first is Map && first['UsedDay'] != null ? num.tryParse(first['UsedDay'].toString()) : null;
        } else if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = (data['data'] as List).first;
          nextUsedLeaveDays = first is Map && first['UsedDay'] != null ? num.tryParse(first['UsedDay'].toString()) : null;
        }
      }

      // API 2: Total days per year for this leave type
      final endpoint2 = 'ELEAVE.LEAVETYPEBYID?leaveTypeId=$leaveTypeId';
      final res2 = await CoreService.instance.getDropdownData(endpoint2);
      if (res2['success'] == true && res2['data'] != null) {
        final data = res2['data'];
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          nextTotalDayPerYear = first is Map && first['TotalDayPerYear'] != null ? num.tryParse(first['TotalDayPerYear'].toString()) : null;
        } else if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = (data['data'] as List).first;
          nextTotalDayPerYear = first is Map && first['TotalDayPerYear'] != null ? num.tryParse(first['TotalDayPerYear'].toString()) : null;
        }
      }
      if (mounted) {
        setState(() {
          _usedLeaveDays = nextUsedLeaveDays;
          _totalDayPerYear = nextTotalDayPerYear;
        });
      }
    } catch (_) {
      // ignore errors, keep values null
    } finally {
      if (mounted) setState(() { _isLoadingLeaveTypeStats = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaveBalanceCards(),
          _buildLeaveDetailsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    );
  }

  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaveBalanceCards(),
          if (_shouldShowLeaveTypeInfoCards()) _buildLeaveTypeInfoCards(),
          _buildLeaveDetailsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildLeaveBalanceCards() {
    // Priority: _leaveBalance (from API or itemDetail) > _moduleData > default
    final totalRemain = _formatDecimal(_leaveBalance['TotalRemainLeave']) ?? 
                        _formatDecimal(_moduleData['totalRemainLeave']) ?? '0.00';
    final totalApplied = _formatDecimal(_leaveBalance['TotalLeaveApplied']) ?? 
                         _formatDecimal(_moduleData['totalLeaveApplied']) ?? '0.00';
    
    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            title: 'Remaining Leave',
            value: totalRemain,
            icon: Icons.account_balance_wallet,
            color: Colors.green,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBalanceCard(
            title: 'Leave Applied',
            value: totalApplied,
            icon: Icons.calendar_month,
            color: Colors.orange,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Cards to show UsedDay and TotalDayPerYear: show when NEW and leaveType selected
  bool _shouldShowLeaveTypeInfoCards() {
    final bool isNew = (_moduleData['id'] == null || _moduleData['id'].toString().isEmpty) &&
                       (_moduleData['code'] == null || _moduleData['code'].toString().isEmpty);
    final dynamic lt = _moduleData['leaveType'];
    final bool hasLeaveType = lt != null;
    // Hide cards for Annual type
    final String? ltId = (lt is Map && lt['id'] != null) ? lt['id'].toString() : null;
    final String ltName = (lt is Map && lt['name'] != null) ? lt['name'].toString() : '';
    final bool isAnnual = (ltId == 'FFFFD914-6057-4286-A321-773680D400A9') || (ltName.toLowerCase() == 'annual');
    return isNew && hasLeaveType && !isAnnual;
  }

  Widget _buildLeaveTypeInfoCards() {
    final String used = _formatNumValue(_usedLeaveDays);
    final String total = _formatNumValue(_totalDayPerYear);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildLeaveTypeStatCard(
              title: 'Used Days',
              value: used,
              icon: Icons.event_busy,
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildLeaveTypeStatCard(
              title: 'Total Days',
              value: total,
              icon: Icons.event_available,
              gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatNumValue(num? value) {
    if (value == null) return '';
    // Trim trailing .0 for whole numbers, keep up to 2 decimals otherwise
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    String s = value.toStringAsFixed(2);
    // remove trailing zeros then possible trailing dot
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  // NEW: Dedicated card for leaveType stats with wrapping text and optional loader
  Widget _buildLeaveTypeStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      // height: 70,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isLoadingLeaveTypeStats && value.isEmpty)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                value.isEmpty ? '0' : value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveDetailsSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.calendar_today,
      headerColor: const Color.fromARGB(255, 26, 32, 159),
      children: [
        // Part 1: fields up to and including leaveType
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'Code', 'type': 'text', 'disabled': true},
            { 'key': 'startDate', 'widget': 'datetime', 'label': 'Start Date - End Date', 'datetimeType': 'daterange', 'startDateKey': 'startDate', 'endDateKey': 'endDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select leave duration...', 'required': true},
            {
              'key': 'leaveTime',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Date Status',
              'hintText': 'Select leave time',
              'data': 'DROPDOWN.ELEAVE/LEAVETIME',
              'display': 'name',
              'required': true,
            },      
            { 'key': 'totalDays', 'label': 'Total Days', 'type': 'number', 'decimalPlaces': 1, 'disabled': true},
            {
              'key': 'leaveType',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'I wish to apply for',
              'hintText': 'Select leave type',
              'data': 'DROPDOWN.ELEAVE/LEAVETYPE',
              'display': 'name',
              'required': true,
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
        // Inline cards right under leaveType
        if (_shouldShowLeaveTypeInfoCards()) _buildLeaveTypeInfoCards(),
        // Part 2: remaining fields after leaveType
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'leaveReason',
              'label': 'Reason',
              'type': 'textarea',
              'required': true,
              'maxLines': 3,
              'hintText': 'Enter leave reason...',
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'createdBy', 'label': 'Created By', 'hintText': 'Created by user', 'type': 'text', 'disabled': true},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Record creation date', 'disabled': true},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  @override
  bool validateData() {
    return CoreDynamicFields.validateData(
      context: context,
      moduleData: _moduleData,
      itemDetail: _itemDetail,
    );
  }

  // Prepare data for save/submit
  Map<String, dynamic> prepareDataForSave() {
    return Map<String, dynamic>.from(_moduleData);
  }

  @override
  Future<void> loadTabSpecificData() async {
    // No-op, data provided by provider initialData
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Update leave balance from updated itemDetail after save
    _updateLeaveBalanceFromItemDetail();
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Update leave balance from updated itemDetail after submit
    _updateLeaveBalanceFromItemDetail();
  }
}
