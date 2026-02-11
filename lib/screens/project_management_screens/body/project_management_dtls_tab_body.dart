import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for PRJMGT DTLS (Details)
class ProjectManagementDetailsTabBody extends CoreTabBody {
  const ProjectManagementDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProjectManagementDetailsTabBody> createState() => _ProjectManagementDetailsTabBodyState();
}

class _ProjectManagementDetailsTabBodyState extends CoreTabBodyState<ProjectManagementDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ProjectManagementDetailsTabBody oldWidget) {
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
      // Handle dependent updates when opportunity changes
      if (key == 'opportunityId') {
        _setByPath(_moduleData, key, value);
        if (value is Map<String, dynamic>) {
          // Auto-fill dependent fields from selected opportunity
          _moduleData['customerId'] = value['customerId'];
          _moduleData['accountId'] = value['accountId'];
        } else if (value == null) {
          // Clear dependent fields
          _moduleData['customerId'] = null;
          _moduleData['accountId'] = null;
        }
      } else if (key.contains('.')) {
        _setByPath(_moduleData, key, value);
      } else {
        _moduleData[key] = value;
      }

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
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralProjectInfoSection(),
          _buildPersonnelInChargeSection(),
          _buildContractInformationSection(),
          _buildCustomerCoreTeamSection(),
          _buildSystemInformationSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  /// GENERAL PROJECT INFORMATION
  Widget _buildGeneralProjectInfoSection() {
    return CardSection(
      title: 'General Project Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'code', 'label': 'Code', 'disabled': true },
            { 'key': 'projectCode', 'label': 'Project Code', 'disabled': true },
            { 'key': 'name', 'label': 'Project Name', 'required': true },
            { 'key': 'listProducts', 'widget': 'select', 'selectType': 'multiple', 'label': 'Solution Name', 'required': true, 'data': 'DROPDOWN.PRJMGT/PRODUCT', 'display': 'name' },
            { 'key': 'location', 'label': 'Location' },
            { 'key': 'implementation', 'label': 'Implementation' },
            { 'key': 'projectTypeId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Type', 'required': true, 'data': 'DROPDOWN.PRJMGT/PROJECTTYPE', 'display': 'name' },
            { 'key': 'departmentId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Department', 'required': true, 'data': 'DROPDOWN.PRJMGT/DEPARTMENT', 'display': 'name' },
            { 'key': 'completedPercent', 'label': 'Percentage of Completeness', 'type': 'number', 'suffix': '%', 'decimalPlaces': 2 },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  /// PERSONNEL IN CHARGE
  Widget _buildPersonnelInChargeSection() {
    return CardSection(
      title: 'Personnel In Charge',
      headerIcon: Icons.people_outline,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'pmUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Manager', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=PROJECT_MANAGER', 'display': 'fullName' },
            { 'key': 'accountId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Account Manager', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=ACCOUNT_MANAGER', 'display': 'fullName', 'disabled': _moduleData['opportunityId'] != null },
            { 'key': 'authorizedToId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Authorized To', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName' },
            { 'key': 'adminUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Admin', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName' },
            { 'key': 'accountantUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Accountant', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=PROJECT_ACCOUNTANT', 'display': 'fullName' },
            { 'key': 'projectSecretaryId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Secretary', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName' },
            { 'key': 'projectCoordinatorId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Coordinator', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  /// CONTRACT INFORMATION
  Widget _buildContractInformationSection() {
    return CardSection(
      title: 'Contract Information',
      headerIcon: Icons.assignment_outlined,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'opportunityId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Opportunity', 'data': 'DROPDOWN.PRJMGT/OPPORTUNITIES', 'display': 'name', 'clearOnChange': ['customerId', 'accountId'], 'moreDisplay': [{'label': 'Customer', 'key': 'customerId.name'}, {'label': 'Owner', 'key': 'accountId.fullName'}] },
            { 'key': 'icv', 'label': 'ICV' },
            { 'key': 'contractNumber', 'label': 'Contract Number', 'required': true },
            { 'key': 'customerId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Customer Name', 'data': 'DROPDOWN.PRJMGT/CUSTOMER', 'display': 'name', 'disabled': _moduleData['opportunityId'] != null, 'required': true },
            { 'key': 'contractStartDate', 'widget': 'datetime', 'label': 'Contract Start Date - Contract End Date', 'datetimeType': 'daterange', 'startDateKey': 'contractStartDate', 'endDateKey': 'contractEndDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select contract duration...', 'required': true },
            { 'key': 'maintStartDate', 'widget': 'datetime', 'label': 'Maint. Start Date - Maint. End Date', 'datetimeType': 'daterange', 'startDateKey': 'maintStartDate', 'endDateKey': 'maintEndDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select maintenance duration...' },
            { 'key': 'isEndProjectByMaint', 'widget': 'checkbox', 'checkboxStyle': 'switch', 'label': 'End Project at Maintenance Completion' },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  /// CUSTOMER'S CORE TEAM
  Widget _buildCustomerCoreTeamSection() {
    return CardSection(
      title: "Customer's Core Team",
      headerIcon: Icons.groups_outlined,
      headerColor: const Color.fromARGB(255, 17, 130, 73),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'projectCustomerCoreTeam',
              'widget': 'collection',
              'label': "Customer's Core Team",
              'itemLabel': 'Team Member',
              'addButtonText': 'Add Root Item',
              'hintText': 'No team member added yet. Click Add to create one.',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'summary': {
                'fields': [
                  { 'key': 'itemNo', 'label': 'Item No', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1565C0', 'valueColor': '#0D47A1' },
                  { 'key': 'fullName', 'label': 'Full Name', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'roleTitle', 'label': 'Role/Title', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'phone', 'label': 'Phone', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'email', 'label': 'Email', 'bgColor': '#E8F5E8', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20' },
                  { 'key': 'note', 'label': 'Note', 'bgColor': '#FFF4E6', 'borderColor': '#FFCC99', 'labelColor': '#C15700', 'valueColor': '#A14400' },
                ],
              },
              'children': [
                { 'key': 'itemNo', 'label': 'Item No', 'type': 'text' },
                { 'key': 'fullName', 'label': 'Full Name', 'type': 'text', 'required': true },
                { 'key': 'roleTitle', 'label': 'Role/Title', 'type': 'text' },
                { 'key': 'phone', 'label': 'Phone', 'type': 'text' },
                { 'key': 'email', 'label': 'Email', 'type': 'text' },
                { 'key': 'note', 'label': 'Note', 'type': 'textarea', 'maxLines': 3 },
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

  /// SYSTEM INFORMATION
  Widget _buildSystemInformationSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'createdBy', 'label': 'Created By', 'type': 'text', 'disabled': true },
            { 'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'disabled': true },
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
