import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';

/// Tab body for TRACLA INFO - Special Expense (use same tab code 'INFO' but separate UI tab)
class TRCInfoSpecialTabBody extends CoreTabBody {
  const TRCInfoSpecialTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRCInfoSpecialTabBody> createState() => _TRCInfoSpecialTabBodyState();
}

class _TRCInfoSpecialTabBodyState extends CoreTabBodyState<TRCInfoSpecialTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  
  // Helper: resolve parent id for dropdown endpoints
  String? get _parentId {
    return _moduleData['id'] ?? _moduleData['travelClaimId'];
  }

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRCInfoSpecialTabBody oldWidget) {
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
      // If updating specialExpense collection we recompute derived fields (travelRequestCode default date helper)
      if (key == 'specialExpense' && value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            // When travelRequestReason selected, expose travelRequestCode and default date helper
            final reason = item['travelRequestReason'];
            if (reason is Map<String, dynamic>) {
              if (reason['travelRequestCode'] != null) {
                item['travelRequestCode'] = reason['travelRequestCode'];
              }
              // Provide startDate/endDate as dynamic min/max and default date path
              final startDate = reason['startDate'];
              if (startDate != null) {
                item['_defaultDate_date'] = startDate; // used by defaultDatePath
              }
            }
            // Compute totalAfterTax (no deductible) when total or expenseType present
            final totalRaw = item['total'];
            double total = 0;
            if (totalRaw is int) total = totalRaw.toDouble();
            else if (totalRaw is double) total = totalRaw;
            double rawTax = 0;
            if (item['expenseType'] is Map && (item['expenseType']['tax'] is num)) {
              rawTax = (item['expenseType']['tax'] as num).toDouble();
            } else if (item['tax'] is num) {
              rawTax = (item['tax'] as num).toDouble();
            }
            final taxRate = rawTax <= 1 ? rawTax : rawTax / 100;
            if (total > 0) {
              final totalAfterTax = total - (total * taxRate);
              item['totalAfterTax'] = totalAfterTax.round();
            } else {
              item['totalAfterTax'] = 0;
            }
          }
        }
      }
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final parentId = _parentId;
    final encodedParentId = parentId == null ? '' : Uri.encodeComponent(parentId.toString());

    final fieldConfigs = [
      {
        'key': 'specialExpense',
        'widget': 'collection',
        'label': 'Special Expense',
        'titleTemplate': '{travelRequestReason.travelRequestCode}',
        'addButtonText': 'Add Special Expense',
        'hintText': 'No special expense yet. Tap Add to create one.',
        'allowAdd': true,
        'allowRemove': true,
        'editMode': 'modal',
        'useFloatingAddButton': true,
        'useAddFirstList': true,
        'summary': {
          'fields': [
            { 'key': 'travelRequestReason', 'display': 'details', 'label': 'TR Reason', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
            { 'key': 'date', 'label': 'Date', 'type': 'date', 'format': 'dd/MM/yyyy', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'expenseType', 'display': 'name', 'label': 'Type', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'locationObject', 'display': 'name', 'label': 'Location', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'purpose', 'label': 'Purpose', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'total', 'label': 'Total', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
            { 'key': 'totalAfterTax', 'label': 'Total After Tax', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
          ]
        },
        'children': [
          {
            'key': 'travelRequestReason',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Travel Request Reason',
            'data': 'DROPDOWN.TRACLA/TR.REASON.BYCLAIM?id=$encodedParentId',
            'display': 'details',
            'moreDisplay': [
              { 'key': 'travelRequestCode', 'label': 'Code' },
              { 'key': 'reasonType.name', 'label': 'Type' },
              { 'key': 'startDate', 'label': 'Start', 'type': 'date', 'format': 'dd/MM/yyyy' },
              { 'key': 'endDate', 'label': 'End', 'type': 'date', 'format': 'dd/MM/yyyy' },
            ],
            'required': true,
            'clearOnChange': ['date'],
          },
          {
            'key': 'travelRequestReason.travelRequestCode',
            'label': 'Travel Request Code',
            'type': 'text',
            'disabled': true,
            'onlyView': true,
          },
            {
            'key': 'date',
            'widget': 'datetime',
            'label': 'Date',
            'datetimeType': 'date',
            'displayFormat': 'ddMMyyyy',
            'required': true,
            'minDatePath': 'travelRequestReason.startDate',
            'maxDatePath': 'travelRequestReason.endDate',
            'defaultDatePath': 'travelRequestReason.startDate',
          },
          {
            'key': 'expenseType',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Expense Type',
            'data': 'DROPDOWN.TRACLA/EXP.TYPE.SPECIAL',
            'display': 'name',
            'required': true,
          },
          {
            'key': 'locationObject',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Location',
            'data': 'DROPDOWN.TRACLA/LOC.BYCLAIM?id=$encodedParentId',
            'display': 'name',
            'required': true,
          },
          { 'key': 'purpose', 'label': 'Purpose', 'type': 'textarea', 'maxLines': 3, 'required': true },
          { 'key': 'total', 'label': 'Total', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'required': true },
          { 'key': 'totalAfterTax', 'label': 'Total After Tax', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'disabled': true },
        ],
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...CoreDynamicFields.buildFields(
              fieldConfigs: fieldConfigs,
              itemDetail: _itemDetail,
              moduleData: _moduleData,
              onChanged: _onChanged,
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // If need maxItems later add logic here
    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['specialExpense'] == null) {
            _moduleData['specialExpense'] = [];
          }
          final l = _moduleData['specialExpense'] as List;
          l.insert(0, <String, dynamic>{});
          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        });
        if (widget.onDataChanged != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            widget.onDataChanged!(_response);
          });
        }
      },
    );
  }
}

