import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for USER DTLS (Details)
class UserDetailsTabBody extends CoreTabBody {
  const UserDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<UserDetailsTabBody> createState() =>
      _UserDetailsTabBodyState();
}

class _UserDetailsTabBodyState extends CoreTabBodyState<UserDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(UserDetailsTabBody oldWidget) {
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
          _buildGenericInformationSection(),
          _buildJobInformationSection(),
          _buildAnnualLeaveEntitlementSection(),
          _buildSystemSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGenericInformationSection() {
    return CardSection(
      title: 'Generic Information',
      headerIcon: Icons.badge_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'code', 'label': 'Employee Code', 'required': true},
            {
              'key': 'directManagerId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Manager',
              'data': 'DROPDOWN.RESOURCE/USER',
              'display': 'fullName',
              'required': true,
            },
            {'key': 'firstName', 'label': 'First Name', 'required': true},
            {'key': 'lastName', 'label': 'Last Name', 'required': true},
            {'key': 'fullName', 'label': 'Full Name', 'required': true},
            {
              'key': 'personalEmail',
              'label': 'Personal Email',
              'type': 'email',
            },
            {'key': 'phone', 'label': 'Phone Number'},
            {
              'key': 'dob',
              'widget': 'datetime',
              'label': 'Date of Birth',
              'datetimeType': 'date',
              'displayFormat': 'ddMMyyyy',
            },
            {
              'key': 'email',
              'label': 'Company Email',
              'type': 'email',
              'required': true,
            },
            {'key': 'passportNo', 'label': 'Passport No.'},
            {
              'key': 'passportExpiryDate',
              'widget': 'datetime',
              'label': 'Passport Expiry Date',
              'datetimeType': 'date',
              'displayFormat': 'ddMMyyyy',
            },
            {'key': 'isActive', 'label': 'Active', 'widget': 'checkbox'},
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildJobInformationSection() {
    return CardSection(
      title: 'Job Information',
      headerIcon: Icons.work_outline,
      headerColor: Colors.blueGrey,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'workplaceId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Work Location',
              'data': 'DROPDOWN.USER/WORKPLACE',
              'display': 'name',
            },
            {
              'key': 'workTypeId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Work Type',
              'data': 'DROPDOWN.USER/WORK_TYPE',
              'display': 'name',
            },
            {
              'key': 'contractTypedId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Contract Type',
              'data': 'DROPDOWN.USER/CONTRACT_TYPE',
              'display': 'name',
            },
            {'key': 'position', 'label': 'Position'},
            {
              'key': 'hireDate',
              'widget': 'datetime',
              'label': 'Hire Date',
              'datetimeType': 'date',
              'displayFormat': 'ddMMyyyy',
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildAnnualLeaveEntitlementSection() {
    return CardSection(
      title: 'Annual Leave Entitlement',
      headerIcon: Icons.event_available_outlined,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'totalAnnualLeave',
              'label': 'Total Annual Leave',
              'type': 'number',
              'disabled': true,
            },
            {
              'key': 'totalLeaveApplied',
              'label': 'Total Leave Applied',
              'type': 'number',
              'disabled': true,
            },
            {
              'key': 'totalRemainLeave',
              'label': 'Total Remain Leave',
              'type': 'number',
              'disabled': true,
            },
            {
              'key': 'currentMonthAddAnnualLeave',
              'label': 'Additional Leave This Month',
              'type': 'number',
              'disabled': true,
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildSystemSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.orange,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            // {'key': 'id', 'label': 'ID', 'disabled': true},
            {'key': 'createdBy', 'label': 'Created By', 'disabled': true},
            {
              'key': 'createdDate',
              'widget': 'datetime',
              'label': 'Created Date',
              'datetimeType': 'datetime',
              'displayFormat': 'ddMMyyyy',
              'disabled': true,
            },
            {'key': 'updatedBy', 'label': 'Updated By', 'disabled': true},
            {
              'key': 'updatedDate',
              'widget': 'datetime',
              'label': 'Updated Date',
              'datetimeType': 'datetime',
              'displayFormat': 'ddMMyyyy',
              'disabled': true,
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
}
