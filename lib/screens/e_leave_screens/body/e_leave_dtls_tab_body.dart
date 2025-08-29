import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
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
    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);

      // Auto-calc totalDays when date range changes
      const relatedKeys = {'startDate', 'endDate'};
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
    
    if (startIso == null || endIso == null) return null;
    
    final start = _parseIsoDateOnly(startIso);
    final end = _parseIsoDateOnly(endIso);
    
    if (start == null || end == null) return null;
    
    final diff = end.difference(start).inDays;
    return diff >= 0 ? diff + 1.0 : 1.0; // Inclusive days
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
    final totalRemain = _moduleData['totalRemainLeave']?.toString() ?? '0';
    final totalApplied = _moduleData['totalLeaveApplied']?.toString() ?? '0';
    
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
            { 'key': 'code', 'label': 'Leave Code', 'type': 'text', 'disabled': true},
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
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
