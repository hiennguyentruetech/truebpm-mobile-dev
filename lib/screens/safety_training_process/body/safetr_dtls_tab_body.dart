import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/keyboard_utils.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for SAFETR DTLS (Details)
class SafetrDetailsTabBody extends CoreTabBody {
  const SafetrDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<SafetrDetailsTabBody> createState() =>
      _SafetrDetailsTabBodyState();
}

class _SafetrDetailsTabBodyState
    extends CoreTabBodyState<SafetrDetailsTabBody> {
  static const Color _attendanceLabelBgColor = Color(0xFFEAF4FF);
  static const Color _attendanceBorderColor = Color(0xFFD1E7FF);

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  final List<Map<String, dynamic>> _attendanceRows = [];
  bool _attendanceLoading = false;
  String? _attendanceError;
  int _attendanceRequestSerial = 0;

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(SafetrDetailsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    if (mounted) setState(() {});
    _loadAttendanceRows();
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      if (key.contains('.')) {
        _setByPath(_moduleData, key, value);
      } else {
        _moduleData[key] = value;
      }

      _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });

    if (key == 'contractorSubmissionId') {
      _loadAttendanceRows();
    }

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

  Future<void> _loadAttendanceRows() async {
    final requestSerial = ++_attendanceRequestSerial;
    final selectedSubmissionIds = _extractSelectedSubmissionIds();
    if (selectedSubmissionIds.isEmpty) {
      if (mounted) {
        setState(() {
          _attendanceRows.clear();
          _attendanceError = null;
          _attendanceLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _attendanceLoading = true;
        _attendanceError = null;
      });
    }

    final ids = await _resolveAttendanceContractorIds(selectedSubmissionIds);
    if (!mounted || requestSerial != _attendanceRequestSerial) return;

    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _attendanceRows.clear();
          _attendanceError = null;
          _attendanceLoading = false;
        });
      }
      return;
    }

    final encodedIds = Uri.encodeQueryComponent(ids.join(','));
    final endpoint = 'DROPDOWN.SAFETR/CONTRACTOR_EMPLOYEE?ids=$encodedIds';
    final response = await CoreService.instance.getDropdownData(endpoint);

    if (!mounted || requestSerial != _attendanceRequestSerial) return;

    if (response['success'] == true) {
      final rows = _normalizeAttendanceRows(response['data']);
      setState(() {
        _attendanceRows
          ..clear()
          ..addAll(rows);
        _attendanceLoading = false;
      });
    } else {
      setState(() {
        _attendanceRows.clear();
        _attendanceLoading = false;
        _attendanceError = response['message']?.toString();
      });
    }
  }

  Future<List<String>> _resolveAttendanceContractorIds(
    List<String> selectedSubmissionIds,
  ) async {
    final directIds = _extractContractorIds(allowFallback: false);
    if (directIds.isNotEmpty) return directIds;

    final response = await CoreService.instance.getDropdownData(
      _contractSubmissionEndpoint(),
    );
    if (response['success'] != true) return selectedSubmissionIds;

    final selectedIdSet = selectedSubmissionIds.toSet();
    final options = _normalizeDropdownOptions(response['data']);
    final ids = <String>{};
    for (final option in options) {
      final optionId = _extractId(option['id']);
      if (optionId != null && selectedIdSet.contains(optionId)) {
        _collectContractorIds(option, ids, allowFallback: false);
      }
    }

    return ids.isNotEmpty ? ids.toList() : selectedSubmissionIds;
  }

  List<Map<String, dynamic>> _normalizeAttendanceRows(dynamic data) {
    final rows = _normalizeDropdownOptions(data);
    rows.sort((a, b) {
      final aOrder = int.tryParse(a['sortOrder']?.toString() ?? '') ?? 0;
      final bOrder = int.tryParse(b['sortOrder']?.toString() ?? '') ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return rows;
  }

  List<Map<String, dynamic>> _normalizeDropdownOptions(dynamic data) {
    dynamic rawRows = data;
    if (data is Map) {
      rawRows = data['data'] ?? data['items'] ?? data['value'] ?? data;
    }

    final rows = <Map<String, dynamic>>[];
    if (rawRows is List) {
      for (final item in rawRows) {
        if (item is Map) rows.add(Map<String, dynamic>.from(item));
      }
    } else if (rawRows is Map) {
      rows.add(Map<String, dynamic>.from(rawRows));
    }

    return rows;
  }

  List<String> _extractContractorIds({bool allowFallback = true}) {
    final selection = _moduleData['contractorSubmissionId'];
    final List<dynamic> items = selection is List
        ? List<dynamic>.from(selection)
        : (selection != null ? [selection] : const []);

    final ids = <String>{};
    for (final item in items) {
      if (item is Map) {
        _collectContractorIds(
          Map<String, dynamic>.from(item),
          ids,
          allowFallback: allowFallback,
        );
      } else if (item is String && item.trim().isNotEmpty) {
        ids.add(item);
      }
    }

    return ids.toList();
  }

  List<String> _extractSelectedSubmissionIds() {
    final selection = _moduleData['contractorSubmissionId'];
    final List<dynamic> items = selection is List
        ? List<dynamic>.from(selection)
        : (selection != null ? [selection] : const []);

    final ids = <String>{};
    for (final item in items) {
      final id = item is Map ? _extractId(item['id']) : _extractId(item);
      if (id != null) ids.add(id);
    }

    return ids.toList();
  }

  void _collectContractorIds(
    Map<String, dynamic> item,
    Set<String> ids, {
    bool allowFallback = true,
  }) {
    final initialCount = ids.length;

    for (final key in const [
      'contractorIds',
      'contractorIdList',
      'contractors',
    ]) {
      final values = item[key];
      if (values is List) {
        for (final value in values) {
          final id = _extractId(value);
          if (id != null) ids.add(id);
        }
      }
    }

    for (final path in const [
      'contractorId',
      'contractorID',
      'contractor.id',
      'contractorId.id',
      'contractorInfo.id',
      'contractorMap.id',
    ]) {
      final id = _extractId(_getByPath(item, path));
      if (id != null) ids.add(id);
    }

    if (allowFallback && ids.length == initialCount) {
      final fallbackId = _extractId(item['id']);
      if (fallbackId != null) ids.add(fallbackId);
    }
  }

  dynamic _getByPath(Map<String, dynamic> item, String path) {
    dynamic current = item;
    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  String? _extractId(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map) {
      final id = value['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String _contractSubmissionEndpoint() {
    final rawId = _moduleData['id']?.toString().trim();
    final id = rawId == null || rawId.isEmpty ? 'null' : rawId;
    final encodedId = Uri.encodeQueryComponent(id);
    return 'DROPDOWN.SAFETR/CONTRACT_SUBMISSION?id=$encodedId';
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
            _buildAttendanceSection(),
            _buildSystemInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'GENERAL INFORMATION',
      headerIcon: Icons.article_outlined,
      headerColor: Colors.indigo,
      children: [
        ..._buildDynamicFields([
          {
            'key': 'contractorSubmissionId',
            'widget': 'select',
            'selectType': 'multiple',
            'label': 'Contractor Submission',
            'hintText': 'Select contractor submission',
            'data': _contractSubmissionEndpoint(),
            'display': 'code',
            'moreDisplay': [
              {'label': 'Project', 'key': 'projectName'},
              {'label': 'Contractor', 'key': 'contractorName'},
            ],
          },
        ]),
        _buildResponsiveFieldRow([
          {
            'key': 'dateTraining',
            'widget': 'datetime',
            'label': 'Training Date',
            'datetimeType': 'date',
            'displayFormat': 'ddMMyyyy',
          },
          {
            'key': 'registrationDate',
            'widget': 'datetime',
            'label': 'Date Registration',
            'datetimeType': 'date',
            'displayFormat': 'ddMMyyyy',
          },
        ]),
        ..._buildDynamicFields([
          {'key': 'topic', 'label': 'Topic', 'type': 'textarea', 'maxLines': 4},
        ]),
      ],
    );
  }

  List<Widget> _buildDynamicFields(List<Map<String, dynamic>> fieldConfigs) {
    return CoreDynamicFields.buildFields(
      fieldConfigs: fieldConfigs,
      itemDetail: _itemDetail,
      moduleData: _moduleData,
      onChanged: _onChanged,
    );
  }

  Widget _buildResponsiveFieldRow(List<Map<String, dynamic>> fieldConfigs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          final children = <Widget>[];
          for (final config in fieldConfigs) {
            children.addAll(_buildDynamicFields([config]));
          }
          return Column(children: children);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < fieldConfigs.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(
                child: Column(children: _buildDynamicFields([fieldConfigs[i]])),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAttendanceSection() {
    return CardSection(
      title: 'SAFETY TRAINING ATTENDANCE',
      headerIcon: Icons.people_outline,
      headerColor: Colors.blue,
      children: [_buildAttendanceContent()],
    );
  }

  Widget _buildAttendanceContent() {
    if (_attendanceLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_attendanceError != null && _attendanceError!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _attendanceError!,
          style: TextStyle(color: Colors.red.shade600),
        ),
      );
    }

    if (_attendanceRows.isEmpty) {
      return _buildAttendanceEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < _attendanceRows.length; i++)
          _buildAttendanceListItem(_attendanceRows[i], i),
      ],
    );
  }

  Widget _buildAttendanceEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No attendance data available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceListItem(Map<String, dynamic> row, int index) {
    final rowNo =
        int.tryParse(row['sortOrder']?.toString() ?? '') ?? (index + 1);
    final fullName = row['fullName']?.toString().trim() ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _attendanceRows.length - 1 ? 0 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceItemHeader(rowNo, fullName),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
            child: Column(
              children: [
                _buildAttendanceInfoRow(
                  'Year of Birth',
                  row['yearOfBirth']?.toString() ?? '',
                ),
                _buildAttendanceInfoRow(
                  'Identity No.',
                  row['identityNo']?.toString() ?? '',
                ),
                _buildAttendanceInfoRow(
                  'Company',
                  row['company']?.toString() ?? '',
                ),
                _buildAttendanceInfoRow(
                  'Position',
                  row['position']?.toString() ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItemHeader(int rowNo, String fullName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rowNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fullName.isEmpty ? 'Unknown attendee' : fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceInfoRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: const BoxDecoration(
                  color: _attendanceLabelBgColor,
                  border: Border(
                    left: BorderSide(color: _attendanceBorderColor),
                    top: BorderSide(color: _attendanceBorderColor),
                    bottom: BorderSide(color: _attendanceBorderColor),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: _attendanceBorderColor),
                    right: BorderSide(color: _attendanceBorderColor),
                    top: BorderSide(color: _attendanceBorderColor),
                    bottom: BorderSide(color: _attendanceBorderColor),
                  ),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'SYSTEM INFORMATION',
      headerIcon: Icons.info_outline,
      headerColor: Colors.teal,
      children: [
        _buildResponsiveFieldRow([
          {'key': 'createdBy', 'label': 'Created By', 'disabled': true},
          {
            'key': 'createdDate',
            'widget': 'datetime',
            'label': 'Created Date',
            'datetimeType': 'datetime',
            'displayFormat': 'ddMMyyyy',
            'disabled': true,
          },
        ]),
        _buildResponsiveFieldRow([
          {'key': 'updatedBy', 'label': 'Updated By', 'disabled': true},
          {
            'key': 'updatedDate',
            'widget': 'datetime',
            'label': 'Updated Date',
            'datetimeType': 'datetime',
            'displayFormat': 'ddMMyyyy',
            'disabled': true,
          },
        ]),
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
