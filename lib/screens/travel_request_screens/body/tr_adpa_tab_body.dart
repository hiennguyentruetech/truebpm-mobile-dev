import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for TRAREQ ADPA (Advance Payment)
class TRAdvancePaymentTabBody extends CoreTabBody {
  const TRAdvancePaymentTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TRAdvancePaymentTabBody> createState() => _TRAdvancePaymentTabBodyState();
}

class _TRAdvancePaymentTabBodyState extends CoreTabBodyState<TRAdvancePaymentTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TRAdvancePaymentTabBody oldWidget) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdvancePaymentSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildAdvancePaymentSection() {
    return CardSection(
      title: 'Advance Payment Records',
      headerIcon: Icons.payment_outlined,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'advancePayment',
              'widget': 'collection',
              'label': 'Advance Payment List',
              'itemLabel': 'Payment Record',
              'addButtonText': 'Add Payment Record',
              'hintText': 'No advance payment records found.',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'totalSummary': {
                'key': 'total',
                'label': 'Total Payment',
                'format': '#,##0',
                'suffix': ' VND',
                'bgColor': '#E8F5E8',
                'borderColor': '#A5D6A7',
                'labelColor': '#2E7D32',
                'valueColor': '#1B5E20',
              },
              'summary': {
                'fields': [
                  { 'key': 'date', 'label': 'Date', 'type': 'date', 'format': 'dd/MM/yyyy', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'total', 'label': 'Amount', 'type': 'number', 'decimalPlaces': 0, 'format': '#,##0', 'suffix': ' VND', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'purpose', 'label': 'Purpose', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                ]
              },
              'children': [
                {
                  'key': 'date',
                  'widget': 'datetime',
                  'label': 'Payment Date',
                  'datetimeType': 'date',
                  'required': true,
                  'hintText': 'Select payment date',
                },
                {
                  'key': 'total',
                  'label': 'Amount',
                  'type': 'number',
                  'suffix': ' VND',
                  'decimalPlaces': 0,
                  'required': true,
                  'hintText': 'Enter payment amount...',
                },
                {
                  'key': 'purpose',
                  'label': 'Purpose',
                  'type': 'textarea',
                  'maxLines': 3,
                  'required': true,
                  'hintText': 'Enter payment purpose...',
                },
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

  @override
  bool validateData() {
    return CoreDynamicFields.validateData(
      context: context,
      moduleData: _moduleData,
      itemDetail: _itemDetail,
    );
  }

  Map<String, dynamic> prepareDataForSave() => Map<String, dynamic>.from(_moduleData);

  @override
  Future<void> loadTabSpecificData() async {}

  Future<void> saveTabData(Map<String, dynamic> data) async { await Future.delayed(const Duration(milliseconds: 200)); }
  Future<void> submitTabData(Map<String, dynamic> data) async { await Future.delayed(const Duration(milliseconds: 200)); }
}
