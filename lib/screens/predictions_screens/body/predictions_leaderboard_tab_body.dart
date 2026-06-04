import 'package:flutter/material.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_stake_widgets.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_ui_helpers.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

class PredictionsLeaderboardTabBody extends CoreTabBody {
  const PredictionsLeaderboardTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<PredictionsLeaderboardTabBody> createState() =>
      _PredictionsLeaderboardTabBodyState();
}

class _PredictionsLeaderboardTabBodyState
    extends CoreTabBodyState<PredictionsLeaderboardTabBody> {
  static const Color _blue = Color(0xFF4E7FB9);
  static const Color _orange = Color(0xFFFF7A2F);
  static const Color _ink = Color(0xFF243447);
  static const Color _line = Color(0xFFD8E5F2);
  static const Color _row = Color(0xFFEAF4FE);
  static const Color _shell = Color(0xFFF6FAFE);

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  bool _showTopStake = true;

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(PredictionsLeaderboardTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = predictionMap(_response['itemDetail']);
    _moduleData = predictionMap(_itemDetail['value']);
    if (mounted) setState(() {});
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeKey = _activeStakeKey;
    final items = _itemsFor(activeKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSwitcher(),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildLeaderboardCard(items, activeKey),
          ),
        ],
      ),
    );
  }

  String get _activeStakeKey =>
      _showTopStake ? 'topUserStake' : 'lowestUserStake';

  void _selectStakeMode(bool showTopStake) {
    if (_showTopStake == showTopStake) return;
    setState(() => _showTopStake = showTopStake);
  }

  List<Map<String, dynamic>> _itemsFor(String key) {
    return List<Map<String, dynamic>>.from(
      predictionList(_leaderboardSourceValue(key)),
    );
  }

  dynamic _leaderboardSourceValue(String key) {
    final itemDetailValue = predictionMap(_itemDetail['value']);
    for (final source in [
      _moduleData,
      itemDetailValue,
      _itemDetail,
      _response,
    ]) {
      if (source.containsKey(key)) return source[key];
    }
    return null;
  }

  Widget _buildSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _switchButton(
              label: 'Top User Stake',
              icon: Icons.leaderboard_rounded,
              selected: _showTopStake,
              onTap: () => _selectStakeMode(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _switchButton(
              label: 'Lowest User Stake',
              icon: Icons.arrow_circle_down_rounded,
              selected: !_showTopStake,
              onTap: () => _selectStakeMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : _shell,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? _blue : _line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : _blue, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(List<Map<String, dynamic>> items, String key) {
    return Container(
      key: ValueKey('leaderboard-card-$key'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(items.length),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _leaderboardTable(items, key),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(int count) {
    final title = _showTopStake ? 'Top User Stake' : 'Lowest User Stake';
    final icon = _showTopStake
        ? Icons.leaderboard_rounded
        : Icons.arrow_circle_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFE0EFFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _orange, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F4FE),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF9BC4EE)),
            ),
            child: Text(
              '$count USERS',
              style: const TextStyle(
                color: Color(0xFF2D68A4),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTable(List<Map<String, dynamic>> items, String key) {
    return Container(
      key: ValueKey('leaderboard-table-$key'),
      decoration: BoxDecoration(
        color: _row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7D9EC)),
      ),
      child: Column(
        children: [
          _tableHeader(),
          if (items.isEmpty)
            _emptyState()
          else
            ...items.asMap().entries.map(
              (entry) => _tableRow(
                entry.key,
                entry.value,
                keyPrefix: key,
                isLast: entry.key == items.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F7FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Color(0xFFC7D9EC))),
      ),
      child: Row(
        children: [
          _headerCell('STT', width: 46),
          _headerCell('USER', flex: 1, alignment: Alignment.centerLeft),
          _headerCell('POINTS', width: 116, alignment: Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _headerCell(
    String text, {
    double? width,
    int flex = 0,
    Alignment alignment = Alignment.center,
  }) {
    final child = Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _blue,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex, child: child);
  }

  Widget _tableRow(
    int index,
    Map<String, dynamic> item, {
    required String keyPrefix,
    required bool isLast,
  }) {
    return Container(
      key: ValueKey(
        '$keyPrefix-$index-${_userName(item)}-${predictionNum(_points(item))}',
      ),
      constraints: const BoxConstraints(minHeight: 42),
      decoration: BoxDecoration(
        color: _row,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFC7D9EC))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                _userName(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 116,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: PredictionStakeAmount(
                  value: _points(item),
                  color: const Color(0xFF2D68A4),
                  fontSize: 11,
                  iconSize: 13,
                  mainAxisAlignment: MainAxisAlignment.end,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const SizedBox(
      height: 86,
      child: Center(
        child: Text(
          'No leaderboard data',
          style: TextStyle(
            color: Color(0xFF7B8EA4),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _userName(Map<String, dynamic> item) {
    final user = predictionMap(item['user']);
    for (final value in [
      user['fullName'],
      user['name'],
      user['userName'],
      item['fullName'],
      item['name'],
      item['userName'],
      item['user'],
    ]) {
      final text = predictionText(value, fallback: '');
      if (text.isNotEmpty && text != '--') return text;
    }
    return '--';
  }

  dynamic _points(Map<String, dynamic> item) {
    final user = predictionMap(item['user']);
    for (final value in [
      item['totalStake'],
      item['points'],
      item['totalPoints'],
      item['stake'],
      item['value'],
      user['totalStake'],
      user['points'],
      user['totalPoints'],
      user['stake'],
    ]) {
      if (value != null) return value;
    }
    return 0;
  }
}
