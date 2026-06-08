import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for USER MBS (Membership)
class UserMembershipTabBody extends CoreTabBody {
  const UserMembershipTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<UserMembershipTabBody> createState() =>
      _UserMembershipTabBodyState();
}

class _UserMembershipTabBodyState
    extends CoreTabBodyState<UserMembershipTabBody> {
  static const String _membershipDropdownEndpoint = 'DROPDOWN.MBS.ORGANIZATION';
  static const String _roleDropdownEndpoint = 'DROPDOWN.MBS.ROLE';

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  List<Map<String, dynamic>> _membershipDropdown = [];

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadMembershipDropdown();
    });
  }

  @override
  void didUpdateWidget(UserMembershipTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _normalizeMembershipDisplay();
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _moduleData[key] = value;
      if (key == 'membership') {
        _normalizeMembershipDisplay();
      }
      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_buildSanitizedResponse());
    });
  }

  Future<void> _loadMembershipDropdown() async {
    final response = await CoreService.instance.getDropdownData(
      _membershipDropdownEndpoint,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      final List<dynamic> rawOptions = data is List
          ? data
          : data == null
          ? const <dynamic>[]
          : <dynamic>[data];

      setState(() {
        _membershipDropdown = rawOptions
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      });
      return;
    }

    if (response['statusCode'] == 401) {
      await SessionHandler.handleSessionExpired(context);
    }
  }

  void _normalizeMembershipDisplay() {
    final raw = _moduleData['membership'];
    if (raw is! List) return;

    final normalized = raw.map((entry) {
      final Map<String, dynamic> membership = entry is Map
          ? Map<String, dynamic>.from(entry)
          : <String, dynamic>{};

      final rawMembers = membership['member'] is List
          ? List<dynamic>.from(membership['member'])
          : const <dynamic>[];
      final members = rawMembers.map((entry) {
        final member = entry is Map
            ? Map<String, dynamic>.from(entry)
            : <String, dynamic>{};
        final display = _formatMemberPair(member);
        if (display.isNotEmpty) {
          member['memberPairDisplay'] = display;
        }
        return member;
      }).toList();

      membership['member'] = members;
      final display = members
          .map((member) => member['memberPairDisplay']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .join('\n');
      if (display.isNotEmpty) {
        membership['membershipMembersDisplay'] = display;
      }

      return membership;
    }).toList();

    _moduleData['membership'] = normalized;
  }

  String _formatMemberPair(Map<String, dynamic> member) {
    final department = _displayName(member['departmentId']);
    final role = _displayName(member['roleId']);
    final group = _displayName(member['departmentGroupId']);

    final left = group.isNotEmpty ? '$department / $group' : department;
    if (left.isNotEmpty && role.isNotEmpty) return '$left - $role';
    if (left.isNotEmpty) return left;
    return role;
  }

  String _displayName(dynamic value) {
    if (value is Map) {
      return (value['name'] ?? value['fullName'] ?? value['code'] ?? '')
          .toString()
          .trim();
    }
    return value?.toString().trim() ?? '';
  }

  String _displayId(dynamic value) {
    if (value is Map) {
      return (value['id'] ?? value['code'] ?? '').toString().trim();
    }
    return value?.toString().trim() ?? '';
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<Map<String, dynamic>> _organizationOptions() {
    final seen = <String>{};
    final options = <Map<String, dynamic>>[];

    for (final node in _membershipDropdown) {
      final organization = _asMap(node['organizationId']) ?? node;
      final option = _compactOption(
        organization,
        fallbackId: node['id'],
        fallbackName: node['name'],
      );
      final key = _optionKey(option);
      if (key.isNotEmpty && seen.add(key)) {
        options.add(option);
      }
    }

    return options;
  }

  List<Map<String, dynamic>> _departmentOptionsForContext(
    Map<String, dynamic> context,
  ) {
    final node = _membershipNodeForContext(context);
    return _departmentOptions(node?['departmentId']);
  }

  List<Map<String, dynamic>> _groupOptionsForContext(
    Map<String, dynamic> context,
  ) {
    final department = _departmentNodeForContext(context);
    return _compactOptions(department?['groupId']);
  }

  Map<String, dynamic>? _membershipNodeForContext(
    Map<String, dynamic> context,
  ) {
    final selected = context['organizationId'];
    final selectedId = _displayId(selected);
    final selectedName = _displayName(selected);

    for (final node in _membershipDropdown) {
      final organization = _asMap(node['organizationId']) ?? node;
      final nodeId = _displayId(organization);
      final nodeName = _displayName(organization);

      if (selectedId.isNotEmpty && selectedId == nodeId) return node;
      if (selectedName.isNotEmpty && selectedName == nodeName) return node;
    }

    return null;
  }

  Map<String, dynamic>? _membershipNodeForSelection(dynamic selected) {
    final selectedId = _displayId(selected);
    final selectedName = _displayName(selected);

    for (final node in _membershipDropdown) {
      final organization = _asMap(node['organizationId']) ?? node;
      final nodeId = _displayId(organization);
      final nodeName = _displayName(organization);

      if (selectedId.isNotEmpty && selectedId == nodeId) return node;
      if (selectedName.isNotEmpty && selectedName == nodeName) return node;
    }

    return null;
  }

  Map<String, dynamic>? _departmentNodeForSelection(
    dynamic organization,
    dynamic department,
  ) {
    final node = _membershipNodeForSelection(organization);
    final departments = node?['departmentId'];
    if (departments is! List) return null;

    final selectedId = _displayId(department);
    final selectedName = _displayName(department);

    for (final entry in departments) {
      if (entry is! Map) continue;
      final departmentNode = Map<String, dynamic>.from(entry);
      final departmentId = _displayId(departmentNode);
      final departmentName = _displayName(departmentNode);

      if (selectedId.isNotEmpty && selectedId == departmentId) {
        return departmentNode;
      }
      if (selectedName.isNotEmpty && selectedName == departmentName) {
        return departmentNode;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _departmentOptions(dynamic rawOptions) {
    if (rawOptions is! List) return const <Map<String, dynamic>>[];

    final seen = <String>{};
    final options = <Map<String, dynamic>>[];
    for (final raw in rawOptions) {
      if (raw is! Map) continue;
      final option = Map<String, dynamic>.from(raw);
      final key = _optionKey(option);
      if (key.isNotEmpty && seen.add(key)) {
        options.add(option);
      }
    }
    return options;
  }

  Map<String, dynamic>? _departmentNodeForContext(
    Map<String, dynamic> context,
  ) {
    final node = _membershipNodeForContext(context);
    final departments = node?['departmentId'];
    if (departments is! List) return null;

    final selected = context['departmentId'];
    final selectedId = _displayId(selected);
    final selectedName = _displayName(selected);

    for (final entry in departments) {
      if (entry is! Map) continue;
      final department = Map<String, dynamic>.from(entry);
      final departmentId = _displayId(department);
      final departmentName = _displayName(department);

      if (selectedId.isNotEmpty && selectedId == departmentId) {
        return department;
      }
      if (selectedName.isNotEmpty && selectedName == departmentName) {
        return department;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _compactOptions(dynamic rawOptions) {
    if (rawOptions is! List) return const <Map<String, dynamic>>[];

    final seen = <String>{};
    final options = <Map<String, dynamic>>[];
    for (final raw in rawOptions) {
      final option = _compactOption(raw);
      final key = _optionKey(option);
      if (key.isNotEmpty && seen.add(key)) {
        options.add(option);
      }
    }
    return options;
  }

  Map<String, dynamic> _compactOption(
    dynamic raw, {
    dynamic fallbackId,
    dynamic fallbackName,
  }) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return {
        'id': map['id'] ?? fallbackId,
        'name':
            map['name'] ??
            map['fullName'] ??
            map['label'] ??
            map['code'] ??
            fallbackName,
      };
    }

    return {
      'id': fallbackId ?? raw,
      'name': fallbackName ?? raw?.toString() ?? '',
    };
  }

  String _optionKey(Map<String, dynamic> option) {
    final id = option['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    return option['name']?.toString().trim() ?? '';
  }

  Map<String, dynamic> _buildSanitizedResponse() {
    final sanitized = _stripUiOnlyFields(_response);
    final response = sanitized is Map<String, dynamic>
        ? sanitized
        : sanitized is Map
        ? Map<String, dynamic>.from(sanitized)
        : Map<String, dynamic>.from(_response);

    _applyMembershipPayloadShape(response);
    return response;
  }

  dynamic _stripUiOnlyFields(dynamic value) {
    if (value is List) return value.map(_stripUiOnlyFields).toList();
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, entryValue) {
        final keyText = key.toString();
        if (keyText == 'memberPairDisplay' ||
            keyText == 'membershipMembersDisplay') {
          return;
        }
        sanitized[keyText] = _stripUiOnlyFields(entryValue);
      });
      return sanitized;
    }
    return value;
  }

  void _applyMembershipPayloadShape(Map<String, dynamic> response) {
    final itemDetail = response['itemDetail'];
    if (itemDetail is! Map) return;

    final itemDetailMap = Map<String, dynamic>.from(itemDetail);
    final value = itemDetailMap['value'];
    if (value is! Map) return;

    final valueMap = Map<String, dynamic>.from(value);
    final membership = _shapeMembershipForPayload(
      valueMap['membership'],
      fallbackUserId: _displayId(valueMap['id']),
    );

    valueMap['membership'] = membership;
    valueMap['membershipConvert'] = _buildMembershipConvert(membership);
    itemDetailMap['value'] = valueMap;
    response['itemDetail'] = itemDetailMap;
  }

  List<Map<String, dynamic>> _shapeMembershipForPayload(
    dynamic rawMembership, {
    String? fallbackUserId,
  }) {
    if (rawMembership is! List) return const <Map<String, dynamic>>[];

    return rawMembership.map((entry) {
      final membership = entry is Map
          ? Map<String, dynamic>.from(entry)
          : <String, dynamic>{};

      final organization = _compactSelection(membership['organizationId']);
      final userId = membership['userId']?.toString().trim().isNotEmpty == true
          ? membership['userId']
          : fallbackUserId;

      final rawMembers = membership['member'] is List
          ? List<dynamic>.from(membership['member'])
          : const <dynamic>[];

      final members = rawMembers.map((entry) {
        final member = entry is Map
            ? Map<String, dynamic>.from(entry)
            : <String, dynamic>{};

        member['id'] = _normalizeNullableValue(member['id']);
        if (organization != null) {
          member['organizationId'] = organization;
        }

        member['roleId'] = _compactSelection(member['roleId']);
        member['departmentId'] = _departmentPayload(
          member['departmentId'],
          organization,
        );
        member['departmentGroupId'] = _compactSelection(
          member['departmentGroupId'],
        );
        member.remove('memberPairDisplay');

        return member;
      }).toList();

      membership['organizationId'] = organization;
      if (userId != null && userId.toString().trim().isNotEmpty) {
        membership['userId'] = userId;
      }
      membership['member'] = members;
      membership.remove('membershipMembersDisplay');

      return membership;
    }).toList();
  }

  List<Map<String, dynamic>> _buildMembershipConvert(
    List<Map<String, dynamic>> membership,
  ) {
    final rows = <Map<String, dynamic>>[];

    for (final item in membership) {
      final organization = item['organizationId'];
      final members = item['member'];
      if (members is! List) continue;

      for (final entry in members) {
        if (entry is! Map) continue;
        final member = Map<String, dynamic>.from(entry);
        rows.add({
          'organizationId': member['organizationId'] ?? organization,
          'id': _normalizeNullableValue(member['id']),
          'departmentId': member['departmentId'],
          'departmentGroupId': member['departmentGroupId'],
          'roleId': member['roleId'],
        });
      }
    }

    return rows;
  }

  Map<String, dynamic>? _departmentPayload(
    dynamic selectedDepartment,
    dynamic selectedOrganization,
  ) {
    final department =
        _departmentNodeForSelection(selectedOrganization, selectedDepartment) ??
        _asMap(selectedDepartment);
    if (department == null) return null;

    final payload = _compactSelection(department);
    if (payload == null) return null;

    final groups = _compactOptions(department['groupId']);
    if (groups.isNotEmpty) {
      payload['groupId'] = groups;
    } else if (department.containsKey('groupId') &&
        department['groupId'] == null) {
      payload['groupId'] = null;
    }

    return payload;
  }

  Map<String, dynamic>? _compactSelection(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final id = map['id'];
      final name =
          map['name'] ?? map['fullName'] ?? map['label'] ?? map['code'];
      final hasId = id != null && id.toString().trim().isNotEmpty;
      final hasName = name != null && name.toString().trim().isNotEmpty;

      if (!hasId && !hasName) return null;
      return {'id': id, 'name': name};
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return {'id': value, 'name': text};
  }

  dynamic _normalizeNullableValue(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  @override
  Widget buildTabContent(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...CoreDynamicFields.buildFields(
              fieldConfigs: [_membershipConfig()],
              itemDetail: _itemDetail,
              moduleData: _moduleData,
              onChanged: _onChanged,
            ),
          ],
        ),
      ).dismissKeyboardOnTap(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Map<String, dynamic> _membershipConfig() {
    return {
      'key': 'membership',
      'widget': 'collection',
      'label': 'Membership',
      'itemLabel': 'Organization',
      'addButtonText': 'Add Membership',
      'hintText': 'No membership available',
      'allowAdd': true,
      'allowRemove': true,
      'editMode': 'modal',
      'useFloatingAddButton': true,
      'useAddFirstList': true,
      'titleTemplate': '{organizationId.name}',
      'summary': {
        'layout': 'row',
        'fields': [
          {
            'key': 'organizationId.name',
            'label': 'Organization',
            'layout': 'row',
          },
          {
            'key': 'membershipMembersDisplay',
            'label': 'Members',
            'layout': 'row',
          },
        ],
      },
      'children': [
        {
          'key': 'organizationId',
          'widget': 'select',
          'selectType': 'dropdown',
          'label': 'Organization',
          'data': (_) => _organizationOptions(),
          'display': 'name',
          'required': true,
          'clearOnChange': ['member'],
        },
        {
          'key': 'member',
          'widget': 'collection',
          'label': 'Members',
          'itemLabel': 'Member',
          'allowAdd': true,
          'allowRemove': true,
          'editMode': 'modal',
          'titleTemplate': '{memberPairDisplay}',
          'summary': {
            'layout': 'row',
            'fields': [
              // {'key': 'memberPairDisplay', 'label': 'Member', 'layout': 'row'},
              {'key': 'roleId.name', 'label': 'Role', 'layout': 'row'},
              {
                'key': 'departmentId.name',
                'label': 'Department',
                'layout': 'row',
              },
              {
                'key': 'departmentGroupId.name',
                'label': 'Group',
                'layout': 'row',
              },
            ],
          },
          'children': [
            {
              'key': 'roleId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Role',
              'data': _roleDropdownEndpoint,
              'display': 'name',
              'required': true,
            },
            {
              'key': 'departmentId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Department',
              'data': _departmentOptionsForContext,
              'display': 'name',
              'required': true,
              'clearOnChange': ['departmentGroupId'],
            },
            {
              'key': 'departmentGroupId',
              'widget': 'select',
              'selectType': 'dropdown',
              'label': 'Department Group',
              'data': _groupOptionsForContext,
              'display': 'name',
            },
          ],
        },
      ],
    };
  }

  Widget? _buildFloatingActionButton() {
    return FloatingAddButton(
      onPressed: () {
        setState(() {
          if (_moduleData['membership'] is! List) {
            _moduleData['membership'] = [];
          }
          final list = _moduleData['membership'] as List;
          list.insert(0, <String, dynamic>{});
          _normalizeMembershipDisplay();
          _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
          _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.onDataChanged?.call(_buildSanitizedResponse());
        });
      },
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
