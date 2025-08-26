import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';

/// Tab body for PRJMGT ESTCOSTS (Estimated Cost)
class ProjectManagementEstCostsTabBody extends CoreTabBody {
  const ProjectManagementEstCostsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProjectManagementEstCostsTabBody> createState() => _ProjectManagementEstCostsTabBodyState();
}

class _ProjectManagementEstCostsTabBodyState extends CoreTabBodyState<ProjectManagementEstCostsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ProjectManagementEstCostsTabBody oldWidget) {
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

  void _onChanged(List<Map<String, dynamic>> value) {
    setState(() {
      _moduleData['projectEstimatedCosts'] = value;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...CoreDynamicFields.buildFields(
            fieldConfigs: [
              {
                'key': 'projectEstimatedCosts',
                'widget': 'collection',
                'label': 'Estimated Costs',
                'itemLabel': 'Estimated Expense',
                'addButtonText': 'Add Estimated Cost',
                'hintText': 'No estimated costs yet. Click Add Estimated Cost to get started.',
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
                    { 'key': 'total', 'label': 'Total', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  ]
                },
                'children': [
                  { 'key': 'travelExpenseTypeId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Type', 'data': 'DROPDOWN.PRJMGT/TRAVELEXPENSETYPE', 'display': 'name', 'required': true },
                  { 'key': 'total', 'widget': 'input', 'label': 'Total Amount', 'type': 'number', 'required': true },
                ],
              },
            ],
            itemDetail: _itemDetail,
            moduleData: _moduleData,
            onChanged: (k, v) => _onChanged(v as List<Map<String, dynamic>>),
          ),
        ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Max items not enforced here; if needed, add a check
    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['projectEstimatedCosts'] == null) {
            _moduleData['projectEstimatedCosts'] = [];
          }
          final l = _moduleData['projectEstimatedCosts'] as List;
          // useAddFirstList = true default for FAB UX
          l.insert(0, <String, dynamic>{
            'id': null,
            'total': 0,
          });

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
