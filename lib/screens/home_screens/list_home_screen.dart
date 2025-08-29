import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/services/core_service.dart';

class ListHomeScreen extends StatefulWidget {
  const ListHomeScreen({super.key});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  // Year selection
  late int _selectedYear;
  late List<int> _years;

  // Loading & error states
  bool _loading = false;
  String? _errorMessage;

  // Dashboard data
  Map<String, dynamic>? _eleave; // keys: totalAnnualLeave, totalLeaveApplied, totalRemainLeave, totalLeaveDaysInYear
  Map<String, dynamic>? _overtime; // keys: totalApprovedOTHoursInYear, approvedTicketCountInYear
  Map<String, dynamic>? _travelRequest; // keys: totalApprovedTravelDaysInYear, approvedTicketCountInYear
  Map<String, dynamic>? _travelClaim; // keys: totalApprovedClaimExpenseInYear, approvedClaimCountInYear

  // User IDs (can differ per module in your samples; we'll use logged-in id for all)
  String? _userId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _years = List<int>.generate(6, (i) => now.year - i);
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _loadUserIdFromSession();
    await _loadDashboardData();
  }

  Future<void> _loadUserIdFromSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr != null) {
        final obj = jsonDecode(userJsonStr);
        _userId = obj['id']?.toString();
      }
    } catch (_) {
      _userId = null;
    }
  }

  Future<void> _loadDashboardData() async {
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _errorMessage = 'Không tìm thấy thông tin người dùng.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Build endpoints
      final eleaveEndpoint = 'DASHBOARD/ELEAVE?userId=$_userId&year=$_selectedYear';
      final overtimeEndpoint = 'DASHBOARD/OVERTIME?userId=$_userId&year=$_selectedYear';
      final trEndpoint = 'DASHBOARD/TRAVEL_REQUEST?userId=$_userId&year=$_selectedYear';
      final tcEndpoint = 'DASHBOARD/TRAVEL_CLAIM?userId=$_userId&year=$_selectedYear';

      // Parallel fetches
      final results = await Future.wait([
        CoreService.instance.getDropdownData(eleaveEndpoint),
        CoreService.instance.getDropdownData(overtimeEndpoint),
        CoreService.instance.getDropdownData(trEndpoint),
        CoreService.instance.getDropdownData(tcEndpoint),
      ]);

      Map<String, dynamic>? parseFirstMap(dynamic res) {
        if (res is Map && res['success'] == true) {
          final data = res['data'];
          if (data is List && data.isNotEmpty && data.first is Map) {
            return Map<String, dynamic>.from(data.first as Map);
          }
          if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
            final first = (data['data'] as List).first;
            if (first is Map) return Map<String, dynamic>.from(first);
          }
        }
        return null;
      }

      final eleave = parseFirstMap(results[0]);
      final overtime = parseFirstMap(results[1]);
      final travelRequest = parseFirstMap(results[2]);
      final travelClaim = parseFirstMap(results[3]);

      setState(() {
        _eleave = eleave;
        _overtime = overtime;
        _travelRequest = travelRequest;
        _travelClaim = travelClaim;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu dashboard: $e';
      });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _fmtNum(dynamic v, {int fraction = 2}) {
    if (v == null) return '0';
    final num? n = num.tryParse(v.toString());
    if (n == null) return '0';
    if (n % 1 == 0) return n.toInt().toString();
    final s = n.toStringAsFixed(fraction);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Chọn năm:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox.shrink(),
            items: _years
                .map((y) => DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString()),
                    ))
                .toList(),
            onChanged: (val) async {
              if (val == null) return;
              setState(() { _selectedYear = val; });
              await _loadDashboardData();
            },
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _loadDashboardData,
            icon: Icon(Icons.refresh_rounded, color: _loading ? Colors.grey : Colors.blue.shade600),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          )
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required List<Color> gradient,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: gradient.last.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bỏ AppBar theo yêu cầu
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildYearSelector(),

                        // E-LEAVE
                        _buildSectionTitle('E-Leave', Icons.beach_access_rounded, Colors.teal),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Annual Leave',
                              value: _fmtNum(_eleave?['totalAnnualLeave']),
                              icon: Icons.event_available,
                              gradient: const [Color(0xFF26A69A), Color(0xFF00796B)],
                            ),
                            _metricCard(
                              label: 'Leave Applied',
                              value: _fmtNum(_eleave?['totalLeaveApplied']),
                              icon: Icons.edit_calendar_rounded,
                              gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                            ),
                            _metricCard(
                              label: 'Remain Leave',
                              value: _fmtNum(_eleave?['totalRemainLeave']),
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: const [Color(0xFF26C6DA), Color(0xFF0097A7)],
                            ),
                            _metricCard(
                              label: 'Total Leave Days (Year)',
                              value: _fmtNum(_eleave?['totalLeaveDaysInYear']),
                              icon: Icons.calendar_month_rounded,
                              gradient: const [Color(0xFF26C6DA), Color(0xFF00838F)],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // OVERTIME (đưa Ticket lên trước)
                        _buildSectionTitle('Overtime', Icons.access_time_rounded, Colors.deepPurple),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved Tickets',
                              value: _fmtNum(_overtime?['approvedTicketCountInYear'], fraction: 0),
                              icon: Icons.verified_rounded,
                              gradient: const [Color(0xFF7E57C2), Color(0xFF512DA8)],
                            ),
                            _metricCard(
                              label: 'Approved OT Hours',
                              value: _fmtNum(_overtime?['totalApprovedOTHoursInYear']),
                              icon: Icons.timelapse_rounded,
                              gradient: const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // TRAVEL REQUEST (đưa Ticket lên trước)
                        _buildSectionTitle('Travel Request', Icons.airplanemode_active_rounded, Colors.indigo),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved Tickets',
                              value: _fmtNum(_travelRequest?['approvedTicketCountInYear'], fraction: 0),
                              icon: Icons.assignment_turned_in_rounded,
                              gradient: const [Color(0xFF5C6BC0), Color(0xFF283593)],
                            ),
                            _metricCard(
                              label: 'Approved Travel Days',
                              value: _fmtNum(_travelRequest?['totalApprovedTravelDaysInYear']),
                              icon: Icons.flight_takeoff_rounded,
                              gradient: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // TRAVEL CLAIM (đưa Claim Count lên trước)
                        _buildSectionTitle('Travel Claim', Icons.receipt_long_rounded, Colors.orange),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved Claims',
                              value: _fmtNum(_travelClaim?['approvedClaimCountInYear'], fraction: 0),
                              icon: Icons.done_all_rounded,
                              gradient: const [Color(0xFFFFA726), Color(0xFFEF6C00)],
                            ),
                            _metricCard(
                              label: 'Approved Expense',
                              value: _fmtNum(_travelClaim?['totalApprovedClaimExpenseInYear']),
                              icon: Icons.payments_rounded,
                              gradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_loading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Đang tải dữ liệu...'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      // Removed floating action button per request
    );
  }
}
