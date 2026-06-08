import 'dart:async';

import 'package:flutter/material.dart';

class DigitalSignatureWaitingDialog extends StatefulWidget {
  final String documentName;
  final String signerName;
  final Duration timeout;
  final Future<Map<String, dynamic>?> Function() onSign;

  const DigitalSignatureWaitingDialog({
    super.key,
    required this.documentName,
    required this.signerName,
    required this.timeout,
    required this.onSign,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String documentName,
    required String signerName,
    required Future<Map<String, dynamic>?> Function() onSign,
    Duration timeout = const Duration(minutes: 2),
  }) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => DigitalSignatureWaitingDialog(
        documentName: documentName,
        signerName: signerName,
        timeout: timeout,
        onSign: onSign,
      ),
    );
  }

  @override
  State<DigitalSignatureWaitingDialog> createState() =>
      _DigitalSignatureWaitingDialogState();
}

class _DigitalSignatureWaitingDialogState
    extends State<DigitalSignatureWaitingDialog> {
  late final DateTime _startedAt;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _remainingSeconds = widget.timeout.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      final elapsed = DateTime.now().difference(_startedAt).inSeconds;
      setState(() {
        _remainingSeconds = (widget.timeout.inSeconds - elapsed).clamp(
          0,
          widget.timeout.inSeconds,
        );
      });
    });
    _runSigning();
  }

  Future<void> _runSigning() async {
    try {
      final response = await widget.onSign().timeout(widget.timeout);
      _finish(response);
    } on TimeoutException {
      _finish({
        'success': false,
        'messageType': 'error',
        'message':
            'Digital signature approval timed out. Please try again later.',
      });
    } catch (e) {
      _finish({
        'success': false,
        'messageType': 'error',
        'message': 'Digital signature failed: $e',
      });
    }
  }

  void _finish(Map<String, dynamic>? response) {
    if (!mounted || _finished) return;
    _finished = true;
    _timer?.cancel();
    Navigator.of(context, rootNavigator: true).pop(response);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    final total = widget.timeout.inSeconds;
    if (total <= 0) return 0;
    return ((total - _remainingSeconds) / total).clamp(0.0, 1.0);
  }

  String get _timeRemaining {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 560 ? width - 32 : 560.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatusPanel(),
              const SizedBox(height: 18),
              _buildTransactionDetails(),
              const SizedBox(height: 22),
              _buildProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDCE6F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'TRUE\nBPM',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B5CAD),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signing Process',
                style: TextStyle(
                  color: Color(0xFF1D2939),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'TRUETECH BPM',
                style: TextStyle(
                  color: Color(0xFF8493A8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2452E8)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Awaiting Digital Signature',
                  style: TextStyle(
                    color: Color(0xFF173B85),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'The BPM system is connecting to verify the electronic signature. Please keep this screen open during transaction processing.',
                  style: TextStyle(
                    color: Color(0xFF0D4BEF),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDDE6F0)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFCFF),
              border: Border(bottom: BorderSide(color: Color(0xFFDDE6F0))),
            ),
            child: const Text(
              'TRANSACTION DETAILS',
              style: TextStyle(
                color: Color(0xFF66758A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          _buildDetailRow(
            icon: Icons.description_outlined,
            label: 'Document',
            value: widget.documentName,
          ),
          _buildDetailRow(
            icon: Icons.person,
            label: 'Signer',
            value: widget.signerName,
          ),
          _buildDetailRow(
            icon: Icons.hourglass_bottom_outlined,
            label: 'Time Remaining',
            value: _timeRemaining,
            valueColor: const Color(0xFF0D4BEF),
            monospace: true,
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF1D2939),
    bool monospace = false,
    bool showBottomBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE7EEF6)))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF92A3BA)),
          const SizedBox(width: 14),
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5F718D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final percent = (_progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'WAITING PROGRESS',
                style: TextStyle(
                  color: Color(0xFF66758A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: Color(0xFF2452E8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: _progress,
            backgroundColor: const Color(0xFFEFF3F8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2452E8)),
          ),
        ),
      ],
    );
  }
}
