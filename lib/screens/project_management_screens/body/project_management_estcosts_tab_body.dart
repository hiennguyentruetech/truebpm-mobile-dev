import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_collection.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoreCollection(
            dataKey: 'projectEstimatedCosts',
            itemDetail: _itemDetail,
            label: 'Project Estimated Costs',
            itemLabel: 'Estimated Cost',
            children: [
              {
                'dataKey': 'purpose',
                'label': 'Purpose',
                'required': true,
                'type': 'input',
              },
              {
                'dataKey': 'location',
                'label': 'Location',
                'required': true,
                'type': 'input',
              },
              {
                'dataKey': 'total',
                'label': 'Total Amount',
                'required': true,
                'type': 'number',
              },
              {
                'dataKey': 'date',
                'label': 'Date',
                'required': true,
                'type': 'date',
              },
              {
                'dataKey': 'travelExpenseTypeId',
                'label': 'Travel Expense Type',
                'required': true,
                'type': 'select',
                'data': 'DROPDOWN.TRAVEL_EXPENSE_TYPES.ALL',
                'display': 'name',
              },
            ],
            onChanged: _onChanged,
            allowAdd: true,
            allowRemove: true,
          ),
        ],
      ),
    );
  }
}
