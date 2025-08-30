import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/utils/keyboard_utils.dart';

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
    // ADAD uses the entire list from key 'additionalAdvanceList'
    final List<dynamic> additionalAdvanceList = List<dynamic>.from(value['additionalAdvanceList'] ?? []);

    // Normalize module data structure for CoreDynamicFields consumption
    _moduleData = {
      'additionalAdvanceList': additionalAdvanceList,
      // include some summary fields if needed
      'perDiemAdvance': value['perDiemAdvance'],
      'perDiemOthers': value['perDiemOthers'],
      'perDiemTotal': value['perDiemTotal'],
    };

    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    if (mounted) setState(() {});
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

  void _onChanged(String key, dynamic value) {
    setState(() {
      // Support nested path updates like 'additionalAdvance.reasons'
      if (key.contains('.')) {
        _setByPath(_moduleData, key, value);
      } else {
        _moduleData[key] = value;
      }
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
      
      // Auto-calc perDiemTotal when advance amounts change
      if (key == 'additionalAdvance.perDiemAdvance' || key == 'additionalAdvance.perDiemOthers') {
        final perDiemAdvance = _moduleData['additionalAdvance']?['perDiemAdvance'] ?? 0;
        final perDiemOthers = _moduleData['additionalAdvance']?['perDiemOthers'] ?? 0;
        final total = (perDiemAdvance ?? 0) + (perDiemOthers ?? 0);
        _moduleData['perDiemTotal'] = total;
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

  Widget _buildAdvanceInfoSection() {
    return CardSection(
      title: 'Additional Advance Information',
      headerIcon: Icons.payments_outlined,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'additionalAdvance.perDiemAdvance', 'label': 'Per Diem', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
            {'key': 'additionalAdvance.perDiemOthers', 'label': 'Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
            {'key': 'additionalAdvance.reasons', 'label': 'Additional Advance Reasons', 'type': 'textarea', 'maxLines': 3, 'onlyView': false},
          ],
          itemDetail: {'value': _moduleData},
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildAdditionalAdvanceListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'additionalAdvanceList',
              'widget': 'collection',
              'label': 'Additional Advance',
              'itemLabel': 'Advance Item',
              'addButtonText': 'Add New Advance',
              'hintText': 'No additional advance.',
              'allowAdd': false,
              'allowRemove': true,
              'editMode': 'modal',
                              'summary': {
                  'fields': [
                    { 'key': 'perDiemAdvance', 'label': 'Per Diem', 'type': 'number', 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
                    { 'key': 'perDiemOthers', 'label': 'Others', 'type': 'number', 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
                    { 'key': 'reasons', 'label': 'Reasons', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
                  ]
                },
              'children': [
                {'key': 'perDiemAdvance', 'label': 'Per Diem Advance', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                {'key': 'perDiemOthers', 'label': 'Per Diem Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                {'key': 'reasons', 'label': 'Reasons', 'type': 'textarea', 'maxLines': 3},
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

  Widget _buildAdvanceSummarySection() {
    return CardSection(
      title: 'Advance Summary',
      headerIcon: Icons.summarize_outlined,
      headerColor: const Color.fromARGB(255, 72, 23, 135),
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

  @override
  Widget buildTabContent(BuildContext context) {
    return KeyboardUtils.withKeyboardDismissal(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdvanceInfoSection(),
            _buildAdvanceSummarySection(),
            const SizedBox(height: 10),
            _buildAdditionalAdvanceListSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

