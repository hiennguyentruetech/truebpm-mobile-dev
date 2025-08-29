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
        _moduleData[key] = value;
        if (value is Map<String, dynamic>) {
          // Auto-fill and lock dependent fields
          _moduleData['customerId'] = value['customerId'];
          _moduleData['accountId'] = value['accountId'];
        } else if (value == null) {
          // Clear and unlock dependent fields
          _moduleData['customerId'] = null;
          _moduleData['accountId'] = null;
        }
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
          _buildBasicInformationSection(),
          _buildPersonnelInChargeSection(),
          _buildContractInformationSection(),
          _buildSystemInformationSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildBasicInformationSection() {
    return CardSection(
      title: 'General Project Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'code', 'label': 'Code', 'disabled': true},
            { 'key': 'projectCode', 'label': 'Project Code', 'disabled': true },
            { 'key': 'name', 'label': 'Project Name', 'required': true },
            { 'key': 'listProducts', 'widget': 'select', 'selectType': 'multiple', 'label': 'Solution Name', 'required': true, 'data': 'DROPDOWN.PRJMGT/PRODUCT', 'display': 'name'},
            { 'key': 'location', 'label': 'Location' },
            { 'key': 'implementation', 'label': 'Implementation' },
            { 'key': 'projectTypeId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Type', 'required': true, 'data': 'DROPDOWN.PRJMGT/PROJECTTYPE', 'display': 'name'},
            { 'key': 'departmentId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Department', 'required': true, 'data': 'DROPDOWN.PRJMGT/DEPARTMENT', 'display': 'name'},
            { 'key': 'completedPercent', 'label': 'Percentage of Completeness', 'type': 'number', 'suffix': '%', 'disabled': true, 'decimalPlaces': 2 },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildPersonnelInChargeSection() {
    return CardSection(
      title: 'Personnel in charge',
      headerIcon: Icons.people_outline,
      headerColor: Colors.deepPurple,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'adminUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Admin', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName'},
            {'key': 'pmUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Manager', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=PROJECT_MANAGER', 'display': 'fullName'},
            {'key': 'accountId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Account Manager', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=ACCOUNT_MANAGER', 'display': 'fullName', 'disabled': _moduleData['opportunityId'] != null},
            {'key': 'authorizedToId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Authorized To', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName'},
            {'key': 'accountantUserId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Accountant', 'required': true, 'data': 'DROPDOWN.PRJMGT/USER?PERMISSION=PROJECT_ACCOUNTANT', 'display': 'fullName'},
            {'key': 'projectSecretaryId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Secretary', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName'},
            {'key': 'projectCoordinatorId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Project Coordinator', 'data': 'DROPDOWN.PRJMGT/USER', 'display': 'fullName'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildContractInformationSection() {
    return CardSection(
      title: 'Contract information',
      headerIcon: Icons.assignment_outlined,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'opportunityId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Opportunity', 'data': 'DROPDOWN.PRJMGT/OPPORTUNITIES', 'display': 'name', 'moreDisplay': [{'label': 'Customer', 'key': 'customerId.name'}, {'label': 'Owner', 'key': 'accountId.fullName'}]},
            {'key': 'icv', 'label': 'ICV'},
            {'key': 'contractNumber', 'label': 'Contract Number', 'required': true},
            {'key': 'customerId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Customer', 'data': 'DROPDOWN.PRJMGT/CUSTOMER', 'display': 'name', 'disabled': _moduleData['opportunityId'] != null, 'required': true},
            {'key': 'contractStartDate', 'widget': 'datetime', 'label': 'Contract Start Date - End Date', 'datetimeType': 'daterange', 'startDateKey': 'contractStartDate', 'endDateKey': 'contractEndDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select contract duration...', 'required': true},
            {'key': 'maintStartDate', 'widget': 'datetime', 'label': 'Maintenance Start Date - End Date', 'datetimeType': 'daterange', 'startDateKey': 'maintStartDate', 'endDateKey': 'maintEndDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select maintenance duration...'},
            {'key': 'isEndProjectByMaint', 'widget': 'checkbox', 'checkboxStyle': 'switch', 'label': 'End Project By Maintenance'},
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
            {'key': 'createdBy', 'label': 'Created By', 'hintText': 'Created by user', 'type': 'text', 'disabled': true},
            {'key': 'createdDate', 'widget': 'datetime', 'label': 'Created Date', 'datetimeType': 'datetime', 'displayFormat': 'ddMMyyyy', 'hintText': 'Record creation date', 'disabled': true},
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

  // Prepare data for save/submit
  Map<String, dynamic> prepareDataForSave() {
    return Map<String, dynamic>.from(_moduleData);
  }

  @override
  Future<void> loadTabSpecificData() async {
    // No-op, data provided by provider initialData
  }

  Future<void> saveTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> submitTabData(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
