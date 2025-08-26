import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';

/// Document Popup Modal - Reuses TabDocCoreBodyScreen
class DocumentPopup extends StatefulWidget {
  final String moduleCode;
  final String tabModuleCode;
  final Map<String, dynamic> listItem;
  final UserModel userInfo;

  const DocumentPopup({
    super.key,
    required this.moduleCode,
    required this.tabModuleCode,
    required this.listItem,
    required this.userInfo,
  });

  @override
  State<DocumentPopup> createState() => _DocumentPopupState();
}

class _DocumentPopupState extends State<DocumentPopup> {
  late CoreDetailProvider _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() async {
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
                  colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade700],
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
                      Icons.folder_outlined,
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
                          'Documents',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage files and documents',
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
                          return TabDocCoreBodyScreen(
                            moduleCode: widget.moduleCode,
                            tabCode: widget.tabModuleCode,
                            initialData: provider.rawResponse,
                            enableRevision: true,
                            enableDocumentType: true,
                            dataRevision: 'DROPDOWN.RESOURCE/REVISION',
                            dataDocumentType: 'DROPDOWN.PRJMGT/PROJECTDOCTYPE',
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
