import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/weekly_report/html_content_viewer.dart';

/// Tab body for WKLRPT DTLS (Details) - View Only
class WeeklyReportDetailsTabBody extends CoreTabBody {
  const WeeklyReportDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<WeeklyReportDetailsTabBody> createState() => _WeeklyReportDetailsTabBodyState();
}

class _WeeklyReportDetailsTabBodyState extends CoreTabBodyState<WeeklyReportDetailsTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(WeeklyReportDetailsTabBody oldWidget) {
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
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  /// Extract raw html string for a key
  String _getHtmlString(String key) => _moduleData[key]?.toString() ?? '';

  @override
  Widget buildTabContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralInfoSection(),
          _buildWeeklySummarySection(),
          _buildSystemInfoSection(),
        ],
      ),
    ).dismissKeyboardOnTap();
  }

  Widget _buildGeneralInfoSection() {
    return CardSection(
      title: 'General Information',
      headerIcon: Icons.article_outlined,
      headerColor: const Color.fromARGB(255, 26, 26, 163),
      children: [
        ...CoreDynamicFields.buildFields(
          fieldConfigs: [
            { 'key': 'status', 'widget': 'status', 'showIcon': true, 'visibleWhen': { 'key': 'id', 'operator': 'ne', 'value': null } },
            { 'key': 'code', 'label': 'Report Code', 'disabled': true },
            { 'key': 'userId', 'widget': 'select', 'selectType': 'dropdown', 'label': 'Reporter', 'hintText': 'Select user', 'data': 'DROPDOWN.WKLRPT/USERS', 'display': 'fullName', 'disabled': true },
            { 'key': 'startDate', 'widget': 'datetime', 'label': 'From Date - To Date', 'datetimeType': 'daterange', 'startDateKey': 'startDate', 'endDateKey': 'endDate', 'displayFormat': 'ddMMyyyy', 'hintText': 'Select week duration...', 'disabled': true },
          ],
          itemDetail: _itemDetail,
          moduleData: _moduleData,
          onChanged: _onChanged,
        ),
      ],
    );
  }

  Widget _buildWeeklySummarySection() {
    final completedWork = _getHtmlString('jobCompletedLastWeek');
    final planNextWeek = _getHtmlString('jobNextWeek');
    final notes = _getHtmlString('note');

    return CardSection(
      title: 'Weekly Summary',
      headerIcon: Icons.event_note,
      headerColor: Colors.teal,
      children: [
        HtmlContentViewer(
          title: 'Completed Last Week',
          htmlContent: completedWork,
          themeColor: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: 10),
        HtmlContentViewer(
          title: 'Plan Next Week',
          htmlContent: planNextWeek,
          themeColor: const Color(0xFF1565C0),
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 10),
        HtmlContentViewer(
          title: 'Notes',
          htmlContent: notes,
          themeColor: const Color(0xFFEF6C00),
          icon: Icons.note_alt_rounded,
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return CardSection(
      title: 'System Information',
      headerIcon: Icons.info_outline,
      headerColor: const Color.fromARGB(255, 71, 102, 21),
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
    return true; // View only - no validation needed
  }

  @override
  Future<void> loadTabSpecificData() async {}
}


