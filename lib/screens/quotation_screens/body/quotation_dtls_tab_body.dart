import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for QUTATI DTLS (Details)
class QuotationDetailsTabBody extends CoreTabBody {
  const QuotationDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<QuotationDetailsTabBody> createState() => _QuotationDetailsTabBodyState();
}

class _QuotationDetailsTabBodyState extends CoreTabBodyState<QuotationDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(QuotationDetailsTabBody oldWidget) {
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
      _setByPath(_moduleData, key, value);
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });

    // Defer notification to avoid calling setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  /// Set a value in a nested map using dot-notation path
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
          _buildBasicInformationSection(),
          _buildOpportunityInformationSection(),
          _buildProjectInformationSection(),
          _buildCustomerInformationSection(),
          _buildProductInterestSection(),
          _buildSystemInformationSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInformationSection() {
    return CardSection(
      title: 'Basic Information',
      headerIcon: Icons.description_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'Code', 'disabled': true },
            { 'key': 'createdDate', 'label': 'Created Date', 'widget': 'datetime', 'datetimeType': 'date', 'disabled': true },
            { 'key': 'createdBy', 'label': 'Created By', 'disabled': true },
            { 'key': 'name', 'label': 'Name', 'required': true },
            { 'key': 'approvedDate', 'widget': 'datetime', 'label': 'Approved Date', 'datetimeType': 'date' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildOpportunityInformationSection() {
    return CardSection(
      title: 'Opportunity Information',
      headerIcon: Icons.account_tree_outlined,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'ownerId',
              'label': 'Owner',
              'widget': 'select',
              'selectType': 'dropdown',
              'data': 'DROPDOWN.QUTATI/OWNER',
              'display': 'fullName',
              'required': true,
              'clearOnChange': ['opportunityId'],
            },
            { 'key': 'opportunityId.leader.fullName', 'label': 'Leader', 'widget': 'input', 'disabled': true },
            {
              'key': 'opportunityId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Opportunity',
              'data': 'DROPDOWN.QUTATI/OPPORTUNITY?ownerId={{ownerId.id}}',
              'display': 'name',
              'required': true,
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildProjectInformationSection() {
    return CardSection(
      title: 'Project Information',
      headerIcon: Icons.work_outline,
      headerColor: Colors.blue,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'opportunityId.projectManagement.icv', 'label': 'ICV', 'widget': 'input', 'disabled': true },
            { 'key': 'opportunityId.projectManagement.contractNumber', 'label': 'Contract Number', 'widget': 'input', 'disabled': true },
            { 'key': 'opportunityId.projectManagement.projectName', 'label': 'Project Name', 'widget': 'input', 'disabled': true, 'maxLines': 3 },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildCustomerInformationSection() {
    return CardSection(
      title: 'Customer Information',
      headerIcon: Icons.apartment_outlined,
      headerColor: const Color.fromARGB(255, 87, 6, 101),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'opportunityId.customer.name', 'label': 'Name', 'widget': 'input', 'disabled': true },
            { 'key': 'opportunityId.customer.address', 'label': 'Address', 'widget': 'input', 'disabled': true, 'maxLines': 3 },
            { 'key': 'opportunityId.customer.contact', 'label': 'Contact', 'widget': 'input', 'disabled': true },
            { 'key': 'opportunityId.customer.email', 'label': 'Email', 'widget': 'input', 'disabled': true },
            { 'key': 'opportunityId.customer.industry.name', 'label': 'Industry', 'widget': 'input', 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildProductInterestSection() {
    return CardSection(
      title: 'Product Interest',
      headerIcon: Icons.shopping_bag_outlined,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'product',
              'widget': 'collection',
              'label': 'Products',
              'itemLabel': 'Product',
              'addButtonText': 'Add Product',
              'hintText': 'No products added yet',
              'allowAdd': false,
              'allowRemove': false,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'name', 'label': 'Name', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'quantity', 'label': 'Quantity', 'type': 'number', 'format': '#,##0', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'unit', 'label': 'Unit', 'bgColor': '#FFF3E0', 'borderColor': '#FFCC80', 'labelColor': '#F57C00', 'valueColor': '#E65100' },
                ]
              },
              'children': [
                { 'key': 'name', 'label': 'Name', 'disabled': true },
                { 'key': 'quantity', 'label': 'Quantity', 'type': 'number', 'decimalPlaces': 0, 'disabled': true },
                { 'key': 'unit', 'label': 'Unit', 'disabled': true },
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

  Widget _buildSystemInformationSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'createdBy', 'label': 'Created By', 'disabled': true },
            { 'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'disabled': true },
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
}
