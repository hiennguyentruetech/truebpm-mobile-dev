import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for DASCFG DETAIL (Config Detail)
class DashboardConfigDetailCollectionTabBody extends CoreTabBody {
  const DashboardConfigDetailCollectionTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<DashboardConfigDetailCollectionTabBody> createState() =>
      _DashboardConfigDetailCollectionTabBodyState();
}

class _DashboardConfigDetailCollectionTabBodyState extends CoreTabBodyState<DashboardConfigDetailCollectionTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(DashboardConfigDetailCollectionTabBody oldWidget) {
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_response.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Map<String, dynamic>> fieldConfigs = [
      {
        'key': 'dashboardConfigDetail',
        'label': 'Chart Display Detail',
        'widget': 'collection',
        'itemLabel': 'Chart Config Item',
        'addButtonText': 'Add Chart Config',
        'hintText': 'No chart config items found.',
        'allowAdd': true,
        'allowRemove': true,
        'editMode': 'modal',
        'useFloatingAddButton': true,
        'useAddFirstList': true,
        'summary': {
          'fields': [
            {
              'key': 'displayOrder',
              'label': 'Display Order',
              'type': 'number',
              'bgColor': '#FFF4E6',
              'borderColor': '#FFCC99',
              'labelColor': '#C15700',
              'valueColor': '#A14400'
            },
            {
              'key': 'chartConfigId.name',
              'label': 'Chart Config',
              'layout': 'row',
              'bgColor': '#EDF7ED',
              'borderColor': '#B7E1B0',
              'labelColor': '#1E6F1E',
              'valueColor': '#125C12'
            },
          ],
        },
        'children': [
          {
            'key': 'displayOrder',
            'label': 'Display Order',
            'type': 'number',
            'required': true,
            'minValue': 1,
          },
          {
            'key': 'chartConfigId',
            'widget': 'select',
            'selectType': 'dropdown',
            'label': 'Chart Config',
            'hintText': 'Select chart config',
            'data': 'DROPDOWN.DASCFG/CHART_CONFIG',
            'display': 'name',
            'required': true,
          },
        ],
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: CoreDynamicFields.buildFields(
            fieldConfigs: fieldConfigs,
            itemDetail: _itemDetail,
            moduleData: _moduleData,
            onChanged: _onChanged,
          ),
        ),
      ).dismissKeyboardOnTap(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    final dashboardConfigDetail = _moduleData['dashboardConfigDetail'] as List?;
    final maxItems = null; // Keep unlimited unless backend/business requires a cap.

    if (maxItems != null && (dashboardConfigDetail?.length ?? 0) >= maxItems) {
      return null;
    }

    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['dashboardConfigDetail'] == null) {
            _moduleData['dashboardConfigDetail'] = [];
          }

          final list = _moduleData['dashboardConfigDetail'] as List;
          list.insert(0, <String, dynamic>{});

          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.onDataChanged?.call(_response);
        });
      },
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
