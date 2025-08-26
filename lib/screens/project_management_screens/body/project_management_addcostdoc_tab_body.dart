import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/card_section.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTravelExpensesSection(),
        ],
      ),
    );
  }

  Widget _buildTravelExpensesSection() {
    return CardSection(
      title: 'Travel Expenses',
      headerIcon: Icons.receipt_long,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'projectAdditionalCosts',
              'widget': 'collection',
              'label': 'Travel Expenses',
              'itemLabel': 'Expense',
              'addButtonText': 'Add New Expense',
              'hintText': 'No expenses added yet. Click Add New Expense to get started.',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'purpose', 'label': 'Purpose', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'location', 'label': 'Location', 'bgColor': '#F3E5F5', 'borderColor': '#CE93D8', 'labelColor': '#7B1FA2', 'valueColor': '#4A148C' },
                  { 'key': 'date', 'label': 'Date', 'type': 'date', 'format': 'dd/MM/yyyy', 'bgColor': '#FFF3E0', 'borderColor': '#FFCC02', 'labelColor': '#E65100', 'valueColor': '#BF360C' },
                  { 'key': 'travelExpenseTypeId', 'display': 'name', 'label': 'Type', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
                  { 'key': 'total', 'label': 'Total', 'type': 'currency', 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                ]
              },
              'children': [
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
                  'key': 'travelExpenseTypeId',
                  'widget': 'select',
                  'selectType': 'dropdown',
                  'label': 'Expense Type',
                  'hintText': 'Select expense type',
                  'data': 'DROPDOWN.TRAVEL/EXPENSETYPES',
                  'display': 'name',
                  'required': true,
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
    );
  }
}
