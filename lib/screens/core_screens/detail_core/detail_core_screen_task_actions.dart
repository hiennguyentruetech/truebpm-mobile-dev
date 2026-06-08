part of 'detail_core_screen.dart';

extension _DetailCoreScreenTaskActionsExt on _DetailCoreScreenState {
  /// Build task approval footer for screens opened from task list
  Widget? _buildTaskFooter(CoreDetailProvider provider) {
    // Get button labels and visibility from API response
    final response = provider.rawResponse ?? {};
    final itemDetail = response['itemDetail'] ?? {};
    final itemValue = itemDetail['value'] ?? {};
    final statusData = itemValue['status'] ?? {};

    final rejectLabel = statusData['rejectButtonLabel']?.toString() ?? 'Reject';
    final approveLabel =
        statusData['approveButtonLabel']?.toString() ?? 'Approve';
    final isRejectHidden = statusData['isRejectHidden'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 7),
          child: Row(
            children: [
              // Reject Button (conditionally visible)
              if (!isRejectHidden) ...[
                Expanded(
                  child: _buildTaskButton(
                    label: rejectLabel,
                    onPressed: () => _handleRejectTask(provider),
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // Approve Button
              Expanded(
                child: _buildTaskButton(
                  label: approveLabel,
                  onPressed: () => _handleApproveTask(provider),
                  backgroundColor: const Color(0xFF38A169),
                  foregroundColor: Colors.white,
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual task action button with professional design and touch animation
  Widget _buildTaskButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
  }) {
    return TouchableOpacity(
      onTap: onPressed,
      opacity: 0.4, // Touch animation opacity
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle reject task action
  Future<void> _handleRejectTask(CoreDetailProvider provider) async {
    // Ensure we have a task ID
    if (widget.taskId == null || widget.taskId!.isEmpty) {
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'error',
          'message': 'Task ID is not available for this operation',
        },
        title: 'Reject Task',
      );
      return;
    }

    try {
      provider.setLoadingOverlay(true);

      // Get required data for payload
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();

      // Call API with reject action (always use DTLS tab for task actions)
      final response = await CoreService.instance.performTaskAction(
        widget.moduleCode,
        'DTLS', // Always use DTLS tab for task actions
        userData,
        itemDetail,
        dataSpy,
        widget.taskId!,
        false, // isApproved = false for reject
      );

      if (mounted && response != null) {
        // Update data directly from response if successful
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Reject Task',
          onSuccess: () {
            // Navigate back to task list after successful rejection
            Navigator.of(context).pop();
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Reject operation failed or session expired',
          },
          title: 'Reject Task',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Reject failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Reject operation failed due to an unexpected error';
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Reject Task',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  /// Handle approve task action
  Future<void> _handleApproveTask(CoreDetailProvider provider) async {
    // Ensure we have a task ID
    if (widget.taskId == null || widget.taskId!.isEmpty) {
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'error',
          'message': 'Task ID is not available for this operation',
        },
        title: 'Approve Task',
      );
      return;
    }

    try {
      provider.setLoadingOverlay(true);

      // Get required data for payload
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();

      if (_usesDigitalSignatureApproval(widget.moduleCode)) {
        provider.setLoadingOverlay(false);
        final signatureResponse = await _handleDigitalSignatureApproval(
          userData: userData,
          itemDetail: itemDetail,
        );
        if (!mounted) return;

        if (signatureResponse == null || signatureResponse['success'] != true) {
          CoreActionDialog.showResponseDialog(
            context,
            response:
                signatureResponse ??
                {
                  'success': false,
                  'messageType': 'error',
                  'message':
                      'Digital signature failed or session expired. Approval was not submitted.',
                },
            title: 'Digital Signature',
          );
          return;
        }

        provider.setLoadingOverlay(true);
      }

      // Call API with approve action (always use DTLS tab for task actions)
      final response = await CoreService.instance.performTaskAction(
        widget.moduleCode,
        'DTLS', // Always use DTLS tab for task actions
        userData,
        itemDetail,
        dataSpy,
        widget.taskId!,
        true, // isApproved = true for approve
      );

      if (mounted && response != null) {
        // Update data directly from response if successful
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Approve Task',
          onSuccess: () {
            // Navigate back to task list after successful approval
            Navigator.of(context).pop();
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Approve operation failed or session expired',
          },
          title: 'Approve Task',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Approve failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Approve operation failed due to an unexpected error';
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Approve Task',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  bool _usesDigitalSignatureApproval(String moduleCode) {
    const modules = {'ESIGNG'};
    return modules.contains(moduleCode.toUpperCase());
  }

  Future<Map<String, dynamic>?> _handleDigitalSignatureApproval({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> itemDetail,
  }) async {
    final document = _getDigitalSignatureDocument(itemDetail);
    final documentName = document?['fileName']?.toString().trim() ?? '';
    final signerName =
        userData['fullName']?.toString().trim().isNotEmpty == true
        ? userData['fullName'].toString().trim()
        : userData['code']?.toString().trim() ?? '';

    return DigitalSignatureWaitingDialog.show(
      context,
      documentName: documentName,
      signerName: signerName,
      timeout: const Duration(minutes: 2),
      onSign: () => CoreService.instance.signPdfForm(
        moduleCode: widget.moduleCode,
        user: userData,
        itemDetail: itemDetail,
      ),
    );
  }

  Map<String, dynamic>? _getDigitalSignatureDocument(
    Map<String, dynamic> itemDetail,
  ) {
    final value = itemDetail['value'];
    if (value is! Map) return null;

    for (final key in const [
      'documentsNext',
      'documentsAssignees',
      'documents',
    ]) {
      final docs = value[key];
      if (docs is List && docs.isNotEmpty) {
        final first = docs.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }
}
