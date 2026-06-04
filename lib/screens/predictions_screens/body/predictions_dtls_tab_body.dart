import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_stake_widgets.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_ui_helpers.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/dismiss_keyboard.dart';

/// Custom details tab for PREDIC.
class PredictionsDetailsTabBody extends CoreTabBody {
  const PredictionsDetailsTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<PredictionsDetailsTabBody> createState() =>
      _PredictionsDetailsTabBodyState();
}

class _PredictionsDetailsTabBodyState
    extends CoreTabBodyState<PredictionsDetailsTabBody> {
  static const Color _blue = Color(0xFF4E7FB9);
  static const Color _green = Color(0xFF20C878);
  static const Color _orange = Color(0xFFFF7A2F);
  static const Color _ink = Color(0xFF243447);
  static const Color _line = Color(0xFFDDE8F5);
  static const Color _shell = Color(0xFFF5F9FE);
  static final TextInputFormatter _stakeInputFormatter =
      _PredictionStakeInputFormatter();

  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  final TextEditingController _betController = TextEditingController();
  final TextEditingController _scoreBetController = TextEditingController();
  bool _formattingStakeInput = false;

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(PredictionsDetailsTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  @override
  void dispose() {
    _betController.dispose();
    _scoreBetController.dispose();
    super.dispose();
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = predictionMap(_response['itemDetail']);
    _moduleData = predictionMap(_itemDetail['value']);
    _syncControllers();
    if (mounted) setState(() {});
  }

  void _syncControllers() {
    _setControllerText(_betController, _moduleData['bet']);
    _setControllerText(_scoreBetController, _moduleData['scoreBet']);
  }

  void _setControllerText(TextEditingController controller, dynamic value) {
    final text = predictionMoneyFormat.format(predictionNum(value).round());
    if (controller.text != text) {
      controller.text = text;
    }
  }

  void _commitResponse() {
    _itemDetail['value'] = Map<String, dynamic>.from(_moduleData);
    _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
  }

  void _notifyChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged?.call(_response);
    });
  }

  void _onChanged(String key, dynamic value) {
    if (_isMatchClosed()) return;

    setState(() {
      _moduleData[key] = value;
      _commitResponse();
    });
    _notifyChanged();
  }

  void _setWinner(String winner) {
    if (_isMatchClosed()) return;
    if (winner == 'draw' && !_isGroupStageMatch()) return;

    setState(() {
      _moduleData['homeWin'] = winner == 'home';
      _moduleData['awayWin'] = winner == 'away';
      _moduleData['draw'] = winner == 'draw';
      _commitResponse();
    });
    _notifyChanged();
  }

  void _changeScore(String key, int value) {
    if (_isMatchClosed() || _isGroupStageMatch()) return;

    _onChanged(key, math.max(0, value));
  }

  void _onStakeChanged(
    String key,
    TextEditingController controller,
    String value,
  ) {
    if (_isMatchClosed()) return;
    if (_formattingStakeInput) return;

    final amount = predictionInt(value);
    _onChanged(key, amount);
    _formatStakeController(controller, allowEmpty: value.trim().isEmpty);
  }

  bool _isGroupStageMatch() {
    final matches = predictionMap(_moduleData['matches']);
    final matchType = predictionMap(matches['matchType']);
    return _isGroupStageValue(matchType['name']) ||
        _isGroupStageValue(matchType['code']) ||
        _isGroupStageValue(matchType['value']);
  }

  bool _isGroupStageValue(dynamic value) {
    final normalized = predictionText(
      value,
      fallback: '',
    ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.isEmpty) return false;
    return normalized == 'gs' ||
        normalized == 'group' ||
        normalized.contains('groupstage') ||
        normalized.contains('vongbang');
  }

  bool _isMatchClosed() {
    final matches = predictionMap(_moduleData['matches']);
    final matchTime = _parseMatchTime(matches['matchTime']);
    if (matchTime == null) return false;
    return !matchTime.isAfter(DateTime.now());
  }

  DateTime? _parseMatchTime(dynamic value) {
    final text = predictionText(value, fallback: '');
    if (text.isEmpty || text == '--') return null;

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final dateTimeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s+(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(text);
    if (dateTimeMatch != null) {
      return DateTime(
        int.parse(dateTimeMatch.group(5)!),
        int.parse(dateTimeMatch.group(4)!),
        int.parse(dateTimeMatch.group(3)!),
        int.parse(dateTimeMatch.group(1)!),
        int.parse(dateTimeMatch.group(2)!),
      );
    }

    final dateMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (dateMatch == null) return null;

    return DateTime(
      int.parse(dateMatch.group(3)!),
      int.parse(dateMatch.group(2)!),
      int.parse(dateMatch.group(1)!),
    );
  }

  void _formatStakeController(
    TextEditingController controller, {
    bool allowEmpty = false,
  }) {
    final raw = controller.text.trim();
    if (allowEmpty && raw.isEmpty) return;

    final formatted = predictionMoneyFormat.format(predictionInt(raw));
    if (controller.text == formatted) return;

    _formattingStakeInput = true;
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _formattingStakeInput = false;
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_moduleData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isGroupStage = _isGroupStageMatch();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlayerBanner(),
              const SizedBox(height: 10),
              _buildMatchOverview(isWide),
              const SizedBox(height: 10),
              _buildWinnerPanel(),
              if (!isGroupStage) ...[
                const SizedBox(height: 10),
                _buildScorePanel(),
              ],
            ],
          ),
        ).dismissKeyboardOnTap();
      },
    );
  }

  Widget _buildPlayerBanner() {
    final user = predictionMap(_moduleData['user']);
    final totalEarned = predictionNum(_moduleData['totalEarned']);

    return Container(
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final gap = compact ? 8.0 : 7.0;
          final metricWidth = compact
              ? math.max(0.0, (constraints.maxWidth - gap) / 2)
              : math.min(
                  128.0,
                  math.max(92.0, (constraints.maxWidth - gap * 3) / 4),
                );

          Widget metric(String label, dynamic value, {bool signed = false}) {
            return SizedBox(
              width: metricWidth,
              child: _buildHeaderRewardMetric(
                label,
                value,
                signed: signed,
                compact: compact,
              ),
            );
          }

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            alignment: compact ? WrapAlignment.spaceBetween : WrapAlignment.end,
            children: [
              metric('Match Reward', _moduleData['betEarned'], signed: true),
              metric(
                'Score Reward',
                _moduleData['scoreBetEarned'],
                signed: true,
              ),
              metric('Total Earned', totalEarned, signed: true),
              metric('Total Points', user['totalStake']),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRewardMetric(
    String label,
    dynamic value, {
    bool signed = false,
    bool compact = false,
  }) {
    return Container(
      height: compact ? 48 : 46,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          _buildHeaderStakeAmount(value, signed: signed, compact: compact),
        ],
      ),
    );
  }

  Widget _buildHeaderStakeAmount(
    dynamic value, {
    required bool signed,
    required bool compact,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            predictionShortMoney(value, signed: signed),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 4),
        GoldfishStakeIcon(size: compact ? 14 : 13),
      ],
    );
  }

  Widget _buildMatchOverview(bool isWide) {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    final matchType = predictionMap(matches['matchType']);
    final homeScore = predictionText(matches['homeScore'], fallback: '-');
    final awayScore = predictionText(matches['awayScore'], fallback: '-');
    final selectedWinner = predictionWinnerKey(_moduleData);
    final histories = predictionList(_moduleData['predictionHistories']);
    final source = histories.isEmpty
        ? <Map<String, dynamic>>[_moduleData]
        : histories;
    final homeAmount = _sumBets(source, 'home');
    final drawAmount = _sumBets(source, 'draw');
    final awayAmount = _sumBets(source, 'away');
    final total = homeAmount + drawAmount + awayAmount;

    return _panel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  predictionText(matchType['name'], fallback: 'Match'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF55708F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 190 : 154),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 15,
                        color: Colors.blueGrey.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        predictionDateTime(matches['matchTime']),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildTeamBlock(
                  homeTeam,
                  home: true,
                  selected: selectedWinner == 'home',
                ),
              ),
              const SizedBox(width: 8),
              _buildScoreBoard(homeScore, awayScore),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTeamBlock(
                  awayTeam,
                  home: false,
                  selected: selectedWinner == 'away',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _line.withOpacity(0.9)),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: _blue, size: 15),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'DISTRIBUTION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _sectionStakeMeta('Total', total),
            ],
          ),
          const SizedBox(height: 8),
          _distributionBar(homeAmount, drawAmount, awayAmount, total),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _distributionTile(
                  label: predictionText(homeTeam['name'], fallback: 'Home'),
                  amount: homeAmount,
                  percent: total == 0 ? 0 : homeAmount / total * 100,
                  color: _green,
                  softColor: const Color(0xFFE1F8EA),
                  compact: true,
                ),
              ),
              if (drawAmount > 0) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _distributionTile(
                    label: 'Draw',
                    amount: drawAmount,
                    percent: drawAmount / total * 100,
                    color: Colors.blueGrey,
                    softColor: const Color(0xFFEAF0F6),
                    compact: true,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: _distributionTile(
                  label: predictionText(awayTeam['name'], fallback: 'Away'),
                  amount: awayAmount,
                  percent: total == 0 ? 0 : awayAmount / total * 100,
                  color: _orange,
                  softColor: const Color(0xFFFFEFE6),
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBlock(
    Map<String, dynamic> team, {
    required bool home,
    required bool selected,
  }) {
    final accent = home ? _green : _orange;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(selected ? 0.30 : 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _teamLogo(team, size: 52),
            ),
            if (selected)
              Positioned(
                top: -4,
                right: -7,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB829),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.emoji_events, size: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          predictionText(team['name']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? accent : (home ? const Color(0xFF0FA45C) : _ink),
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _teamLogo(Map<String, dynamic> team, {double size = 34}) {
    final logo = predictionText(team['logo'], fallback: '');
    if (logo.isEmpty || logo == '--') {
      return Icon(Icons.flag_outlined, size: size * 0.65, color: _blue);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.flag_outlined, size: size * 0.65, color: _blue),
      ),
    );
  }

  Widget _buildScoreBoard(String homeScore, String awayScore) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$homeScore : $awayScore',
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  num _sumBets(List<Map<String, dynamic>> entries, String winner) {
    return entries.fold<num>(0, (sum, entry) {
      if (predictionWinnerKey(entry) != winner) return sum;
      return sum + predictionNum(entry['bet']);
    });
  }

  Widget _distributionBar(num home, num draw, num away, num total) {
    if (total <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final segments = <Widget>[];
    void addSegment(num amount, Color color) {
      if (amount <= 0) return;
      segments.add(
        Expanded(
          flex: math.max(1, (amount / total * 100).round()),
          child: Container(color: color),
        ),
      );
    }

    addSegment(home, _green);
    addSegment(draw, Colors.blueGrey.shade400);
    addSegment(away, _orange);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(height: 8, child: Row(children: segments)),
    );
  }

  Widget _distributionTile({
    required String label,
    required num amount,
    required num percent,
    required Color color,
    required Color softColor,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 1 : 2),
          Text(
            '${predictionPercentFormat.format(percent)}%',
            style: TextStyle(
              color: color,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          PredictionStakeAmount(
            value: amount,
            color: const Color(0xFF55708F),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w800,
            iconSize: compact ? 12 : 13,
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPanel() {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    final matchType = predictionMap(matches['matchType']);
    final selected = predictionWinnerKey(_moduleData);
    final showDraw =
        _isGroupStageValue(matchType['name']) ||
        _isGroupStageValue(matchType['code']) ||
        _isGroupStageValue(matchType['value']);
    final editable = !_isMatchClosed();

    return _panel(
      title: 'Pick Your Winner',
      icon: Icons.sports_soccer,
      accent: _orange,
      trailing: _sectionStakeMeta('MIN', matchType['lowestBet']),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _winnerOption(
                  keyName: 'home',
                  title: 'Home Team',
                  subtitle: predictionText(homeTeam['name']),
                  color: _green,
                  selected: selected == 'home',
                  logo: _teamLogo(homeTeam, size: 24),
                  enabled: editable,
                ),
              ),
              if (showDraw) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _winnerOption(
                    keyName: 'draw',
                    title: 'Draw',
                    subtitle: 'No winner',
                    color: Colors.blueGrey,
                    selected: selected == 'draw',
                    logo: const Icon(Icons.drag_handle, size: 21),
                    enabled: editable,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _winnerOption(
                  keyName: 'away',
                  title: 'Away Team',
                  subtitle: predictionText(awayTeam['name']),
                  color: _orange,
                  selected: selected == 'away',
                  logo: _teamLogo(awayTeam, size: 24),
                  enabled: editable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _moneyInput(
            label: 'Points',
            icon: Icons.add_circle_outline,
            controller: _betController,
            onChanged: (value) => _onStakeChanged('bet', _betController, value),
            enabled: editable,
          ),
        ],
      ),
    );
  }

  Widget _winnerOption({
    required String keyName,
    required String title,
    required String subtitle,
    required Color color,
    required bool selected,
    required Widget logo,
    bool enabled = true,
  }) {
    final selectedBackground = selected
        ? color.withOpacity(enabled ? 0.12 : 0.07)
        : (enabled ? Colors.white : const Color(0xFFF8FAFD));
    final selectedBorder = selected
        ? color.withOpacity(enabled ? 0.75 : 0.32)
        : _line;
    final titleColor = selected
        ? color.withOpacity(enabled ? 1 : 0.62)
        : (enabled ? const Color(0xFF92A1B4) : const Color(0xFFB7C2CF));
    final subtitleColor = selected
        ? (enabled ? _ink : const Color(0xFF7E8B99))
        : (enabled ? const Color(0xFFB6C2D0) : const Color(0xFFC8D1DA));

    return InkWell(
      onTap: enabled ? () => _setWinner(keyName) : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selectedBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selectedBorder, width: selected ? 1.5 : 1),
          boxShadow: selected && enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Opacity(
              opacity: enabled ? 1 : 0.5,
              child: SizedBox(
                width: 26,
                height: 26,
                child: Center(child: logo),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePanel() {
    final matches = predictionMap(_moduleData['matches']);
    final homeTeam = predictionMap(matches['homeTeam']);
    final awayTeam = predictionMap(matches['awayTeam']);
    final matchType = predictionMap(matches['matchType']);
    final homeScore = predictionInt(_moduleData['predictHomeScore']);
    final awayScore = predictionInt(_moduleData['predictAwayScore']);
    final editable = !_isMatchClosed();

    return _panel(
      title: 'Score Pick',
      icon: Icons.grid_view_rounded,
      accent: _orange,
      trailing: _sectionStakeMeta('MIN', matchType['lowestScoreBet']),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _scoreStepper(
                  label: predictionText(homeTeam['name'], fallback: 'Home'),
                  icon: Icons.home_outlined,
                  value: homeScore,
                  color: _green,
                  onChanged: (value) => _changeScore('predictHomeScore', value),
                  enabled: editable,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scoreStepper(
                  label: predictionText(awayTeam['name'], fallback: 'Away'),
                  icon: Icons.outbound_outlined,
                  value: awayScore,
                  color: _orange,
                  onChanged: (value) => _changeScore('predictAwayScore', value),
                  enabled: editable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _moneyInput(
            label: 'Bonus Points',
            icon: Icons.track_changes_outlined,
            controller: _scoreBetController,
            onChanged: (value) =>
                _onStakeChanged('scoreBet', _scoreBetController, value),
            enabled: editable,
          ),
          const SizedBox(height: 10),
          _buildPopularScores(),
        ],
      ),
    );
  }

  Widget _scoreStepper({
    required String label,
    required IconData icon,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
    bool enabled = true,
  }) {
    final controlColor = enabled ? color : Colors.blueGrey.shade300;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: controlColor, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF657B94),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreButton(
                Icons.remove,
                () => onChanged(value - 1),
                controlColor,
                enabled: enabled,
              ),
              Container(
                width: 42,
                height: 38,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: controlColor.withOpacity(enabled ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: controlColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _scoreButton(
                Icons.add,
                () => onChanged(value + 1),
                controlColor,
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreButton(
    IconData icon,
    VoidCallback onTap,
    Color color, {
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _shell : const Color(0xFFF3F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _moneyInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        _stakeInputFormatter,
      ],
      onChanged: enabled ? onChanged : null,
      onEditingComplete: () {
        _formatStakeController(controller);
        FocusScope.of(context).unfocus();
      },
      onTapOutside: (_) {
        _formatStakeController(controller);
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: const GoldfishStakeIcon(size: 18),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 24,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: enabled ? _blue : Colors.blueGrey.shade300,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFD),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _sectionStakeMeta(String label, dynamic value) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF55708F),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          PredictionStakeAmount(
            value: value,
            color: const Color(0xFF55708F),
            fontSize: 11,
            iconSize: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularScores() {
    final histories = predictionList(_moduleData['predictionHistories']);
    final counts = <String, int>{};
    for (final history in histories) {
      final key = predictionScoreLabel(history);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visibleEntries = entries.take(6).toList();

    if (visibleEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 5),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: _blue, size: 15),
                const SizedBox(width: 6),
                const Text(
                  'Score Predictions',
                  style: TextStyle(
                    color: Color(0xFF6E91B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${histories.length} picks',
                  style: const TextStyle(
                    color: Color(0xFF6E91B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: visibleEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value.key;
                final count = entry.value.value;
                final percent = histories.isEmpty
                    ? 0
                    : count / histories.length * 100;
                final highlight = index < 3;
                return Container(
                  width: 82,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlight
                        ? const Color(0xFFFFF4E6)
                        : const Color(0xFFF1F6FC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: highlight
                          ? const Color(0xFFFFC28B)
                          : const Color(0xFFD6E6F6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: highlight ? _orange : _blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${predictionPercentFormat.format(percent)}%',
                            style: TextStyle(
                              color: highlight ? _orange : _blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score,
                        style: TextStyle(
                          color: highlight ? const Color(0xFFC75B00) : _blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$count picks',
                        style: const TextStyle(
                          color: Color(0xFF6D7C8D),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    Widget? child,
    String? title,
    IconData? icon,
    Color accent = _blue,
    Widget? trailing,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFE0EFFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: accent, size: 16),
                    const SizedBox(width: 7),
                  ],
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
                  if (trailing != null) trailing,
                ],
              ),
            ),
          if (child != null)
            Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }
}

class _PredictionStakeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final amount = int.tryParse(digits);
    if (amount == null) {
      return oldValue;
    }

    final formatted = predictionMoneyFormat.format(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
