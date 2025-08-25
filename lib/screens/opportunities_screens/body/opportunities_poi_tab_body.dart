import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for OPPRTU POI (Product of Interest)
class OpportunitiesPOITabBody extends CoreTabBody {
  const OpportunitiesPOITabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<OpportunitiesPOITabBody> createState() => _OpportunitiesPOITabBodyState();
}

class _OpportunitiesPOITabBodyState extends CoreTabBodyState<OpportunitiesPOITabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(OpportunitiesPOITabBody oldWidget) {
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
    
    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_response.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Field configuration for Product of Interest collection
    final List<Map<String, dynamic>> fieldConfigs = [
      {
        'key': 'productOfInterest',
        'label': 'Product of Interest',
        'widget': 'collection',
        'editMode': 'modal', // Use modal for better UX
        'itemLabel': 'Product Item',
        'addButtonText': 'Add Product',
        'allowAdd': true,
        'allowRemove': true,
        'required': false,
        'children': [
          // Product selection
          { 'key': 'product', 'label': 'Product', 'widget': 'select', 'selectType': 'dropdown', 'data': 'DROPDOWN.OPPRTU/PRODUCT', 'display': 'name', 'required': true },
          // Quantity
          { 'key': 'quantity', 'label': 'Quantity', 'widget': 'input', 'type': 'number', 'required': true },
          // Unit/Description
          { 'key': 'unit', 'label': 'Unit', 'widget': 'input', 'type': 'text', 'required': true },
        ],
        'summary': {
          'fields': [
            { 'key': 'product.name', 'label': 'Product', 'layout': 'row', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
            { 'key': 'quantity', 'label': 'Quantity', 'layout': 'row', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
            { 'key': 'unit', 'label': 'Unit', 'layout': 'row', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12' },
          ],
        },
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: CoreDynamicFields.buildFields(
          fieldConfigs: fieldConfigs,
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ),
    );
  }
}
