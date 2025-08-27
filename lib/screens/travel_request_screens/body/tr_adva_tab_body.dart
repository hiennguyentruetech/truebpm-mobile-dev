import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRAREQ ADVA (Advance)
class TRAdvanceTabBody extends CoreTabBody {
  const TRAdvanceTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRAdvanceTabBody> createState() => _TRAdvanceTabBodyState();
}

class _TRAdvanceTabBodyState extends CoreTabBodyState<TRAdvanceTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {}; // holds full itemDetail.value to preserve nested paths

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRAdvanceTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    // Keep entire value object so dot-notation paths work (e.g., 'advance.reasons')
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      // Support nested path updates like 'advance.reasons'
      _setByPath(_moduleData, key, value);
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
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

  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvanceInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildAdvanceInfoSection() {
    return CardSection(
      title: 'Advance Payment',
      headerIcon: Icons.payments_outlined,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'advance.reasons', 'label': 'Reasons', 'type': 'textarea', 'maxLines': 3, 'onlyView': false},
            {'key': 'advance.perDiemAdvance', 'label': 'Per Diem Advance', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
            {'key': 'advance.perDiemOthers', 'label': 'Per Diem Others', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0, 'onlyView': false},
          ],
          itemDetail: {'value': _moduleData},
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
      itemDetail: {'value': _moduleData},
    );
  }
}

