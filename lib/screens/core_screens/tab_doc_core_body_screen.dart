import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/dialogs/custom_confirm_dialog.dart';
import 'package:truebpm/widgets/loading_overlay.dart';
import 'package:truebpm/widgets/file_viewer_dialog.dart';

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
  CoreTabBodyState<TabDocCoreBodyScreen> createState() => _TabDocCoreBodyScreenState();
}

class _TabDocCoreBodyScreenState extends CoreTabBodyState<TabDocCoreBodyScreen> {
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

  void _updateDataFromInitialData() {
    if (widget.initialData != null) {
      _response = Map<String, dynamic>.from(widget.initialData!);
      _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
      _files = List<dynamic>.from(_itemDetail['files'] ?? []);
      
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  

  Future<void> _pickFiles() async {
    // Show options for file picking using custom dialog style
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Select Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'Choose where to pick files from:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Options
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('files'),
                      icon: const Icon(Icons.folder),
                      label: const Text('Device Storage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('gallery'),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Photo Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'files') {
      await _pickFromStorage();
    } else if (choice == 'gallery') {
      await _pickFromGallery();
    }
  }

  Future<void> _pickFromStorage() async {
    try {
      setState(() => _isProcessing = true);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
        withData: false, // Don't load data directly
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final platformFile in result.files) {
          // Read file from path instead of using bytes directly
          if (platformFile.path != null) {
            try {
              final file = File(platformFile.path!);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                
                final selectedFile = _createSelectedFileWithDefaults(
                  name: platformFile.name,
                  size: bytes.length,
                  bytes: bytes,
                  path: platformFile.path,
                );

                setState(() {
                  _selectedFiles.add(selectedFile);
                  // Auto-expand upload area when files are selected
                  if (!_isUploadAreaExpanded) {
                    _isUploadAreaExpanded = true;
                  }
                });
              } else {
                throw Exception('File not found at path: ${platformFile.path}');
              }
            } catch (fileError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error reading file ${platformFile.name}: $fileError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Fallback to using bytes if available
            if (platformFile.bytes != null) {
              final selectedFile = _createSelectedFileWithDefaults(
                name: platformFile.name,
                size: platformFile.size,
                bytes: platformFile.bytes!,
                path: null,
              );

              setState(() {
                _selectedFiles.add(selectedFile);
                if (!_isUploadAreaExpanded) {
                  _isUploadAreaExpanded = true;
                }
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultipleMedia(
        maxHeight: 1920,
        maxWidth: 1080,
        imageQuality: 85,
      );

      for (final image in images) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        
        final selectedFile = _createSelectedFileWithDefaults(
          name: image.name,
          size: bytes.length,
          bytes: bytes,
          path: image.path,
        );
        
        setState(() {
          _selectedFiles.add(selectedFile);
          // Auto-expand upload area when files are selected
          if (!_isUploadAreaExpanded) {
            _isUploadAreaExpanded = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking from gallery: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      setState(() => _isProcessing = true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        // Fix green tint issue by processing the image
        File processedFile = File(image.path);
        Uint8List processedBytes = await processedFile.readAsBytes();
        
        // Convert image to ensure proper color space (fix green tint)
        try {
          final originalImage = img.decodeImage(processedBytes);
          if (originalImage != null) {
            // Convert to RGB format to fix color issues
            final fixedImage = img.copyResize(
              originalImage,
              width: originalImage.width,
              height: originalImage.height,
              interpolation: img.Interpolation.linear,
            );
            
            // Save corrected image to temp file
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await tempFile.writeAsBytes(img.encodeJpg(fixedImage, quality: 85));
            
            processedFile = tempFile;
            processedBytes = await tempFile.readAsBytes();
          }
        } catch (imgError) {
          // If image processing fails, continue with original
          debugPrint('Image processing error: $imgError');
        }
        
        // Apply image cropping
        final croppedFile = await _cropImage(processedFile.path);
        
        if (croppedFile != null) {
          final croppedBytes = await File(croppedFile.path).readAsBytes();
          final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          final selectedFile = _createSelectedFileWithDefaults(
            name: fileName,
            size: croppedBytes.length,
            bytes: croppedBytes,
            path: croppedFile.path,
          );
          
          setState(() {
            _selectedFiles.add(selectedFile);
            // Auto-expand upload area when files are selected
            if (!_isUploadAreaExpanded) {
              _isUploadAreaExpanded = true;
            }
          });
          
          // Clean up temp file if different from cropped
          if (processedFile.path != image.path && processedFile.path != croppedFile.path) {
            try {
              await processedFile.delete();
            } catch (_) {}
          }
        } else {
          // User cancelled cropping, still use the processed image
          final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          final selectedFile = _createSelectedFileWithDefaults(
            name: fileName,
            size: processedBytes.length,
            bytes: processedBytes,
            path: processedFile.path,
          );
          
          setState(() {
            _selectedFiles.add(selectedFile);
            if (!_isUploadAreaExpanded) {
              _isUploadAreaExpanded = true;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF667EEA),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF667EEA),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            cropFrameColor: const Color(0xFF667EEA),
            cropGridColor: Colors.white.withOpacity(0.3),
            cropFrameStrokeWidth: 3,
            cropGridStrokeWidth: 1,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            resetButtonHidden: false,
            hidesNavigationBar: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );
      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
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

  /// Load revision dropdown data
  Future<void> _loadRevisionOptions() async {
    if (_revisionOptions.isNotEmpty || _isLoadingRevision || !widget.enableRevision) return;

    setState(() => _isLoadingRevision = true);

    try {
      // Use custom endpoint if provided, otherwise use default
      final apiKey = widget.dataRevision ?? 'DROPDOWN.RESOURCE/REVISION';

      final response = await CoreService.instance.getDropdownData(apiKey);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          setState(() {
            _revisionOptions = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading revision options: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingRevision = false);
    }
  }

  /// Load document type dropdown data
  Future<void> _loadDocumentTypeOptions() async {
    if (_documentTypeOptions.isNotEmpty || _isLoadingDocumentType || !widget.enableDocumentType) return;

    setState(() => _isLoadingDocumentType = true);

    try {
      // Use custom endpoint if provided, otherwise use default
      final apiKey = widget.dataDocumentType ?? 'DROPDOWN.PRJMGT/PROJECTDOCTYPE';

      final response = await CoreService.instance.getDropdownData(apiKey);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          setState(() {
            _documentTypeOptions = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document type options: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingDocumentType = false);
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty || _isUploading) return;

    setState(() => _isUploading = true);

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
      final currentSubTabCode = Provider.of<CoreDetailProvider>(context, listen: false).currentDocSubTabCode;

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
          subTabModuleCode: currentSubTabCode, // Pass subtab code separately for payload
          revisionId: file.revisionId,
          documentTypeId: file.documentTypeId,
        );

        if (response == null || response['success'] != true) {
          throw Exception('Failed to upload ${file.name}: ${response?['message'] ?? 'Unknown error'}');
        }

        // Keep the last successful response to update UI
        lastSuccessfulResponse = response;
      }

      // Clear selected files after successful upload
      setState(() {
        _selectedFiles.clear();
      });

      // Update data using the last upload response instead of calling API again
      if (mounted && lastSuccessfulResponse != null) {
        final provider2 = Provider.of<CoreDetailProvider>(context, listen: false);

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
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    try {
      LoadingOverlay.show(context, message: 'Downloading...');
      setState(() => _isProcessing = true);

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
        subTabModuleCode: currentSubTabCode, // Pass subtab code separately for payload
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
          final fileType = file['fileType']?.toString() ?? 'application/octet-stream';
          
          // Hide loading overlay before showing dialog
          LoadingOverlay.hide();
          setState(() => _isProcessing = false);
          
          await FileViewerDialog.showFileOptionsDialog(
            context: context,
            fileName: fileName,
            fileType: fileType,
            bytes: bytes,
            fileInfo: file,
            onSaveToDevice: (context, fileName, bytes) async => await _saveFileToDevice(fileName, bytes),
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
        setState(() => _isProcessing = false);
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
        m == 'text/markdown') return 'text';

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
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
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
      message: 'Are you sure you want to delete "$fileName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {},
    );
    if (confirmed == null || confirmed == false) return;

    try {
      LoadingOverlay.show(context, message: 'Deleting...');
      setState(() => _isProcessing = true);

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

      if (response != null && (response['success'] == true || response['itemDetail'] != null)) {
        // Update the local data from response similar to module tab load
        if (response['itemDetail'] != null) {
          setState(() {
            _response = response;
            _itemDetail = Map<String, dynamic>.from(response['itemDetail'] ?? {});
            _files = List<dynamic>.from(_itemDetail['files'] ?? []);
          });

          // Update provider with new data
          final provider = Provider.of<CoreDetailProvider>(context, listen: false);
          provider.updateRawResponse(response);

          if (widget.onDataChanged != null) {
            widget.onDataChanged!(response);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted $fileName'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception(response?['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        LoadingOverlay.hide();
        setState(() => _isProcessing = false);
      }
    }
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
          colors: [
            Colors.purple.shade50,
            Colors.white,
          ],
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
  
  
  Widget _buildUploadArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Always visible)
          // Make the whole header tappable with ripple
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _isUploadAreaExpanded = !_isUploadAreaExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Documents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Tap to expand upload options',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selected files count badge
                    if (_selectedFiles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedFiles.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isUploadAreaExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isUploadAreaExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isUploadAreaExpanded ? 1.0 : 0.0,
              child: _isUploadAreaExpanded ? Container(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 5),
                child: Column(
                  children: [
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.folder_open,
                            label: 'Files & Gallery',
                            onTap: _pickFiles,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onTap: _pickFromCamera,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Selected Files
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSelectedFilesList(),
                      const SizedBox(height: 12),
                      _buildUploadButton(),
                    ],
                  ],
                ),
              ) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _isProcessing ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]) : gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isProcessing ? [] : [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSelectedFilesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(file.name),
                  color: Colors.blue.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        softWrap: true,
                      ),
                      Text(
                        _formatFileSize(file.size),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // Revision and Document Type dropdowns in same row
                      if (widget.enableRevision || widget.enableDocumentType) ...[
                        const SizedBox(height: 4),
                        _buildFileDropdownsRow(index),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeSelectedFile(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade400,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileDropdownsRow(int fileIndex) {
    return Row(
      children: [
        // Revision dropdown
        if (widget.enableRevision) ...[
          Expanded(
            child: _buildFileRevisionDropdown(fileIndex),
          ),
          if (widget.enableDocumentType) const SizedBox(width: 6),
        ],
        // Document Type dropdown
        if (widget.enableDocumentType) ...[
          Expanded(
            child: _buildFileDocumentTypeDropdown(fileIndex),
          ),
        ],
      ],
    );
  }

  Widget _buildFileRevisionDropdown(int fileIndex) {
    final file = _selectedFiles[fileIndex];
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: file.revisionId,
          hint: Text(
            'Revision',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          items: _revisionOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['id']?.toString(),
              child: Text(
                option['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final selectedOption = _revisionOptions.firstWhere(
                (option) => option['id']?.toString() == value,
                orElse: () => {},
              );
              setState(() {
                _selectedFiles[fileIndex] = file.copyWith(
                  revisionId: value,
                  revisionCode: selectedOption['name']?.toString(),
                );
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFileDocumentTypeDropdown(int fileIndex) {
    final file = _selectedFiles[fileIndex];
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: file.documentTypeId,
          hint: Text(
            'Doc Type',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          items: _documentTypeOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['id']?.toString(),
              child: Text(
                option['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final selectedOption = _documentTypeOptions.firstWhere(
                (option) => option['id']?.toString() == value,
                orElse: () => {},
              );
              setState(() {
                _selectedFiles[fileIndex] = file.copyWith(
                  documentTypeId: value,
                  documentTypeName: selectedOption['name']?.toString(),
                );
              });
            }
          },
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _uploadFiles,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _isUploading
              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
              : const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isUploading ? [] : [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              _isUploading ? 'Uploading...' : 'Upload ${_selectedFiles.length} file(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first document!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileName = file['fileName']?.toString() ?? 'Unknown File';
    final fileSize = file['fileSize'] ?? 0;
    final fileType = file['fileType']?.toString() ?? '';
    final createdDate = file['createdDate']?.toString();
    final revisionCode = file['revisionCode']?.toString();
    final documentTypeName = file['documentTypeName']?.toString();
    final revisionName = file['revisionName']?.toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            // File Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _getFileTypeColor(fileType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(fileType),
                color: _getFileTypeColor(fileType),
                size: 22,
              ),
            ),
            
            const SizedBox(width: 5),
            
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (createdDate != null) ...[
                        Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                        Text(
                          _formatUploadDate(createdDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Show revision and document type info if available
                  if (revisionCode != null || documentTypeName != null || revisionName != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (revisionCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Rev: $revisionCode',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (revisionName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Revison: $revisionName',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (documentTypeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              'Type: $documentTypeName',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFileActionButton(
                  icon: Icons.download,
                  color: Colors.blue,
                  onTap: () => _downloadFile(file),
                ),
                const SizedBox(width: 8),
                _buildFileActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => _deleteFile(file),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: color,
          size: 17,
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType, {String? fileName}) {
    final category = _classifyMime(_resolveMime(fileType, fileName));
    switch (category) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'text':
        return Icons.article_outlined;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.grid_on;
      case 'powerpoint':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType, {String? fileName}) {
    final category = _classifyMime(_resolveMime(fileType, fileName));
    switch (category) {
      case 'image':
        return Colors.green;
      case 'pdf':
        return Colors.red;
      case 'text':
        return Colors.indigo;
      case 'word':
        return Colors.blue;
      case 'excel':
        return Colors.teal;
      case 'powerpoint':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatUploadDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
