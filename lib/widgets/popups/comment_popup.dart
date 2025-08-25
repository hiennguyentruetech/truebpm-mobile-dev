import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';

/// Comment Popup Modal - Reuses TabCmtCoreBodyScreen
class CommentPopup extends StatefulWidget {
  final String moduleCode;
  final String tabModuleCode;
  final Map<String, dynamic> listItem;
  final UserModel userInfo;

  const CommentPopup({
    super.key,
    required this.moduleCode,
    required this.tabModuleCode,
    required this.listItem,
    required this.userInfo,
  });

  @override
  State<CommentPopup> createState() => _CommentPopupState();
}

class _CommentPopupState extends State<CommentPopup> {
  late CoreDetailProvider _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() async {
    try {
      _provider = CoreDetailProvider();

      // Initialize provider with the data
      await _provider.initialize(
        widget.moduleCode,
        widget.listItem,
        tabModuleCode: widget.tabModuleCode,
        onSessionExpired: () {
          // Handle session expired
          Navigator.of(context).pop();
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.comment_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View and add comments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ChangeNotifierProvider.value(
                      value: _provider,
                      child: Consumer<CoreDetailProvider>(
                        builder: (context, provider, child) {
                          return TabCmtCoreBodyScreen(
                            moduleCode: widget.moduleCode,
                            tabCode: widget.tabModuleCode,
                            initialData: provider.rawResponse,
                            onDataChanged: (data) {
                              // Handle data changes if needed
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
