import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for OPPRTU DTLS (Details)
class OpportunitiesDetailsTabBody extends CoreTabBody {
  const OpportunitiesDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<OpportunitiesDetailsTabBody> createState() => _OpportunitiesDetailsTabBodyState();
}

class _OpportunitiesDetailsTabBodyState extends CoreTabBodyState<OpportunitiesDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(OpportunitiesDetailsTabBody oldWidget) {
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
          _buildBasicInformationSection(),
          _buildCustomerInformationSection(),
          _buildSystemInformationSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInformationSection() {
    return CardSection(
      title: 'General Opportunity Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'code', 'label': 'Code', 'widget': 'input', 'type': 'text', 'disabled': true },
            { 'key': 'opportunityName', 'label': 'Opportunity Name', 'widget': 'input', 'type': 'text' },
            { 'key': 'ownerId', 'label': 'Owner', 'widget': 'select', 'selectType': 'dropdown', 'data': 'DROPDOWN.OPPRTU/USER_SALE_DEPARTMENT', 'display': 'fullName', 'required': true },
            { 'key': 'leaderId', 'label': 'Leader', 'widget': 'select', 'selectType': 'dropdown', 'data': 'DROPDOWN.OPPRTU/USER_SALE_DEPARTMENT', 'display': 'fullName' },
            { 'key': 'saleStageId', 'label': 'Sale Stage', 'widget': 'select', 'selectType': 'dropdown', 'data': 'DROPDOWN.OPPRTU/SALE_STAGE', 'display': 'name' },
            { 'key': 'estimatedAmount', 'label': 'Estimated Amount', 'widget': 'input', 'type': 'number', 'suffix': 'VND', 'decimalPlaces': 0 },
            { 'key': 'closeDate', 'label': 'Close Date', 'widget': 'datetime', 'datetimeType': 'date' },  
            {'key': 'moveToNextYear', 'widget': 'checkbox', 'label': 'Move To Next Year', 'checkboxStyle': 'switch'},
            {'key': 'inPlan', 'widget': 'checkbox', 'label': 'In Plan', 'checkboxStyle': 'switch'},
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
      headerIcon: Icons.person_search,
      headerColor: const Color.fromARGB(255, 87, 6, 101),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'customerId',
              'label': 'Customer',
              'widget': 'select',
              'selectType': 'dropdown',
              'data': 'DROPDOWN.OPPRTU/CUSTOMER',
              'display': 'name',
              'moreDisplay': [
                {'label': 'Address', 'key': 'address'},
                {'label': 'Industry', 'key': 'industryName'},
              ],
            },
            // Display nested customer fields as read-only inputs
            { 'key': 'customerId.address', 'label': 'Address', 'widget': 'input', 'type': 'text', 'disabled': true, 'maxLines': 3 },
            { 'key': 'customerId.industryName', 'label': 'Industry', 'widget': 'input', 'type': 'text', 'disabled': true,  },
            { 'key': 'contactName', 'label': 'Contact Name', 'widget': 'input', 'type': 'text' },
            { 'key': 'phoneContact', 'label': 'Phone Contact', 'widget': 'input', 'type': 'phone' },
            { 'key': 'email', 'label': 'Email', 'widget': 'input', 'type': 'email' },
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
            { 'key': 'createdBy', 'label': 'Created By', 'widget': 'input', 'type': 'text', 'disabled': true },
            { 'key': 'createdDate', 'label': 'Created Date', 'widget': 'datetime', 'datetimeType': 'datetime', 'disabled': true },
            { 'key': 'updatedDate', 'label': 'Last Updated Date', 'widget': 'datetime', 'datetimeType': 'datetime', 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
