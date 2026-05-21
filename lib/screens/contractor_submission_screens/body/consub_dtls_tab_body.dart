import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/utils/keyboard_utils.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for CONSUB DTLS (Details)
class ConsubDetailsTabBody extends CoreTabBody {
  const ConsubDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ConsubDetailsTabBody> createState() =>
      _ConsubDetailsTabBodyState();
}

class _ConsubDetailsTabBodyState
    extends CoreTabBodyState<ConsubDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ConsubDetailsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _normalizeApprovalWorkflow();
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    if (mounted) setState(() {});
  }

  void _normalizeApprovalWorkflow() {
    final raw = _moduleData['approvalWorkFlow'];
    if (raw is! List) return;

    final normalized = raw.map((entry) {
      final Map<String, dynamic> item = entry is Map
          ? Map<String, dynamic>.from(entry)
          : <String, dynamic>{};
      final List<dynamic> rawPics = item['listEmployeePic'] is List
          ? List<dynamic>.from(item['listEmployeePic'])
          : const [];
      final List<Map<String, dynamic>> normalizedPics = rawPics
          .map(
            (pic) => pic is Map
                ? Map<String, dynamic>.from(pic)
                : <String, dynamic>{},
          )
          .map((pic) {
            final employeeRaw = pic['employeePic'];
            if (employeeRaw is Map) {
              final normalizedEmployee = _normalizeEmployeeMap(
                Map<String, dynamic>.from(employeeRaw),
              );
              pic['employeePic'] = normalizedEmployee;
              final display = _formatEmployeeDisplay(normalizedEmployee);
              if (display.isNotEmpty) {
                pic['employeePicDisplay'] = display;
              }
            }
            return pic;
          })
          .toList();

      item['listEmployeePic'] = normalizedPics;

      final displayList = normalizedPics
          .map(
            (pic) =>
                pic['employeePicDisplay']?.toString() ??
                _formatEmployeeDisplay(pic),
          )
          .where((value) => value.isNotEmpty)
          .join(', ');

      if (displayList.isNotEmpty) {
        item['listEmployeePicDisplay'] = displayList;
      }
      return item;
    }).toList();

    _moduleData['approvalWorkFlow'] = normalized;
  }

  Map<String, dynamic> _normalizeEmployeeMap(Map<String, dynamic> employee) {
    final normalized = Map<String, dynamic>.from(employee);
    if (normalized['fullName'] == null && normalized['fullname'] != null) {
      normalized['fullName'] = normalized['fullname'];
    }
    if (normalized['fullname'] == null && normalized['fullName'] != null) {
      normalized['fullname'] = normalized['fullName'];
    }
    return normalized;
  }

  String _formatEmployeeDisplay(dynamic value) {
    if (value is! Map) return '';
    final employee = value['employeePic'] is Map ? value['employeePic'] : value;
    if (employee is! Map) return '';

    final name =
        employee['fullname']?.toString().trim() ??
        employee['fullName']?.toString().trim() ??
        '';
    final department = employee['departmentName']?.toString().trim() ?? '';
    final role = employee['roleName']?.toString().trim() ?? '';

    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (department.isNotEmpty) parts.add(department);
    if (role.isNotEmpty) parts.add(role);

    return parts.join(' - ');
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      if (key.contains('.')) {
        _setByPath(_moduleData, key, value);
      } else {
        _moduleData[key] = value;
      }

      if (key == 'approvalWorkFlow') {
        _normalizeApprovalWorkflow();
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
  Widget buildTabContent(BuildContext context) {
    return KeyboardUtils.withKeyboardDismissal(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralInfoSection(),
            _buildDocumentInfoSection(),
            _buildSystemInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'status',
              'widget': 'status',
              'showIcon': true,
              'visibleWhen': {'key': 'id', 'operator': 'ne', 'value': null},
            },
            {'key': 'code', 'label': 'Code', 'disabled': true},
            {
              'key': 'projectId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Project',
              'hintText': 'Select project',
              'data': 'DROPDOWN.CONSUB/PROJECT',
              'display': 'name',
            },
            {
              'key': 'contractorId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Contractor',
              'hintText': 'Select contractor',
              'data': 'DROPDOWN.CONSUB/CONTRACTOR',
              'display': 'name',
            },
            // {
            //   'key': 'currentApproverId',
            //   'widget': 'select',
            //   'selectType': 'dropdown',
            //   'label': 'Current Approver',
            //   'hintText': 'Select approver',
            //   'data': 'DROPDOWN.CONSUB/USER',
            //   'display': 'fullName',
            //   'disabled': true,
            // },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildDocumentInfoSection() {
    return CardSection(
      title: 'Document Information',
      headerIcon: Icons.list_alt,
      headerColor: Colors.blueGrey,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'approvalWorkFlow',
              'widget': 'collection',
              'label': 'Approval Workflow',
              'itemLabel': 'Step',
              'allowAdd': false,
              'allowRemove': false,
              'editMode': 'modal',
              'titleTemplate': 'Step {stepOrder}',
              'summary': {
                'layout': 'row',
                'fields': [
                  {'key': 'name', 'label': 'Name', 'layout': 'row'},
                  {
                    'key': 'listEmployeePicDisplay',
                    'label': 'Employees',
                    'layout': 'row',
                  },
                ],
              },
              'children': [
                {'key': 'stepOrder', 'label': 'Flow Order', 'type': 'number'},
                {'key': 'name', 'label': 'Name'},
                {
                  'key': 'listEmployeePic',
                  'label': 'Employees',
                  'widget': 'collection',
                  'itemLabel': 'Employee',
                  'allowAdd': true,
                  'allowRemove': true,
                  'summary': {
                    'layout': 'row',
                    'fields': [
                      {
                        'key': 'employeePicDisplay',
                        'label': 'Employee',
                        'layout': 'row',
                      },
                    ],
                  },
                  'children': [
                    {
                      'key': 'employeePic',
                      'widget': 'select',
                      'selectType': 'dropdown',
                      'label': 'Employee',
                      'hintText': 'Select employee',
                      'data': 'DROPDOWN.CONSUB/USER',
                      'display': 'fullname',
                    },
                  ],
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

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
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
