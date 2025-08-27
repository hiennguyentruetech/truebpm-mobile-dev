import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRACLA INFO - General Expense (use same tab code 'INFO' but separate UI tab)
class TRCInfoGeneralTabBody extends CoreTabBody {
  const TRCInfoGeneralTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRCInfoGeneralTabBody> createState() => _TRCInfoGeneralTabBodyState();
}

class _TRCInfoGeneralTabBodyState extends CoreTabBodyState<TRCInfoGeneralTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRCInfoGeneralTabBody oldWidget) {
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
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...CoreDynamicFields.buildFields(
            fieldConfigs: [
              {
                'key': 'generalExpense',
                'widget': 'collection',
                'label': 'General Expense',
                'itemLabel': 'Expense Item',
                'addButtonText': 'Add Expense',
                'hintText': 'No expense added yet. Click Add to create one.',
                'allowAdd': true,
                'allowRemove': true,
                'editMode': 'modal',
                'useFloatingAddButton': false,
                'useAddFirstList': true,
                'children': [
                  {'key': 'date', 'widget': 'datetime', 'label': 'Date', 'datetimeType': 'date', 'displayFormat': 'ddMMyyyy'},
                  // object keys -> dropdown with sample endpoints
                  {'key': 'expenseType', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Expense Type', 'data': 'DROPDOWN.TRACLA/EXPENSETYPES', 'display': 'name'},
                  {'key': 'locationObject', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Location', 'data': 'DROPDOWN.TRACLA/LOCATIONS', 'display': 'name'},
                  {'key': 'purpose', 'label': 'Purpose', 'type': 'textarea', 'maxLines': 3},
                  {'key': 'deductible', 'label': 'Deductible', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                  {'key': 'total', 'label': 'Total', 'type': 'number', 'suffix': ' VND', 'decimalPlaces': 0},
                  {'key': 'tax', 'label': 'Tax', 'type': 'number', 'decimalPlaces': 2, 'suffix': ''},
                  {'key': 'totalAfterTax', 'label': 'Total After Tax', 'type': 'number', 'decimalPlaces': 0, 'suffix': ' VND'},
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

