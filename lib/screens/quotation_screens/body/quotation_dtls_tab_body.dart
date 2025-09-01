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
          _buildGeneralInfoSection(),
          _buildOpportunitySection(),
          _buildCustomerInfoSection(),
          _buildProductSection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.description_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'code', 'label': 'Code', 'disabled': true },
            { 'key': 'name', 'label': 'Name', 'required': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildOpportunitySection() {
    return CardSection(
      title: 'Opportunity Information',
      headerIcon: Icons.account_tree_outlined,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            // opportunityId object related selects (placeholder endpoints)
            { 'key': 'opportunityId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Opportunity', 'data': 'DROPDOWN.QUTATI/OPPORTUNITY', 'display': 'opportunityName' },
            // Owner & Leader full name (view only)
            { 'key': 'opportunityId.owner.fullName', 'label': 'Owner', 'widget': 'input', 'onlyView': true, 'disabled': true },
            { 'key': 'opportunityId.leader.fullName', 'label': 'Leader', 'widget': 'input', 'onlyView': true, 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection() {
    return CardSection(
      title: 'Customer Information',
      headerIcon: Icons.apartment_outlined,
      headerColor: Colors.green,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'opportunityId.customer.name', 'label': 'Customer Name', 'widget': 'input', 'onlyView': true, 'disabled': true },
            { 'key': 'opportunityId.customer.address', 'label': 'Address', 'widget': 'input', 'type': 'textarea', 'maxLines': 3, 'onlyView': true, 'disabled': true },
            { 'key': 'opportunityId.customer.contact', 'label': 'Contact', 'widget': 'input', 'onlyView': true, 'disabled': true },
            { 'key': 'opportunityId.customer.email', 'label': 'Email', 'widget': 'input', 'onlyView': true, 'disabled': true },
            { 'key': 'opportunityId.customer.industry.name', 'label': 'Industry', 'widget': 'input', 'onlyView': true, 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildProductSection() {
    final List<dynamic> products = (_moduleData['product'] is List) ? _moduleData['product'] as List : const [];
    return CardSection(
      title: 'Products',
      headerIcon: Icons.shopping_bag_outlined,
      headerColor: Colors.orange,
      children: [
        // Display collection of product objects (view only for now)
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'product',
              'widget': 'collection',
              'label': 'Product Items',
              'itemLabel': 'Product',
              'allowAdd': false,
              'allowRemove': false,
              'hintText': products.isEmpty ? 'No products.' : null,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'code', 'label': 'Code', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'name', 'label': 'Name', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'description', 'label': 'Description', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                ]
              },
              'children': [
                { 'key': 'code', 'disabled': true },
                { 'key': 'name', 'disabled': true },
                { 'key': 'description', 'type': 'textarea', 'maxLines': 3, 'disabled': true },
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

  Widget _buildSystemInfoSection() {
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

  Map<String, dynamic> prepareDataForSave() => Map<String, dynamic>.from(_moduleData);

  @override
  Future<void> loadTabSpecificData() async {}

  Future<void> saveTabData(Map<String, dynamic> data) async { await Future.delayed(const Duration(milliseconds: 200)); }
  Future<void> submitTabData(Map<String, dynamic> data) async { await Future.delayed(const Duration(milliseconds: 200)); }
}
