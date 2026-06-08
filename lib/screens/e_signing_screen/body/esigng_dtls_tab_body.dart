import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/utils/keyboard_utils.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for ESIGNG DTLS (Details)
class ESigningDetailsTabBody extends CoreTabBody {
  const ESigningDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ESigningDetailsTabBody> createState() =>
      _ESigningDetailsTabBodyState();
}

class _ESigningDetailsTabBodyState
    extends CoreTabBodyState<ESigningDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ESigningDetailsTabBody oldWidget) {
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
      item['stepOrder'] = _normalizeIntegerNumber(item['stepOrder']);

      final rawPics = item['listEmployeePic'] is List
          ? List<dynamic>.from(item['listEmployeePic'])
          : const <dynamic>[];
      final normalizedPics = rawPics
          .map(
            (pic) => pic is Map
                ? Map<String, dynamic>.from(pic)
                : <String, dynamic>{},
          )
          .map((pic) {
            final employeeRaw = pic['employeePic'];
            if (employeeRaw is Map) {
              final employee = _normalizeEmployeeMap(
                Map<String, dynamic>.from(employeeRaw),
              );
              pic['employeePic'] = employee;
              final display = _formatEmployeeDisplay(employee);
              if (display.isNotEmpty) pic['employeePicDisplay'] = display;
            }
            return pic;
          })
          .toList();

      item['listEmployeePic'] = normalizedPics;
      final displayList = normalizedPics
          .map((pic) => pic['employeePicDisplay']?.toString() ?? '')
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

  dynamic _normalizeIntegerNumber(dynamic value) {
    if (value is num && value % 1 == 0) return value.toInt();
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null && parsed % 1 == 0) return parsed.toInt();
    }
    return value;
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_buildSanitizedResponse());
    });
  }

  void _setByPath(Map<String, dynamic> map, String path, dynamic value) {
    final parts = path.split('.');
    Map<String, dynamic> curr = map;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isLast = i == parts.length - 1;
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

  Map<String, dynamic> _buildSanitizedResponse() {
    final sanitized = _stripUiOnlyFields(_response);
    if (sanitized is Map<String, dynamic>) return sanitized;
    if (sanitized is Map) return Map<String, dynamic>.from(sanitized);
    return Map<String, dynamic>.from(_response);
  }

  dynamic _stripUiOnlyFields(dynamic value) {
    if (value is List) return value.map(_stripUiOnlyFields).toList();
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, entryValue) {
        final keyText = key.toString();
        if (keyText == 'employeePicDisplay' ||
            keyText == 'listEmployeePicDisplay') {
          return;
        }
        final sanitizedValue = _stripUiOnlyFields(entryValue);
        sanitized[keyText] = keyText == 'stepOrder'
            ? _normalizeIntegerNumber(sanitizedValue)
            : sanitizedValue;
      });
      return sanitized;
    }
    return value;
  }

  @override
  Widget buildTabContent(BuildContext context) {
    return KeyboardUtils.withKeyboardDismissal(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSection(),
            _buildWorkflowSection(),
            _buildSystemSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.draw_outlined,
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
            {'key': 'name', 'label': 'Name', 'required': true},
            {
              'key': 'description',
              'label': 'Description',
              'type': 'textarea',
              'maxLines': 3,
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildWorkflowSection() {
    return CardSection(
      title: 'Approval Workflow',
      headerIcon: Icons.account_tree_outlined,
      headerColor: Colors.blueGrey,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {
              'key': 'approvalWorkFlow',
              'widget': 'collection',
              'label': 'Approval Workflow',
              'itemLabel': 'Step',
              'allowAdd': true,
              'allowRemove': true,
              'editMode': 'modal',
              'titleTemplate': 'Step {stepOrder}',
              'summary': {
                'layout': 'row',
                'fields': [
                  // {'key': 'stepOrder', 'label': 'Flow Order', 'layout': 'row'},
                  {'key': 'name', 'label': 'Name', 'layout': 'row'},
                  {
                    'key': 'listEmployeePicDisplay',
                    'label': 'Assignees',
                    'layout': 'row',
                  },
                ],
              },
              'children': [
                {
                  'key': 'stepOrder',
                  'label': 'Flow Order',
                  'type': 'number',
                  'decimalPlaces': 0,
                  'required': true,
                },
                {'key': 'name', 'label': 'Name', 'required': true},
                {
                  'key': 'deadline',
                  'widget': 'datetime',
                  'label': 'Deadline',
                  'datetimeType': 'datetime',
                  'displayFormat': 'ddMMyyyy',
                },
                {
                  'key': 'listEmployeePic',
                  'label': 'Assignees',
                  'widget': 'collection',
                  'itemLabel': 'Assignee',
                  'allowAdd': true,
                  'allowRemove': true,
                  'maxItems': 1,
                  'summary': {
                    'layout': 'row',
                    'fields': [
                      {
                        'key': 'employeePicDisplay',
                        'label': 'Assignee',
                        'layout': 'row',
                      },
                    ],
                  },
                  'children': [
                    {
                      'key': 'employeePic',
                      'widget': 'select',
                      'selectType': 'dropdown',
                      'label': 'Assignee',
                      'hintText': 'Select assignee',
                      'data': 'DROPDOWN.ESIGNG/USER',
                      'display': 'fullname',
                      'required': true,
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

  Widget _buildSystemSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: Colors.deepPurple,
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
