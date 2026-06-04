import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_stake_widgets.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_ui_helpers.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Read-only custom collection tab for PREDIC predictionHistories.
class PredictionsHistoryTabBody extends CoreTabBody {
  const PredictionsHistoryTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<PredictionsHistoryTabBody> createState() =>
      _PredictionsHistoryTabBodyState();
}

class _PredictionsHistoryTabBodyState
    extends CoreTabBodyState<PredictionsHistoryTabBody> {
  static const Color _blue = Color(0xFF4E7FB9);
  static const Color _green = Color(0xFF1DBE71);
  static const Color _orange = Color(0xFFFF7A2F);
  static const Color _ink = Color(0xFF243447);
  static const Color _line = Color(0xFFD8E5F2);
  static const Color _row = Color(0xFFE0F0FE);
  static const Color _shell = Color(0xFFF6FAFE);

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(PredictionsHistoryTabBody oldWidget) {
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

    final histories = _filteredHistories();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearch(),
              const SizedBox(height: 10),
              if (isWide)
                _buildWideTable(histories, constraints.maxWidth)
              else
                _buildMobileCards(histories),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredHistories() {
    final histories = predictionList(_moduleData['predictionHistories']);
    final query = _searchText.trim().toLowerCase();

    final filtered = query.isEmpty
        ? List<Map<String, dynamic>>.from(histories)
        : histories.where((item) {
            final user = predictionMap(item['user']);
            final target = [
              user['fullName'],
              user['code'],
              user['location'],
              item['code'],
              predictionScoreLabel(item),
            ].whereType<Object>().join(' ').toLowerCase();
            return target.contains(query);
          }).toList();

    return filtered;
  }

  Widget _buildSearch() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextField(
        onChanged: (value) => setState(() => _searchText = value),
        decoration: const InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search, size: 19),
          isDense: true,
          filled: true,
          fillColor: Color(0xFFF8FBFF),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildWideTable(List<Map<String, dynamic>> histories, double width) {
    final tableWidth = math.max(980.0, width);
    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _tableHeader(),
              if (histories.isEmpty)
                _emptyState()
              else
                ...histories.map(_tableRow),
              _tableFooter(histories),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _blue.withOpacity(0.9), width: 2),
        ),
      ),
      child: Row(
        children: [
          _headerCell('User', flex: 18),
          _headerCell('Selection', flex: 24),
          _headerCell('Match Entry', flex: 12),
          _headerCell(_scoreHeader(), flex: 13),
          _headerCell('Score Entry', flex: 12),
          _headerCell('Total Balance', flex: 16),
        ],
      ),
    );
  }

  Widget _scoreHeader() {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Score',
          style: TextStyle(
            color: Color(0xFF0B579D),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _teamLogo(homeTeam, size: 20),
            const SizedBox(width: 5),
            const Text('-', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            _teamLogo(awayTeam, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(dynamic content, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: _line.withOpacity(0.9))),
        ),
        child: content is Widget
            ? content
            : Text(
                content.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0B579D),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> item) {
    final user = predictionMap(item['user']);
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      decoration: const BoxDecoration(
        color: _row,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          _bodyCell(
            Text(
              predictionText(user['fullName']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            flex: 18,
            alignment: Alignment.centerLeft,
          ),
          _bodyCell(_selectionPills(item), flex: 24),
          _bodyCell(_amountText(item['bet']), flex: 12),
          _bodyCell(_scoreBadge(item), flex: 13),
          _bodyCell(_amountText(item['scoreBet']), flex: 12),
          _bodyCell(
            _amountText(
              user['totalStake'],
              color: Colors.redAccent,
              bold: true,
            ),
            flex: 16,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _bodyCell(
    Widget child, {
    required int flex,
    Alignment alignment = Alignment.center,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _selectionPills(Map<String, dynamic> item) {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    final selected = predictionWinnerKey(item);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _choicePill(
          label: predictionText(homeTeam['name'], fallback: 'Home'),
          selected: selected == 'home',
          color: _green,
          child: _teamLogo(homeTeam, size: 22),
        ),
        const SizedBox(width: 12),
        _choicePill(
          label: 'Draw',
          selected: selected == 'draw',
          color: Colors.blueGrey,
          child: const Icon(Icons.drag_handle, size: 21),
        ),
        const SizedBox(width: 12),
        _choicePill(
          label: predictionText(awayTeam['name'], fallback: 'Away'),
          selected: selected == 'away',
          color: _orange,
          child: _teamLogo(awayTeam, size: 22),
        ),
      ],
    );
  }

  Widget _choicePill({
    required String label,
    required bool selected,
    required Color color,
    required Widget child,
  }) {
    final opacity = selected ? 1.0 : 0.34;
    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          SizedBox(width: 28, height: 24, child: Center(child: child)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _ink : const Color(0xFF8D9AAA),
              fontSize: 10,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _scoreBox(predictionInt(item['predictHomeScore'])),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            '-',
            style: TextStyle(
              color: Color(0xFF42576D),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _scoreBox(predictionInt(item['predictAwayScore'])),
      ],
    );
  }

  Widget _scoreBox(int score) {
    return Container(
      width: 28,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        score.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _amountText(dynamic value, {Color color = _ink, bool bold = false}) {
    return PredictionStakeAmount(
      value: value,
      color: color,
      fontSize: 13,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
      iconSize: 14,
    );
  }

  Widget _tableFooter(List<Map<String, dynamic>> histories) {
    final totals = _historyTotals(histories);
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _bodyCell(
            const Text(
              'Total',
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            flex: 18,
            alignment: Alignment.centerLeft,
          ),
          _bodyCell(_selectionTotals(totals), flex: 24),
          _bodyCell(_amountText(totals['matchBet']), flex: 12),
          _bodyCell(const SizedBox.shrink(), flex: 13),
          _bodyCell(_amountText(totals['scoreBet']), flex: 12),
          _bodyCell(
            _amountText(totals['totalStake'], bold: true),
            flex: 16,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _selectionTotals(Map<String, num> totals) {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _totalPick(_teamLogo(homeTeam, size: 22), totals['homeBet'] ?? 0),
        const SizedBox(width: 14),
        _totalPick(
          const Icon(Icons.drag_handle, size: 21),
          totals['drawBet'] ?? 0,
        ),
        const SizedBox(width: 14),
        _totalPick(_teamLogo(awayTeam, size: 22), totals['awayBet'] ?? 0),
      ],
    );
  }

  Widget _totalPick(Widget icon, num value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 26, height: 22, child: Center(child: icon)),
        const SizedBox(height: 4),
        PredictionStakeAmount(
          value: value,
          color: const Color(0xFF5C6A7A),
          fontSize: 10,
          iconSize: 12,
        ),
      ],
    );
  }

  Map<String, num> _historyTotals(List<Map<String, dynamic>> histories) {
    final totals = <String, num>{
      'homeBet': 0,
      'drawBet': 0,
      'awayBet': 0,
      'matchBet': 0,
      'scoreBet': 0,
      'totalStake': 0,
    };

    for (final item in histories) {
      final bet = predictionNum(item['bet']);
      final winner = predictionWinnerKey(item);
      if (winner == 'home') totals['homeBet'] = totals['homeBet']! + bet;
      if (winner == 'draw') totals['drawBet'] = totals['drawBet']! + bet;
      if (winner == 'away') totals['awayBet'] = totals['awayBet']! + bet;
      totals['matchBet'] = totals['matchBet']! + bet;
      totals['scoreBet'] =
          totals['scoreBet']! + predictionNum(item['scoreBet']);
      totals['totalStake'] =
          totals['totalStake']! +
          predictionNum(predictionMap(item['user'])['totalStake']);
    }

    return totals;
  }

  Widget _buildMobileCards(List<Map<String, dynamic>> histories) {
    if (histories.isEmpty) return _emptyState();
    final totals = _historyTotals(histories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _mobileSummary(totals),
        const SizedBox(height: 10),
        ...histories.map(_mobileCard),
      ],
    );
  }

  Widget _mobileSummary(Map<String, num> totals) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryMetric('Match', totals['matchBet'])),
          Expanded(child: _summaryMetric('Score', totals['scoreBet'])),
          Expanded(child: _summaryMetric('Balance', totals['totalStake'])),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5E7591),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        PredictionStakeAmount(
          value: value,
          color: _ink,
          fontSize: 13,
          iconSize: 14,
        ),
      ],
    );
  }

  Widget _mobileCard(Map<String, dynamic> item) {
    final user = predictionMap(item['user']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _row,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  predictionText(user['fullName']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _amountText(
                user['totalStake'],
                color: Colors.redAccent,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 9),
          _selectionPills(item),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: _mobileStat('Match Entry', item['bet'])),
              Expanded(child: Center(child: _scoreBadge(item))),
              Expanded(child: _mobileStat('Score Entry', item['scoreBet'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6F8298),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          _amountText(value),
        ],
      ),
    );
  }

  Widget _teamLogo(Map<String, dynamic> team, {double size = 24}) {
    final logo = predictionText(team['logo'], fallback: '');
    if (logo.isEmpty || logo == '--') {
      return Icon(Icons.flag_outlined, size: size * 0.75, color: _blue);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.flag_outlined, size: size * 0.75, color: _blue),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _shell,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_outlined, color: Color(0xFF91A7BD), size: 34),
          SizedBox(height: 8),
          Text(
            'No predictions found',
            style: TextStyle(
              color: Color(0xFF627A94),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
