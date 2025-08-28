import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for OVTIME DTLS (Details)
class OTDetailsTabBody extends CoreTabBody {
  const OTDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<OTDetailsTabBody> createState() => _OTDetailsTabBodyState();
}

class _OTDetailsTabBodyState extends CoreTabBodyState<OTDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(OTDetailsTabBody oldWidget) {
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

      // Auto-calc totalHour when any related field changes
      const relatedKeys = {
        'startDate', 'endDate',
        'amFromHours', 'amToHours',
        'pmFromHours', 'pmToHours',
      };
      if (relatedKeys.contains(key)) {
        final total = _calculateTotalHours(_moduleData);
        _moduleData['totalHour'] = total;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }
    });
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  double? _calculateTotalHours(Map<String, dynamic> data) {
    // Parse time ranges
    final amFrom = _parseTime(data['amFromHours']?.toString());
    final amTo   = _parseTime(data['amToHours']?.toString());
    final pmFrom = _parseTime(data['pmFromHours']?.toString());
    final pmTo   = _parseTime(data['pmToHours']?.toString());

    double perDayHours = 0;
    if (amFrom != null && amTo != null) {
      perDayHours += _diffHours(amFrom, amTo);
    }
    if (pmFrom != null && pmTo != null) {
      perDayHours += _diffHours(pmFrom, pmTo);
    }

    // If no time provided, nothing to compute
    if (perDayHours == 0) return null;

    // Parse date range (inclusive days)
    final startIso = data['startDate']?.toString();
    final endIso = data['endDate']?.toString();
    int days = 1; // default 1 day when range not set
    final start = _parseIsoDateOnly(startIso);
    final end = _parseIsoDateOnly(endIso);
    if (start != null && end != null) {
      final diff = end.difference(start).inDays;
      days = diff >= 0 ? diff + 1 : 1;
    }

    final total = perDayHours * days;
    // round to 1 decimal place for nicer display
    return double.parse(total.toStringAsFixed(1));
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  double _diffHours(TimeOfDay from, TimeOfDay to) {
    final fromMin = from.hour * 60 + from.minute;
    final toMin = to.hour * 60 + to.minute;
    final diffMin = toMin - fromMin;
    if (diffMin <= 0) return 0;
    return diffMin / 60.0;
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
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestInfoSection(),
          _buildDateTimeSection(),
          _buildReasonsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildRequestInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'OT Code', 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return CardSection(
      title: 'OT Information',
      headerIcon: Icons.access_time,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'approverId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Approver', 'hintText': 'Select approver', 'data': 'DROPDOWN.OVTIME/APPROVERS', 'display': 'fullName'},
            {'key': 'startDate', 'widget': 'datetime', 'label': 'From Date - To Date', 'datetimeType': 'daterange', 'startDateKey': 'startDate', 'endDateKey': 'endDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select project duration...'},
            {'key': 'amFromHours', 'widget': 'datetime', 'label': 'AM: From', 'datetimeType': 'time', 'defaultTime': '07:30'},
            {'key': 'amToHours', 'widget': 'datetime', 'label': 'AM: To', 'datetimeType': 'time', 'defaultTime': '11:30'},
            {'key': 'pmFromHours', 'widget': 'datetime', 'label': 'PM: From', 'datetimeType': 'time', 'defaultTime': '13:30'},
            {'key': 'pmToHours', 'widget': 'datetime', 'label': 'PM: To', 'datetimeType': 'time', 'defaultTime': '17:30'},
            {'key': 'totalHour', 'label': 'Total hours applied', 'type': 'number', 'disabled': true},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildReasonsSection() {
    return CardSection(
      title: 'Reasons',
      headerIcon: Icons.list_alt,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'reasons',
              'widget': 'collection',
              'label': 'OT Reasons',
              'itemLabel': 'Reason',
              'addButtonText': 'Add New Reason',
              'hintText': 'No reasons added yet. Click Add New Reason to get started.',
              'allowAdd': true,
              'allowRemove': true,
              // 'minItems': 0,
              // 'maxItems': 10,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'reasonType', 'display': 'name', 'label': 'Type', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
                  { 'key': 'percentage', 'label': 'Percent', 'suffix': '%', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
                  { 'key': 'opportunity', 'display': 'name', 'label': 'Opportunity', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row', 'visibleWhen': { 'key': 'reasonType.id', 'operator': 'eq', 'value': '63B92EB6-BCAB-4AB4-95C0-BBD9A07B36BF' } },
                  { 'key': 'product', 'display': 'name', 'label': 'Contract', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row', 'visibleWhen': { 'key': 'reasonType.id', 'operator': 'eq', 'value': 'C508C0FA-8208-4F09-B587-86C6DA621BBF' } },
                  { 'key': 'details', 'label': 'Details', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row' },
                ]
              },
              'children': [
                {
                  'key': 'reasonType',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Reason Type',
                  'hintText': 'Select reason type',
                  'data': 'DROPDOWN.OVTIME/OTREASONTYPES',
                  'display': 'name',
                  'required': true,
                  // When reason changes, clear all dependent fields
                  'clearOnChange': ['accountManager', 'opportunity', 'product', 'listProductCmdr']
                },
                {
                  'key': 'percentage',
                  'label': 'Percentage',
                  'type': 'number',
                  'suffix': '%',
                  'decimalPlaces': 0,
                  'minValue': 0,
                  'maxValue': 100,
                  'hintText': 'Enter percentage (0-100)',
                },
                {
                  'key': 'details',
                  'label': 'Details',
                  'type': 'textarea',
                  'required': true,
                  'maxLines': 3,
                  'hintText': 'Enter reason details...',
                },
                // Pre-Sales: Account Manager, then Opportunity depends on accountManager.preSales
                {
                  'key': 'accountManager',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Account Manager',
                  'hintText': 'Select account manager',
                  'data': 'DROPDOWN.OVTIME/REASONS_PRESALES',
                  'display': 'fullName',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': '63B92EB6-BCAB-4AB4-95C0-BBD9A07B36BF'
                  },
                  'clearOnChange': ['opportunity']
                },
                {
                  'key': 'opportunity',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Opportunity',
                  'hintText': 'Select opportunity',
                  'data': 'DROPDOWN.OVTIME/OPPORTUNITIES?ownerId={{accountManager.id}}',
                  'display': 'name',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': '63B92EB6-BCAB-4AB4-95C0-BBD9A07B36BF'
                  }
                },
                // Contract Implementation: Product then Project Commanders collection depends on product.id
                {
                  'key': 'product',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Contract',
                  'hintText': 'Select contract product',
                  'data': 'DROPDOWN.OVTIME/CONTRACTS',
                  'display': 'name',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': 'C508C0FA-8208-4F09-B587-86C6DA621BBF'
                  },
                  'clearOnChange': ['listProductCmdr']
                },
                {
                  'key': 'listProductCmdr',
                  'widget': 'collection',
                  'label': 'List CMDR',
                  'itemLabel': 'CMDR',
                  'addButtonText': 'Add Commander',
                  'hintText': 'No commanders added yet.',
                  'allowAdd': true,
                  'allowRemove': true,
                  'minItems': 0,
                  'maxItems': 5,
                  'editMode': 'inline',
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': 'C508C0FA-8208-4F09-B587-86C6DA621BBF'
                  },
                  'children': [
                    {
                      'key': 'productCmdr',
                      'widget': 'select',
                      'selectType': 'dropdown',
                      'label': 'CMDR Activity',
                      'hintText': 'Select project commander',
                      'data': 'DROPDOWN.OVTIME/PROJECTCMDRS?projectId={{product.id}}',
                      'display': 'name',
                      'required': true,
                    },
                  ],
                },
              ],
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
