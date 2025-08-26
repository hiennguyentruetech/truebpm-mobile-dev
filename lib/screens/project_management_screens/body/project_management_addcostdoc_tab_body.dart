import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';

/// Tab body for PRJMGT ADDCOSTDOC (Additional Cost)
class ProjectManagementAddCostDocTabBody extends CoreTabBody {
  const ProjectManagementAddCostDocTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProjectManagementAddCostDocTabBody> createState() => _ProjectManagementAddCostDocTabBodyState();
}

class _ProjectManagementAddCostDocTabBodyState extends CoreTabBodyState<ProjectManagementAddCostDocTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ProjectManagementAddCostDocTabBody oldWidget) {
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
    });
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'projectAdditionalCosts',
              'widget': 'collection',
              'label': 'Additional Costs',
              'itemLabel': 'Additional Expense',
              'addButtonText': 'Add New Expense',
              'hintText': 'No expenses added yet. Click Add New Expense to get started.',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'useFloatingAddButton': true,
              'useAddFirstList': true,
              'totalSummary': {
                'key': 'total',
                'label': 'Total',
                'format': '#,##0',
                'suffix': ' VND',
                'bgColor': '#E8F5E8',
                'borderColor': '#A5D6A7',
                'labelColor': '#2E7D32',
                'valueColor': '#1B5E20',
              },
              'summary': {
                'fields': [
                  { 'key': 'travelExpenseTypeId', 'display': 'name', 'label': 'Type', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
                  { 'key': 'purpose', 'label': 'Purpose', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'location', 'label': 'Location', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'date', 'label': 'Date', 'type': 'date', 'format': 'dd/MM/yyyy', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'total', 'label': 'Total', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                ]
              },
              'children': [
                {
                  'key': 'travelExpenseTypeId',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Expense Type',
                  'hintText': 'Select expense type',
                  'data': 'DROPDOWN.PRJMGT/TRAVELEXPENSETYPE',
                  'display': 'name',
                  'required': true,
                },
                {
                  'key': 'purpose',
                  'label': 'Purpose',
                  'type': 'text',
                  'required': true,
                  'hintText': 'Enter expense purpose...',
                },
                {
                  'key': 'location',
                  'label': 'Location',
                  'type': 'text',
                  'required': true,
                  'hintText': 'Enter location...',
                },
                {
                  'key': 'date',
                  'widget': 'datetime',
                  'label': 'Date',
                  'type': 'date',
                  'required': true,
                  'hintText': 'Select date',
                },
                {
                  'key': 'total',
                  'label': 'Total Amount',
                  'type': 'number',
                  'suffix': 'VND',
                  'required': true,
                  'hintText': 'Enter total amount...',
                },
              ]
            }
          ],
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
    // Check if we should show floating button based on config
    final projectAdditionalCosts = _moduleData['projectAdditionalCosts'] as List?;
    final maxItems = null; // You can configure this if needed

    if (maxItems != null && (projectAdditionalCosts?.length ?? 0) >= maxItems) {
      return null; // Don't show if max items reached
    }

    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['projectAdditionalCosts'] == null) {
            _moduleData['projectAdditionalCosts'] = [];
          }
          final list = _moduleData['projectAdditionalCosts'] as List;
          list.insert(0, <String, dynamic>{});

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
