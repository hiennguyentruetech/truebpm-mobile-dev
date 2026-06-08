import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';

/// Tab body for USER ANNUALLEAVEHISTORY
class UserAnnualLeaveHistoryTabBody extends CoreTabBody {
  const UserAnnualLeaveHistoryTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<UserAnnualLeaveHistoryTabBody> createState() =>
      _UserAnnualLeaveHistoryTabBodyState();
}

class _UserAnnualLeaveHistoryTabBodyState
    extends CoreTabBodyState<UserAnnualLeaveHistoryTabBody> {
  static const Color _blue = Color(0xFF2B78C5);
  static const Color _headerBlue = Color(0xFFE1F0FD);
  static const Color _rowBlue = Color(0xFFE7F4FF);
  static const Color _line = Color(0xFFC7D9EC);
  static const Color _ink = Color(0xFF243447);

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  String _historySearch = '';
  final TextEditingController _historySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(UserAnnualLeaveHistoryTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  @override
  void dispose() {
    _historySearchController.dispose();
    super.dispose();
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
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
        children: [_buildAdjustmentSection(), _buildHistorySection()],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildAdjustmentSection() {
    return CardSection(
      title: 'Add/Subtract Annual Leave Days',
      headerIcon: Icons.event_available_outlined,
      headerColor: Colors.indigo,
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            {'key': 'code', 'label': 'Username', 'disabled': true},
            {'key': 'fullName', 'label': 'Full Name', 'disabled': true},
            {
              'key': 'totalRemainLeave',
              'label': 'Total Remain Leave',
              'type': 'number',
              'decimalPlaces': 4,
              'useGrouping': false,
              'disabled': true,
            },
            {
              'key': 'totalDays',
              'label': 'Total Days',
              'type': 'number',
              'decimalPlaces': 4,
              'allowNegative': true,
              'useGrouping': false,
              'required': true,
              'hintText': 'Use positive or negative number',
            },
            {
              'key': 'reason',
              'label': 'Reason',
              'type': 'textarea',
              'maxLines': 3,
              'required': true,
              'hintText': 'Enter adjustment reason',
            },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final histories = _filteredHistories();

    return CardSection(
      title: 'Annual Leave History',
      headerIcon: Icons.history_outlined,
      headerColor: Colors.teal,
      children: [
        _buildHistorySearch(),
        const SizedBox(height: 10),
        _buildHistoryTable(histories),
      ],
    );
  }

  List<Map<String, dynamic>> _historyItems() {
    final raw = _moduleData['plusSubAnnualLeave'];
    if (raw is! List) return const <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  List<Map<String, dynamic>> _filteredHistories() {
    final histories = _historyItems();
    final query = _historySearch.trim().toLowerCase();
    if (query.isEmpty) return histories;

    return histories.where((item) {
      final text = [
        _dateText(item),
        _daysText(item),
        _reasonText(item),
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Widget _buildHistorySearch() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _historySearchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _historySearch = value),
        style: const TextStyle(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(
            color: Color(0xFF8EA2B8),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF6E85A0),
          ),
          suffixIcon: _historySearch.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF7B8EA4),
                  ),
                  onPressed: () {
                    _historySearchController.clear();
                    setState(() => _historySearch = '');
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<Map<String, dynamic>> histories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final dateWidth = isNarrow ? 104.0 : 112.0;
        final daysWidth = isNarrow ? 54.0 : 62.0;

        return Container(
          decoration: BoxDecoration(
            color: _rowBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _historyTableHeader(dateWidth: dateWidth, daysWidth: daysWidth),
              if (histories.isEmpty)
                _historyEmptyState()
              else
                ...histories.asMap().entries.map(
                  (entry) => _historyTableRow(
                    entry.value,
                    dateWidth: dateWidth,
                    daysWidth: daysWidth,
                    isLast: entry.key == histories.length - 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyTableHeader({
    required double dateWidth,
    required double daysWidth,
  }) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: _headerBlue,
        border: Border(bottom: BorderSide(color: _blue, width: 1.4)),
      ),
      child: Row(
        children: [
          _historyHeaderCell('Created\nDate', width: dateWidth),
          _historyHeaderCell('Total\nDays', width: daysWidth, alignRight: true),
          _historyHeaderCell('Reason', expand: true),
        ],
      ),
    );
  }

  Widget _historyTableRow(
    Map<String, dynamic> item, {
    required double dateWidth,
    required double daysWidth,
    required bool isLast,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: _rowBlue,
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: _line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _historyBodyCell(_dateText(item), width: dateWidth, fontSize: 11),
          _historyBodyCell(
            _daysText(item),
            width: daysWidth,
            alignRight: true,
            fontSize: 11,
            fitText: true,
          ),
          _historyBodyCell(_reasonText(item), expand: true, maxLines: 3),
        ],
      ),
    );
  }

  Widget _historyHeaderCell(
    String text, {
    double? width,
    bool expand = false,
    bool alignRight = false,
  }) {
    final cell = Container(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _line)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF2E67A3),
          fontSize: 10,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (expand) return Expanded(child: cell);
    return SizedBox(width: width, child: cell);
  }

  Widget _historyBodyCell(
    String text, {
    double? width,
    bool expand = false,
    bool alignRight = false,
    int maxLines = 1,
    double fontSize = 12,
    bool fitText = false,
  }) {
    final textWidget = Text(
      text,
      maxLines: maxLines,
      overflow: fitText ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: !fitText,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: _ink,
        fontSize: fontSize,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );

    final cell = Container(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: fitText
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: textWidget,
            )
          : textWidget,
    );

    if (expand) return Expanded(child: cell);
    return SizedBox(width: width, child: cell);
  }

  Widget _historyEmptyState() {
    return Container(
      height: 82,
      alignment: Alignment.center,
      child: const Text(
        'No annual leave history available',
        style: TextStyle(
          color: Color(0xFF71849A),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _dateText(Map<String, dynamic> item) {
    final raw = item['createdDate'] ?? item['date'];
    if (raw == null) return '';
    final text = raw.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  String _daysText(Map<String, dynamic> item) {
    final value = item['totalDays'] ?? item['days'];
    if (value == null) return '';
    if (value is num) {
      final rounded = value.roundToDouble();
      if (value.toDouble() == rounded) return rounded.toInt().toString();
    }
    return value.toString();
  }

  String _reasonText(Map<String, dynamic> item) {
    return (item['reason'] ?? '').toString();
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
