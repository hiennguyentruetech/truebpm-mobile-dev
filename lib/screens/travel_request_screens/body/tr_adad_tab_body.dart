import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';

/// Tab body for TRAREQ ADAD (Additional Advance)
/// Show entire body as a collection similar to project_management_addcostdoc_tab_body.dart
class TRAdditionalAdvanceTabBody extends CoreTabBody {
  const TRAdditionalAdvanceTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRAdditionalAdvanceTabBody> createState() => _TRAdditionalAdvanceTabBodyState();
}

class _TRAdditionalAdvanceTabBodyState extends CoreTabBodyState<TRAdditionalAdvanceTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRAdditionalAdvanceTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    final value = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    // ADAD uses the entire list from key 'additionalAdvance'
    final List<dynamic> additionalAdvance = List<dynamic>.from(value['additionalAdvance'] ?? []);

    // Normalize module data structure for CoreDynamicFields consumption
    _moduleData = {
      'additionalAdvance': additionalAdvance,
      // include some summary fields if needed
      'perDiemAdvance': value['perDiemAdvance'],
      'perDiemOthers': value['perDiemOthers'],
      'perDiemTotal': value['perDiemTotal'],
    };

    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
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
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...CoreDynamicFields.buildFields(
            fieldConfigs: [
              {
                'key': 'additionalAdvance',
                'widget': 'collection',
                'label': 'Additional Advance',
                'itemLabel': 'Advance Item',
                'addButtonText': 'Add New Advance',
                'hintText': 'No additional advance. Click to add.',
                'allowAdd': true,
                'allowRemove': true,
                'editMode': 'modal',
                'useFloatingAddButton': true,
                'useAddFirstList': true,
                'children': [
                  {'key': 'reasons', 'label': 'Reasons', 'type': 'textarea', 'maxLines': 3},
                  {'key': 'perDiemAdvance', 'label': 'Per Diem Advance', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                  {'key': 'perDiemOthers', 'label': 'Per Diem Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                ],
              },
            ],
            itemDetail: _itemDetail,
            moduleData: _moduleData,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}

