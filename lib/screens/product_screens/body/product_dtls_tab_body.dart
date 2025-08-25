import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for PRD DTLS (Details)
class ProductDetailsTabBody extends CoreTabBody {
  const ProductDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProductDetailsTabBody> createState() => _ProductDetailsTabBodyState();
}

class _ProductDetailsTabBodyState extends CoreTabBodyState<ProductDetailsTabBody> {
    Map<String, dynamic> _response = {};
    Map<String, dynamic> _itemDetail = {};
    Map<String, dynamic> _moduleData = {};

    @override
    void initState() {
      super.initState();
      _updateDataFromInitialData();
    }

    @override
    void didUpdateWidget(ProductDetailsTabBody oldWidget) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(),
          _buildProductDetailsSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInfoSection() {
    return CardSection(
      title: 'Basic Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'code', 'label': 'Code', 'disabled': true },
            { 'key': 'name', 'label': 'Name', 'required': true },
            { 'key': 'description', 'label': 'Description', 'type': 'textarea', 'maxLines': 3, 'hintText': 'Enter product description...' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildProductDetailsSection() {
    return CardSection(
      title: 'Product Details',
      headerIcon: Icons.inventory_2_outlined,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'manufacturer', 'widget': 'input', 'type': 'text', 'label': 'Manufacturer', 'hintText': 'Enter manufacturer' },
            { 'key': 'unit', 'widget': 'input', 'type': 'text', 'label': 'Unit', 'hintText': 'Enter unit' },
            { 'key': 'version', 'widget': 'input', 'type': 'text', 'label': 'Version', 'hintText': 'Enter version' },
            { 'key': 'newFeature', 'widget': 'input', 'type': 'text', 'label': 'New Feature', 'hintText': 'Enter new feature' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.settings_outlined,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'createdBy', 'label': 'Created By', 'hintText': 'Created by user', 'type': 'text' },
            { 'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Record creation date' },
            { 'key': 'updatedDate', 'widget': 'datetime', 'label': 'Updated Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Last update date' },
            { 'key': 'editId', 'label': 'Edit ID', 'type': 'number', 'hintText': 'Edit identifier' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
