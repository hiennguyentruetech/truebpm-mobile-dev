import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
// Removed native PDF viewer to avoid native .so page size issues on Android 15+
import 'package:open_filex/open_filex.dart';

/// A comprehensive file viewer dialog that supports multiple file types
/// including images, PDFs, text files, and Office documents
class FileViewerDialog {
  /// Shows a professional file options dialog with view, download, and open capabilities
  static Future<void> showFileOptionsDialog({
    required BuildContext context,
    required String fileName,
    required String fileType,
    required Uint8List bytes,
    required Map<String, dynamic> fileInfo,
    required Function(BuildContext, String, Uint8List) onSaveToDevice,
  }) async {
  final classification = _classifyMime(_resolveMime(fileType, fileName));
  final isOffice = classification == 'word' || classification == 'excel' || classification == 'powerpoint';
  final isPdf = classification == 'pdf';

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
              // File Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(fileType).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFileTypeIcon(fileType),
                  size: 32,
                  color: _getFileTypeColor(fileType),
                ),
              ),
              const SizedBox(height: 16),
              
              // File Name
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // File Info
              Text(
                '${_formatFileSize(bytes.length)} • ${_getFileTypeDisplayName(fileType, fileName: fileName)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Column(
                children: [
                  // View File Button (if supported)
                  if (_isViewableFileType(fileType)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop('view'),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View File'),
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
                  ],
                  
                  if (isOffice || isPdf) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop('open'),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in another app'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('download'),
                      icon: const Icon(Icons.download),
                      label: const Text('Download to Device'),
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
                  
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

    if (!context.mounted) return;

    // Handle user choice
    if (choice == 'view') {
      await _viewFile(context, fileName, fileType, bytes, fileInfo, onSaveToDevice);
    } else if (choice == 'download') {
      await onSaveToDevice(context, fileName, bytes);
    } else if (choice == 'open') {
      await _openWithSystemApp(fileName, bytes, context);
    }
  }

  // MIME type detection and classification methods
  static String _resolveMime(String fileType, String? fileName) {
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

  static String _mimeFromExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      // Microsoft Office
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'docm':
        return 'application/vnd.ms-word.document.macroEnabled.12';
      case 'dotx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.template';
      case 'dotm':
        return 'application/vnd.ms-word.template.macroEnabled.12';
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

  static String _classifyMime(String mime) {
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

  static bool _isViewableFileType(String fileType) {
    final category = _classifyMime(_resolveMime(fileType, null));
  // Only allow in-app view for image and text. PDF will be opened with system apps.
  return category == 'image' || category == 'text';
  }

  static String _getFileTypeDisplayName(String fileType, {String? fileName}) {
    final category = _classifyMime(_resolveMime(fileType, fileName));
    switch (category) {
      case 'image':
        return 'Image';
      case 'pdf':
        return 'PDF Document';
      case 'text':
        return 'Text Document';
      case 'word':
        return 'Word Document';
      case 'excel':
        return 'Excel Spreadsheet';
      case 'powerpoint':
        return 'PowerPoint Presentation';
      default:
        return 'Document';
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Color _getFileTypeColor(String fileType) {
    final category = _classifyMime(_resolveMime(fileType, null));
    switch (category) {
      case 'image':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'text':
        return Colors.blue;
      case 'word':
        return Colors.blue.shade700;
      case 'excel':
        return Colors.green.shade700;
      case 'powerpoint':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  static IconData _getFileTypeIcon(String fileType) {
    final category = _classifyMime(_resolveMime(fileType, null));
    switch (category) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'text':
        return Icons.description;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.table_chart;
      case 'powerpoint':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  // File viewing and opening methods
  static Future<void> _viewFile(
    BuildContext context,
    String fileName,
    String fileType,
    Uint8List bytes,
    Map<String, dynamic> fileInfo,
    Function(BuildContext, String, Uint8List) onSaveToDevice,
  ) async {
    try {
      final category = _classifyMime(_resolveMime(fileType, fileName));
      if (category == 'image') {
        await _showProfessionalImageViewer(context, fileName, bytes, fileInfo, onSaveToDevice);
      } else if (category == 'pdf') {
        // Open PDFs with installed apps instead of in-app viewing
        await _openWithSystemApp(fileName, bytes, context);
      } else if (category == 'text') {
        await _showTextViewer(context, fileName, bytes, fileInfo, onSaveToDevice);
      } else if (category == 'word' || category == 'excel' || category == 'powerpoint') {
        await _showDocumentViewer(context, fileName, fileType, bytes, fileInfo, onSaveToDevice);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewer for ${_getFileTypeDisplayName(fileType, fileName: fileName)} coming soon'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _openWithSystemApp(String fileName, Uint8List bytes, BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final f = File(tempPath);
      await f.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(tempPath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: ${result.message}'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> _showProfessionalImageViewer(
    BuildContext context,
    String fileName,
    Uint8List bytes,
    Map<String, dynamic> fileInfo,
    Function(BuildContext, String, Uint8List) onSaveToDevice,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                onPressed: () => onSaveToDevice(context, fileName, bytes),
                icon: const Icon(Icons.download),
                tooltip: 'Download',
              ),
            ],
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: MemoryImage(bytes),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.5,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                heroAttributes: PhotoViewHeroAttributes(tag: fileName),
              );
            },
            itemCount: 1,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 60.0,
                height: 60.0,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  static Future<void> _showTextViewer(
    BuildContext context,
    String fileName,
    Uint8List bytes,
    Map<String, dynamic> fileInfo,
    Function(BuildContext, String, Uint8List) onSaveToDevice,
  ) async {
    try {
      final content = String.fromCharCodes(bytes);

      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  fileName,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    onPressed: () => onSaveToDevice(context, fileName, bytes),
                    icon: const Icon(Icons.download),
                    tooltip: 'Download',
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Info bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.indigo.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.article_outlined, color: Colors.indigo.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Text Document - ${_formatFileSize(bytes.length)}',
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          content,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing text file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _showDocumentViewer(
    BuildContext context,
    String fileName,
    String fileType,
    Uint8List bytes,
    Map<String, dynamic> fileInfo,
    Function(BuildContext, String, Uint8List) onSaveToDevice,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                onPressed: () => onSaveToDevice(context, fileName, bytes),
                icon: const Icon(Icons.download),
                tooltip: 'Download',
              ),
            ],
          ),
          body: Column(
            children: [
              // Info bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document viewer - Download for full functionality',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Placeholder content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _getFileTypeColor(fileType).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getFileTypeIcon(fileType),
                          size: 60,
                          color: _getFileTypeColor(fileType),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getFileTypeDisplayName(fileType, fileName: fileName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview not available for this document type.\nDownload the file to view it with appropriate software.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSaveToDevice(context, fileName, bytes);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getFileTypeColor(fileType),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PDF viewer uses flutter_pdfview native component
