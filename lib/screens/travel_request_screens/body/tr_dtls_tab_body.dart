import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRAREQ DTLS (Details)
class TRDetailsTabBody extends CoreTabBody {
  const TRDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRDetailsTabBody> createState() => _TRDetailsTabBodyState();
}

class _TRDetailsTabBodyState extends CoreTabBodyState<TRDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRDetailsTabBody oldWidget) {
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
      // Support nested path updates like 'advance.reasons'
      if (key.contains('.')) {
        _setByPath(_moduleData, key, value);
      } else {
        _moduleData[key] = value;
      }
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      // Auto-calc totalDays when date range changes
      if (key == 'startDate' || key == 'endDate') {
        final total = _calculateTotalDays(_moduleData);
        _moduleData['totalDays'] = total;
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }
      
      // Auto-calc perDiemTotal when advance amounts change
      if (key == 'advance.perDiemAdvance' || key == 'advance.perDiemOthers') {
        final perDiemAdvance = _moduleData['advance']?['perDiemAdvance'] ?? 0;
        final perDiemOthers = _moduleData['advance']?['perDiemOthers'] ?? 0;
        final total = (perDiemAdvance ?? 0) + (perDiemOthers ?? 0);
        _setByPath(_moduleData, 'advance.perDiemTotal', total);
        _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
        _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      }
    });
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  void _setByPath(Map<String, dynamic> map, String path, dynamic value) {
    final parts = path.split('.');
    Map<String, dynamic> curr = map;
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final bool isLast = i == parts.length - 1;
      if (isLast) {
        curr[part] = value;
      } else {
        if (curr[part] is! Map<String, dynamic>) {
          curr[part] = <String, dynamic>{};
        }
        curr = curr[part] as Map<String, dynamic>;
      }
    }
  }

  int? _calculateTotalDays(Map<String, dynamic> data) {
    final startIso = data['startDate']?.toString();
    final endIso = data['endDate']?.toString();
    final start = _parseIsoDateOnly(startIso);
    final end = _parseIsoDateOnly(endIso);
    if (start == null || end == null) return null;
    final diff = end.difference(start).inDays;
    return (diff >= 0) ? diff + 1 : null; // inclusive
  }

  DateTime? _parseIsoDateOnly(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso);
      return DateTime.utc(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget buildTabContent(BuildContext context) {
    final hasId = _moduleData['id'] != null;
    final hasCode = _moduleData['code'] != null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralInfoSection(),
          if (hasId && hasCode) _buildAdvanceSummarySection(),
          if (!hasId && !hasCode) _buildAdvanceInfoSection(),
          _buildReasonsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'Code', 'disabled': true },
            { 'key': 'startDate', 'widget': 'datetime', 'label': 'Start Date - End Date', 'datetimeType': 'daterange', 'startDateKey': 'startDate', 'endDateKey': 'endDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select duration' },
            { 'key': 'totalDays', 'type': 'number', 'label': 'Total Days', 'suffix': ' days', 'disabled': true},
            { 'key': 'country', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Country', 'hintText': 'Select country', 'data': 'DROPDOWN.TRAREQ/COUNTRY', 'display': 'name', 'clearOnChange': ['locations'] },
            {
              'key': 'locations',
              'widget': 'select',
              'selectType': 'multiple',
              'label': 'Locations',
              'hintText': 'Select locations',
              'data': 'DROPDOWN.TRAREQ/LOCATION?countryId={{country.id}}',
              'display': 'name',
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildAdvanceSummarySection() {
    return CardSection(
      title: 'Advance Summary',
      headerIcon: Icons.summarize_outlined,
      headerColor: Colors.blue,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'perDiemAdvance', 'label': 'Per Diem', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'disabled': true},
            {'key': 'perDiemOthers', 'label': 'Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'disabled': true},
            {'key': 'perDiemTotal', 'label': 'Total', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'disabled': true},
          ],
          itemDetail: {'value': _moduleData},
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildAdvanceInfoSection() {
    return CardSection(
      title: 'Advance Payment',
      headerIcon: Icons.payments_outlined,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'advance.perDiemAdvance', 'label': 'Per Diem', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
            {'key': 'advance.perDiemOthers', 'label': 'Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
            {'key': 'advance.reasons', 'label': 'Advance Payment Reasons', 'type': 'textarea', 'maxLines': 3, 'onlyView': false},
          ],
          itemDetail: {'value': _moduleData},
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
              'label': 'Travel Reasons',
              'itemLabel': 'Reason',
              'addButtonText': 'Add New Reason',
              'hintText': 'Click Add to add reasons',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'reasonType', 'display': 'name', 'label': 'Type', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
                  { 'key': 'percentage', 'label': 'Percent', 'suffix': '%', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
                  { 'key': 'salesperson', 'display': 'fullName', 'label': 'Salesperson', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row' },
                  { 'key': 'opportunity', 'display': 'displayName', 'label': 'Opportunity', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row', 'visibleWhen': { 'key': 'reasonType.id', 'operator': 'eq', 'value': 'A965F4BE-F911-4B5A-A9CC-98C60590DA5D' } },
                  { 'key': 'project', 'display': 'projectCode', 'label': 'Project', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row', 'visibleWhen': { 'key': 'reasonType.id', 'operator': 'eq', 'value': 'F9BD509B-E5CE-4B5C-91F0-7D4097BF9906' } },
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
                  'data': 'DROPDOWN.TRAREQ/TRAVELREASONTYPE',
                  'display': 'name',
                  'required': true,
                  'clearOnChange': ['accountManager', 'opportunity', 'project', 'product']
                },
                {
                  'key': 'percentage',
                  'label': 'Percentage',
                  'type': 'number',
                  'suffix': '%',
                  'decimalPlaces': 0,
                  'minValue': 0,
                  'maxValue': 100,
                  'hintText': 'Enter percentage (0-100)'
                },
                {
                  'key': 'details',
                  'label': 'Details',
                  'type': 'textarea',
                  'required': true,
                  'maxLines': 3,
                  'hintText': 'Enter reason details...'
                },
                {
                  'key': 'salesperson',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Request from salesperson',
                  'hintText': 'Select salesperson',
                  'data': 'DROPDOWN.TRAREQ/SALEPERSON',
                  'display': 'fullName',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': 'A965F4BE-F911-4B5A-A9CC-98C60590DA5D'
                  },
                  'clearOnChange': ['opportunity']
                },
                {
                  'key': 'opportunity',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Opportunity',
                  'hintText': 'Select opportunity',
                  'data': 'DROPDOWN.TRAREQ/OPPORTUNITY?salespersonId={{salesperson.id}}',
                  'display': 'displayName',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': 'A965F4BE-F911-4B5A-A9CC-98C60590DA5D'
                  }
                },
                {
                  'key': 'project',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Project',
                  'hintText': 'Select project',
                  'data': 'DROPDOWN.TRAREQ/PROJECTS',
                  'display': 'projectCode',
                  'required': true,
                  'visibleWhen': {
                    'key': 'reasonType.id',
                    'operator': 'eq',
                    'value': 'F9BD509B-E5CE-4B5C-91F0-7D4097BF9906'
                  }
                }
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
            {'key': 'createdBy', 'label': 'Created By', 'type': 'text', 'disabled': true},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'disabled': true},
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
}

