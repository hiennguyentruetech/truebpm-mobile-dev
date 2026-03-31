part of 'tab_doc_core_body_screen.dart';

extension TabDocCoreBodyPickerExt on _TabDocCoreBodyScreenState {
  Future<void> _pickFiles() async {
    // Show options for file picking using custom dialog style
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: const Color(0xFFF7FBFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 18,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD6E7F8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF3FF), Color(0xFFDDEFFF)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC9DFF7),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.folder_open,
                  size: 34,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Select Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Choose where to pick files from:',
                style: TextStyle(
                  fontSize: 15.5,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

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
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF1E88E5).withOpacity(0.35),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
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
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF1565C0).withOpacity(0.32),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Cancel'),
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
      _safeSetState(() => _isProcessing = true);

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

                _safeSetState(() {
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
                    content: Text(
                      'Error reading file ${platformFile.name}: $fileError',
                    ),
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

              _safeSetState(() {
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
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      _safeSetState(() => _isProcessing = true);

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

        _safeSetState(() {
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
          SnackBar(
            content: Text('Error picking from gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      _safeSetState(() => _isProcessing = true);

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
            final tempFile = File(
              '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
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

          _safeSetState(() {
            _selectedFiles.add(selectedFile);
            // Auto-expand upload area when files are selected
            if (!_isUploadAreaExpanded) {
              _isUploadAreaExpanded = true;
            }
          });

          // Clean up temp file if different from cropped
          if (processedFile.path != image.path &&
              processedFile.path != croppedFile.path) {
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

          _safeSetState(() {
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
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isProcessing = false);
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
    _safeSetState(() {
      _selectedFiles.removeAt(index);
    });
  }
}
