part of 'tab_doc_core_body_screen.dart';

extension TabDocCoreBodyTransferExt on _TabDocCoreBodyScreenState {
  /// Load revision dropdown data
  Future<void> _loadRevisionOptions() async {
    if (_revisionOptions.isNotEmpty ||
        _isLoadingRevision ||
        !widget.enableRevision) {
      return;
    }

    _safeSetState(() => _isLoadingRevision = true);

    try {
      // Use custom endpoint if provided, otherwise use default
      final apiKey = widget.dataRevision ?? 'DROPDOWN.RESOURCE/REVISION';

      final response = await CoreService.instance.getDropdownData(apiKey);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          _safeSetState(() {
            _revisionOptions = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading revision options: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isLoadingRevision = false);
    }
  }

  /// Load document type dropdown data
  Future<void> _loadDocumentTypeOptions() async {
    if (_documentTypeOptions.isNotEmpty ||
        _isLoadingDocumentType ||
        !widget.enableDocumentType) {
      return;
    }

    _safeSetState(() => _isLoadingDocumentType = true);

    try {
      // Use custom endpoint if provided, otherwise use default
      final apiKey =
          widget.dataDocumentType ?? 'DROPDOWN.PRJMGT/PROJECTDOCTYPE';

      final response = await CoreService.instance.getDropdownData(apiKey);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          _safeSetState(() {
            _documentTypeOptions = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading document type options: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isLoadingDocumentType = false);
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty || _isUploading) return;

    _safeSetState(() => _isUploading = true);

    try {
      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();
      final provider = Provider.of<CoreDetailProvider>(context, listen: false);
      final currentData = provider.rawResponse;

      if (currentData == null) {
        throw Exception('No data available for upload');
      }

      if (userInfo == null) {
        throw Exception('User information not available');
      }

      // Upload files one by one using the specialized uploadFile method
      Map<String, dynamic>? lastSuccessfulResponse;
      final currentSubTabCode = Provider.of<CoreDetailProvider>(
        context,
        listen: false,
      ).currentDocSubTabCode;

      for (final file in _selectedFiles) {
        final response = await CoreService.instance.uploadFile(
          widget.moduleCode,
          file.name,
          file.bytes,
          userInfo.id,
          userInfo.code,
          currentData['itemDetail']?['value']?['id'] ?? '',
          currentData['itemDetail']?['value']?['code'] ?? '',
          tabModuleCode: widget.tabCode, // Always use main tab code for URL
          subTabModuleCode:
              currentSubTabCode, // Pass subtab code separately for payload
          revisionId: file.revisionId,
          documentTypeId: file.documentTypeId,
        );

        if (response == null || response['success'] != true) {
          throw Exception(
            'Failed to upload ${file.name}: ${response?['message'] ?? 'Unknown error'}',
          );
        }

        // Keep the last successful response to update UI
        lastSuccessfulResponse = response;
      }

      // Clear selected files after successful upload
      _safeSetState(() {
        _selectedFiles.clear();
      });

      // Update data using the last upload response instead of calling API again
      if (mounted && lastSuccessfulResponse != null) {
        final provider2 = Provider.of<CoreDetailProvider>(
          context,
          listen: false,
        );

        // Use the response data from upload to update the provider
        // This avoids an extra API call since upload response contains updated data
        provider2.updateRawResponse(lastSuccessfulResponse);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Files uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      //       print('🔥 [DOC TAB] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _safeSetState(() => _isUploading = false);
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    try {
      LoadingOverlay.show(context, message: 'Downloading...');
      _safeSetState(() => _isProcessing = true);

      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();
      if (userInfo == null) {
        throw Exception('User information not available');
      }

      // Convert userInfo to Map format required by API
      final userInfoMap = {
        'id': userInfo.id,
        'code': userInfo.code,
        'fullName': userInfo.fullName,
        'phone': userInfo.phone,
        'email': userInfo.email,
        'personalEmail': userInfo.personalEmail,
        'position': userInfo.position,
        'createdDate': userInfo.createdDate,
        'managerFullName': userInfo.managerFullName,
        'roles': userInfo.roles,
      };

      // Get current sub-tab code from provider if DOC has sub-tabs
      final provider = Provider.of<CoreDetailProvider>(context, listen: false);
      final currentSubTabCode = provider.currentDocSubTabCode;

      final response = await CoreService.downloadFile(
        widget.moduleCode,
        userInfoMap,
        file,
        tabModuleCode: widget.tabCode, // Always use main tab code for URL
        subTabModuleCode:
            currentSubTabCode, // Pass subtab code separately for payload
      );

      // Accept both structures: with or without 'success' flag
      if (response != null) {
        // Extract base64 data from response (expected under key 'data')
        final dynamic raw = response['data'] ?? response['value']?['data'];
        if (raw != null && raw.toString().isNotEmpty) {
          // Some APIs may return data URIs; handle both pure base64 and data URI
          String dataStr = raw.toString();
          if (dataStr.contains(',')) {
            // Take the part after the comma if present (data:<mime>;base64,<data>)
            dataStr = dataStr.split(',').last;
          }
          final bytes = base64Decode(dataStr);

          final fileName = file['fileName']?.toString() ?? 'downloaded_file';
          final fileType =
              file['fileType']?.toString() ?? 'application/octet-stream';

          // Hide loading overlay before showing dialog
          LoadingOverlay.hide();
          _safeSetState(() => _isProcessing = false);

          await FileViewerDialog.showFileOptionsDialog(
            context: context,
            fileName: fileName,
            fileType: fileType,
            bytes: bytes,
            fileInfo: file,
            onSaveToDevice: (context, fileName, bytes) async =>
                await _saveFileToDevice(fileName, bytes),
          );
        } else {
          throw Exception('No file data received from server');
        }
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Only hide loading if still showing (in case of error)
        if (LoadingOverlay.isShowing) {
          LoadingOverlay.hide();
        }
        _safeSetState(() => _isProcessing = false);
      }
    }
  }

  // MIME helpers
  String _resolveMime(String fileType, String? fileName) {
    String mime = fileType.trim().toLowerCase();
    if (mime.isEmpty || !mime.contains('/')) {
      // Fallback to extension-based guess
      final ext = (fileName ?? '').split('.').length > 1
          ? fileName!.split('.').last.toLowerCase()
          : '';
      final guessed = _mimeFromExtension(ext);
      if (guessed.isNotEmpty) return guessed;
      return 'application/octet-stream';
    }
    return mime;
  }

  String _mimeFromExtension(String ext) {
    switch (ext) {
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'rtf':
        return 'application/rtf';
      case 'epub':
        return 'application/epub+zip';
      // Word
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'docm':
        return 'application/vnd.ms-word.document.macroEnabled.12';
      case 'dot':
        return 'application/msword';
      case 'dotx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.template';
      case 'dotm':
        return 'application/vnd.ms-word.template.macroEnabled.12';
      // Excel
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xlsm':
        return 'application/vnd.ms-excel.sheet.macroEnabled.12';
      case 'xltx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.template';
      case 'xltm':
        return 'application/vnd.ms-excel.template.macroEnabled.12';
      case 'xlam':
        return 'application/vnd.ms-excel.addin.macroEnabled.12';
      case 'xlsb':
        return 'application/vnd.ms-excel.sheet.binary.macroEnabled.12';
      case 'csv':
        return 'text/csv';
      case 'tsv':
        return 'text/tab-separated-values';
      // PowerPoint
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'pptm':
        return 'application/vnd.ms-powerpoint.presentation.macroEnabled.12';
      case 'potx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.template';
      case 'potm':
        return 'application/vnd.ms-powerpoint.template.macroEnabled.12';
      case 'pps':
        return 'application/vnd.ms-powerpoint';
      case 'ppsx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.slideshow';
      case 'ppsm':
        return 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12';
      // OpenDocument
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'ott':
        return 'application/vnd.oasis.opendocument.text-template';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'ots':
        return 'application/vnd.oasis.opendocument.spreadsheet-template';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';
      case 'otp':
        return 'application/vnd.oasis.opendocument.presentation-template';
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'webp':
        return 'image/webp';
      case 'svg':
      case 'svgz':
        return 'image/svg+xml';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      // Text / Markup
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'yaml':
      case 'yml':
        return 'application/x-yaml';
      default:
        return '';
    }
  }

  String _classifyMime(String mime) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return 'image';
    if (m == 'application/pdf') return 'pdf';
    if (m.startsWith('text/') ||
        m == 'application/json' ||
        m == 'application/xml' ||
        m == 'application/x-yaml' ||
        m == 'text/csv' ||
        m == 'text/tab-separated-values' ||
        m == 'text/markdown') {
      return 'text';
    }

    const wordMimes = {
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-word.document.macroEnabled.12',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
      'application/vnd.ms-word.template.macroEnabled.12',
      'application/vnd.oasis.opendocument.text',
      'application/vnd.oasis.opendocument.text-template',
    };
    const excelMimes = {
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel.sheet.macroEnabled.12',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
      'application/vnd.ms-excel.template.macroEnabled.12',
      'application/vnd.ms-excel.addin.macroEnabled.12',
      'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
      'application/vnd.oasis.opendocument.spreadsheet',
      'application/vnd.oasis.opendocument.spreadsheet-template',
      'text/csv',
      'text/tab-separated-values',
    };
    const pptMimes = {
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.ms-powerpoint.presentation.macroEnabled.12',
      'application/vnd.openxmlformats-officedocument.presentationml.template',
      'application/vnd.ms-powerpoint.template.macroEnabled.12',
      'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
      'application/vnd.ms-powerpoint.slideshow.macroEnabled.12',
      'application/vnd.oasis.opendocument.presentation',
      'application/vnd.oasis.opendocument.presentation-template',
    };

    if (wordMimes.contains(m)) return 'word';
    if (excelMimes.contains(m)) return 'excel';
    if (pptMimes.contains(m)) return 'powerpoint';

    return 'other';
  }

  Future<void> _saveFileToDevice(String fileName, Uint8List bytes) async {
    try {
      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory?.path}/Download';

      // Create downloads directory if it doesn't exist
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create file with unique name if needed
      String finalFileName = fileName;
      String filePath = '$downloadsPath/$finalFileName';
      int counter = 1;

      while (await File(filePath).exists()) {
        final nameWithoutExt = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        final extension = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        finalFileName = '${nameWithoutExt}_$counter$extension';
        filePath = '$downloadsPath/$finalFileName';
        counter++;
      }

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to Downloads: $finalFileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final fileName = file['fileName']?.toString() ?? 'this file';

    final confirmed = await CustomConfirmDialog.showDelete(
      context,
      title: 'Delete File',
      message:
          'Are you sure you want to delete "$fileName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {},
    );
    if (confirmed == null || confirmed == false) return;

    try {
      LoadingOverlay.show(context, message: 'Deleting...');
      _safeSetState(() => _isProcessing = true);

      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();
      if (userInfo == null) {
        throw Exception('User information not available');
      }

      // Convert userInfo to Map format required by API
      final userInfoMap = {
        'id': userInfo.id,
        'code': userInfo.code,
        'fullName': userInfo.fullName,
        'phone': userInfo.phone,
        'email': userInfo.email,
        'personalEmail': userInfo.personalEmail,
        'position': userInfo.position,
        'createdDate': userInfo.createdDate,
        'managerFullName': userInfo.managerFullName,
        'roles': userInfo.roles,
      };

      // Get current sub-tab code from provider if DOC has sub-tabs
      final provider = Provider.of<CoreDetailProvider>(context, listen: false);
      final subTabCode = provider.currentDocSubTabCode;

      final response = await CoreService.deleteFile(
        widget.moduleCode,
        userInfoMap,
        file,
        tabModuleCode: widget.tabCode, // Always use main tab code for URL
        subTabCode: subTabCode, // Pass subtab code for payload
      );

      if (response != null &&
          (response['success'] == true || response['itemDetail'] != null)) {
        // Update the local data from response similar to module tab load
        if (response['itemDetail'] != null) {
          _safeSetState(() {
            _response = response;
            _itemDetail = Map<String, dynamic>.from(
              response['itemDetail'] ?? {},
            );
            _files = List<dynamic>.from(_itemDetail['files'] ?? []);
          });

          // Update provider with new data
          final provider = Provider.of<CoreDetailProvider>(
            context,
            listen: false,
          );
          provider.updateRawResponse(response);

          if (widget.onDataChanged != null) {
            widget.onDataChanged!(response);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response?['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide();
        _safeSetState(() => _isProcessing = false);
      }
    }
  }
}
