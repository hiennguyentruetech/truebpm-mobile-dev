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
    
    final diff = end.difference(start).inDays;
    final totalDays = diff >= 0 ? diff + 1.0 : 1.0; // Inclusive days
    
    // Calculate based on leaveTime type
    final leaveTimeId = leaveTime['id']?.toString();
    if (leaveTimeId == null) return totalDays;
    
    switch (leaveTimeId) {
      case 'D95FC623-A1D4-4E05-A93C-07BEE433C679': // Full day
        return totalDays;
      case '76022664-7E76-497B-A4DF-22CC5EAB7CA6': // AM
        return totalDays * 0.5;
      case 'AFB9171B-D653-4576-9C37-A5C01188400B': // PM
        return totalDays * 0.5;
      default:
        return totalDays;
    }
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
            { 'key': 'totalDays', 'label': 'Total Days', 'type': 'number', 'disabled': true},
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
