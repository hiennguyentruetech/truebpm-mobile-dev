part of 'tab_doc_core_body_screen.dart';

/// File model for selected files
class SelectedFile {
  final String name;
  final int size;
  final Uint8List bytes;
  final String? path;
  final String? revisionId;
  final String? revisionCode;
  final String? documentTypeId;
  final String? documentTypeName;

  SelectedFile({
    required this.name,
    required this.size,
    required this.bytes,
    this.path,
    this.revisionId,
    this.revisionCode,
    this.documentTypeId,
    this.documentTypeName,
  });

  /// Create a copy with updated revision/documentType info
  SelectedFile copyWith({
    String? name,
    int? size,
    Uint8List? bytes,
    String? path,
    String? revisionId,
    String? revisionCode,
    String? documentTypeId,
    String? documentTypeName,
  }) {
    return SelectedFile(
      name: name ?? this.name,
      size: size ?? this.size,
      bytes: bytes ?? this.bytes,
      path: path ?? this.path,
      revisionId: revisionId ?? this.revisionId,
      revisionCode: revisionCode ?? this.revisionCode,
      documentTypeId: documentTypeId ?? this.documentTypeId,
      documentTypeName: documentTypeName ?? this.documentTypeName,
    );
  }
}

/// Core tab body for Documents (DOC) - Reusable for all modules
/// Handles file upload, download, delete and view with stunning UI
class TabDocCoreBodyScreen extends CoreTabBody {
  final bool enableRevision;
  final bool enableDocumentType;
  final String? dataRevision;
  final String? dataDocumentType;

  const TabDocCoreBodyScreen({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
    this.enableRevision = false,
    this.enableDocumentType = false,
    this.dataRevision,
    this.dataDocumentType,
  });

  @override
  CoreTabBodyState<TabDocCoreBodyScreen> createState() =>
      _TabDocCoreBodyScreenState();
}

class _TabDocCoreBodyScreenState
    extends CoreTabBodyState<TabDocCoreBodyScreen> {
  // Response data
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  List<dynamic> _files = [];

  // File upload data
  List<SelectedFile> _selectedFiles = [];
  bool _isUploading = false;
  bool _isProcessing = false;
  bool _isUploadAreaExpanded = false;

  // Dropdown data for revision and documentType
  List<Map<String, dynamic>> _revisionOptions = [];
  List<Map<String, dynamic>> _documentTypeOptions = [];
  bool _isLoadingRevision = false;
  bool _isLoadingDocumentType = false;

  // No sub-tab state here anymore; handled by DetailCoreScreen

  @override
  void initState() {
    super.initState();
    // Use initial data from parent; provider updates will come via didUpdateWidget
    _updateDataFromInitialData();

    // Load dropdown data if options are enabled
    if (widget.enableRevision) {
      _loadRevisionOptions();
    }
    if (widget.enableDocumentType) {
      _loadDocumentTypeOptions();
    }
  }

  @override
  void didUpdateWidget(TabDocCoreBodyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _safeSetState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  void _updateDataFromInitialData() {
    if (widget.initialData != null) {
      _response = Map<String, dynamic>.from(widget.initialData!);
      _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
      _files = List<dynamic>.from(_itemDetail['files'] ?? []);

      _safeSetState(() {});
    }
  }

  /// Create SelectedFile with default revision and document type if enabled
  SelectedFile _createSelectedFileWithDefaults({
    required String name,
    required int size,
    required Uint8List bytes,
    String? path,
  }) {
    String? defaultRevisionId;
    String? defaultRevisionCode;
    String? defaultDocumentTypeId;
    String? defaultDocumentTypeName;

    // Set default revision if enabled and options are available
    if (widget.enableRevision && _revisionOptions.isNotEmpty) {
      final firstRevision = _revisionOptions.first;
      defaultRevisionId = firstRevision['id']?.toString();
      defaultRevisionCode = firstRevision['name']?.toString();
    }

    // Set default document type if enabled and options are available
    if (widget.enableDocumentType && _documentTypeOptions.isNotEmpty) {
      final firstDocumentType = _documentTypeOptions.first;
      defaultDocumentTypeId = firstDocumentType['id']?.toString();
      defaultDocumentTypeName = firstDocumentType['name']?.toString();
    }

    return SelectedFile(
      name: name,
      size: size,
      bytes: bytes,
      path: path,
      revisionId: defaultRevisionId,
      revisionCode: defaultRevisionCode,
      documentTypeId: defaultDocumentTypeId,
      documentTypeName: defaultDocumentTypeName,
    );
  }

  @override
  Widget buildTabContent(BuildContext context) {
    // Pull latest files from provider each build
    final provider = Provider.of<CoreDetailProvider>(context);
    final newData = provider.rawResponse;
    List<dynamic> files = _files;
    if (newData != null) {
      final itemDetail = Map<String, dynamic>.from(newData['itemDetail'] ?? {});
      files = List<dynamic>.from(itemDetail['files'] ?? []);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          _buildUploadArea(),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : files.isEmpty && _selectedFiles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index] as Map<String, dynamic>;
                      return _buildFileCard(file);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
