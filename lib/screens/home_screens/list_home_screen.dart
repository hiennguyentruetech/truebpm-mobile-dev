import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/widgets/loading_overlay.dart';
import 'package:truebpm/widgets/dialogs/custom_confirm_dialog.dart';
import 'package:truebpm/di/service_locator.dart';
import 'package:truebpm/services/auth_service.dart';

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
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _years = List<int>.generate(6, (i) => now.year - i);
    _authService = get<AuthService>();
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
        _errorMessage = 'User information not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (mounted) {
        context.showLoading(message: 'Loading data, please wait...');
      }
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

      // Check for 401 errors in any response
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result['statusCode'] == 401) {
          if (mounted) {
            _showSessionExpiredDialog();
          }
          return;
        }
      }

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
        _errorMessage = 'Error loading dashboard data: $e';
      });
    } finally {
      if (mounted) {
        context.hideLoading();
        setState(() { _loading = false; });
      }
    }
  }

  void _showSessionExpiredDialog() {
    CustomConfirmDialog.showSessionExpired(
      context,
      onConfirm: () async {
        await _authService.clearSavedCredentials();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
    );
  }

  String _fmtNum(dynamic v, {int fraction = 0}) {
    if (v == null) return '0';
    final num? n = num.tryParse(v.toString());
    if (n == null) return '0';
    
    // Format to EU style (thousand '.' and decimal ',')
    if (n % 1 == 0) {
      // Integer: add thousand separators with dots
      return _groupThousands(n.toInt().toString());
    } else {
      // Decimal: format with comma and limit decimal places
      final s = n.toStringAsFixed(fraction);
      final parts = s.split('.');
      final intPart = _groupThousands(parts[0]);
      final decPart = parts.length > 1 ? parts[1] : '';
      return decPart.isNotEmpty ? '$intPart,$decPart' : intPart;
    }
  }

  String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String _formatValueWithDecimals(String value, int decimalPlaces) {
    if (decimalPlaces == 0) return value;
    
    // Parse the value to check if it needs decimal formatting
    final cleanValue = value.replaceAll('.', '').replaceAll(',', '.');
    final num? numValue = num.tryParse(cleanValue);
    
    if (numValue == null) return value;
    
    // Format with specified decimal places
    if (numValue % 1 == 0) {
      // Integer value, add decimal places if needed
      if (decimalPlaces > 0) {
        final formatted = numValue.toStringAsFixed(decimalPlaces);
        final parts = formatted.split('.');
        final intPart = _groupThousands(parts[0]);
        final decPart = parts[1];
        return '$intPart,$decPart';
      }
      return _groupThousands(numValue.toInt().toString());
    } else {
      // Decimal value, format with specified places
      final formatted = numValue.toStringAsFixed(decimalPlaces);
      final parts = formatted.split('.');
      final intPart = _groupThousands(parts[0]);
      final decPart = parts[1];
      return '$intPart,$decPart';
    }
  }

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.blue.shade200.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Calendar Icon with gradient background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade400.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 5),
          
          // Text section with better typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Year',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Reporting Period',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Modern dropdown with gradient border
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox.shrink(),
              icon: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
              ),
              items: _years
                  .map((y) => DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: y == _selectedYear ? Colors.blue.shade800 : Colors.grey.shade700,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (val) async {
                if (val == null) return;
                setState(() { _selectedYear = val; });
                await _loadDashboardData();
              },
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Refresh button with gradient and animation
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _loading 
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [Colors.blue.shade500, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _loading 
                    ? Colors.grey.shade400.withOpacity(0.3)
                    : Colors.blue.shade500.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _loading ? null : _loadDashboardData,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: _loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                ),
              ),
            ),
          ),
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
    String? suffix,
    int decimalPlaces = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: gradient.last.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  _formatValueWithDecimals(value, decimalPlaces),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
          if (suffix != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  suffix,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: _buildYearSelector(),
          ),
        ),
      ),
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
                        // TRAVEL REQUEST (đưa Ticket lên trước)
                        _buildSectionTitle('Travel Request', Icons.airplanemode_active_rounded, Colors.indigo),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved',
                              value: _fmtNum(_travelRequest?['approvedTicketCountInYear']),
                              icon: Icons.assignment_turned_in_rounded,
                              gradient: const [Color(0xFF5C6BC0), Color(0xFF283593)],
                              suffix: 'records',
                            ),
                            _metricCard(
                              label: 'Total Days',
                              value: _fmtNum(_travelRequest?['totalApprovedTravelDaysInYear']),
                              icon: Icons.flight_takeoff_rounded,
                              gradient: const [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                              suffix: 'days',
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
                          childAspectRatio: 1.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved',
                              value: _fmtNum(_travelClaim?['approvedClaimCountInYear']),
                              icon: Icons.done_all_rounded,
                              gradient: const [Color(0xFFFFA726), Color(0xFFEF6C00)],
                              suffix: 'records',
                            ),
                            _metricCard(
                              label: 'Expense Total',
                              value: _fmtNum(_travelClaim?['totalApprovedClaimExpenseInYear']),
                              icon: Icons.payments_rounded,
                              gradient: const [Color(0xFFFFA726), Color(0xFFF57C00)],
                              suffix: 'VND',
                              decimalPlaces: 0,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // E-LEAVE
                        _buildSectionTitle('E-Leave', Icons.beach_access_rounded, Colors.teal),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // _metricCard(
                            //   label: 'Annual Leave',
                            //   value: _fmtNum(_eleave?['totalAnnualLeave']),
                            //   icon: Icons.event_available,
                            //   gradient: const [Color(0xFF26A69A), Color(0xFF00796B)],
                            //   suffix: 'days',
                            //   decimalPlaces: 2,
                            // ),
                            // _metricCard(
                            //   label: 'Applied',
                            //   value: _fmtNum(_eleave?['totalLeaveApplied']),
                            //   icon: Icons.edit_calendar_rounded,
                            //   gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                            //   suffix: 'days',
                            //   decimalPlaces: 2,
                            // ),
                            _metricCard(
                              label: 'Remaining',
                              value: _fmtNum(_eleave?['totalRemainLeave']),
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: const [Color(0xFF26C6DA), Color(0xFF0097A7)],
                              suffix: 'days',
                              decimalPlaces: 2,
                            ),
                            _metricCard(
                              label: 'Total Days',
                              value: _fmtNum(_eleave?['totalLeaveDaysInYear']),
                              icon: Icons.calendar_month_rounded,
                              gradient: const [Color(0xFF26C6DA), Color(0xFF00838F)],
                              suffix: 'days',
                              decimalPlaces: 2,
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
                          childAspectRatio: 1.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metricCard(
                              label: 'Approved',
                              value: _fmtNum(_overtime?['approvedTicketCountInYear']),
                              icon: Icons.verified_rounded,
                              gradient: const [Color(0xFF7E57C2), Color(0xFF512DA8)],
                              suffix: 'records',
                            ),
                            _metricCard(
                              label: 'Total Hours',
                              value: _fmtNum(_overtime?['totalApprovedOTHoursInYear']),
                              icon: Icons.timelapse_rounded,
                              gradient: const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                              suffix: 'hours',
                              decimalPlaces: 2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Loading inline indicator đã được thay bằng LoadingOverlay
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
