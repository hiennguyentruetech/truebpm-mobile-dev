import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_dynamic_fields.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/widgets/loading_overlay.dart';
import 'package:truebpm/widgets/file_viewer_dialog.dart';

/// Tab body for PRJMGT FOLDEREXPLORER (Folder Explorer)
class ProjectManagementFolderExplorerTabBody extends CoreTabBody {
  const ProjectManagementFolderExplorerTabBody({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<ProjectManagementFolderExplorerTabBody> createState() => _ProjectManagementFolderExplorerTabBodyState();
}

class _ProjectManagementFolderExplorerTabBodyState extends CoreTabBodyState<ProjectManagementFolderExplorerTabBody> {
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  Map<String, dynamic> _moduleData = {};

  @override
  void initState() {
    super.initState();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(ProjectManagementFolderExplorerTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _moduleData = Map<String, dynamic>.from(_itemDetail['value'] ?? {});

    // Ensure tree structure exists
    if (!_itemDetail.containsKey('tree')) {
      _itemDetail['tree'] = {'data': []};
    }

    if (mounted) setState(() {});
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _itemDetail[key] = value;
      _response['itemDetail'] = _itemDetail;
    });

    if (widget.onDataChanged != null) {
      widget.onDataChanged!(_response);
    }
  }

  Map<String, dynamic> _buildFieldConfigWithPermissions() {
    // Get current user ID for permission checks
    final currentUserId = 'current-user-id'; // Replace with actual user ID logic
    final isPrivilegedUser = true; // Replace with actual privilege check

    // Build permissions map
    final permissions = {
      'currentUserId': currentUserId,
      'canAdd': isPrivilegedUser,
      'canEdit': isPrivilegedUser,
      'canDelete': isPrivilegedUser,
      'canAccessFooterActions': isPrivilegedUser,
    };

    // Base configuration
    final baseConfig = {
      'widget': 'tree',
      'key': 'tree',
      'label': 'Folder Explorer',
      'headerTemplate': '{itemNo} - {name}',
      'isUseUpdateAction': false,
      'isOnItemDetailValue': false, // Mode 2
      'titleTemplate': '{name}{fileName}',
      'footerActions': [
        {'type': 'download', 'tooltip': 'Download', 'color': '#2E7D32'}, // green
      ],

      'onFooterAction': (BuildContext ctx, Map<String, dynamic> item, Map<String, dynamic> action) async {
        final type = (action['type'] ?? '').toString();

        if (type == 'download') {
          await _downloadFile(ctx, item);
        }
      },

      // Summary configuration for tree display
      'summary': {
        'layout': 'row',
        'fields': [
          {'key': 'itemNo', 'label': 'No', 'bgColor': '#EDF7ED', 'borderColor': '#B7E1B0', 'labelColor': '#1E6F1E', 'valueColor': '#125C12', 'layout': 'row'},
          {'key': 'name', 'label': 'Name', 'bgColor': '#E8F5E9', 'borderColor': '#A5D6A7', 'labelColor': '#2E7D32', 'valueColor': '#1B5E20', 'layout': 'row'},
          {'key': 'fileName', 'label': 'File Name', 'bgColor': '#E3F2FD', 'borderColor': '#90CAF9', 'labelColor': '#1976D2', 'valueColor': '#0D47A1', 'layout': 'row'},
        ],
      },

      // Level-based action restrictions
      'levelRestrictions': {
        'minLevelForAdd': 3,           // Only allow Add from level 1 onwards (not at root level 0)
        'minLevelForEdit': 2,          // Only allow Edit from level 1 onwards (not at root level 0)
        'minLevelForDelete': 3,        // Only allow Delete from level 1 onwards (not at root level 0)
        'minLevelForFooterActions': 2, // Only allow Footer Actions from level 1 onwards (not at root level 0)
      },

      // Default values for tree fields
      'defaultValues': {
        'completeness': 0.0,           // Default completeness to 0 instead of null
      },

      'permissions': permissions,
    };

    return baseConfig;
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_itemDetail.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final fieldConfig = _buildFieldConfigWithPermissions();

    final fields = CoreDynamicFields.buildFields(
      fieldConfigs: [fieldConfig],
      itemDetail: _itemDetail,
      moduleData: _moduleData,
      onChanged: _onChanged,
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: fields.isNotEmpty ? fields.first : const SizedBox.shrink(),
    );
  }

  Future<void> _downloadFile(BuildContext context, Map<String, dynamic> item) async {
    try {
      // Check if item has file data
      final fileUrl = item['fileUrl']?.toString();
      final fileName = item['fileName']?.toString();

      if (fileUrl == null || fileUrl.isEmpty || fileName == null || fileName.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file available for download'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LoadingOverlay.show(context, message: 'Downloading...');

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
      };

      final response = await CoreService.downloadFile(
        'PRJMGT',
        userInfoMap,
        item,
        tabModuleCode: 'DOC',
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

          final fileType = item['fileType']?.toString() ?? 'application/octet-stream';

          // Hide loading overlay before showing dialog
          LoadingOverlay.hide();

          if (context.mounted) {
            await FileViewerDialog.showFileOptionsDialog(
              context: context,
              fileName: fileName,
              fileType: fileType,
              bytes: bytes,
              fileInfo: item,
              onSaveToDevice: _saveFileToDevice,
            );
          }
        } else {
          throw Exception('No file data received from server');
        }
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        // Only hide loading if still showing (in case of error)
        if (LoadingOverlay.isShowing) {
          LoadingOverlay.hide();
        }
      }
    }
  }

  Future<void> _saveFileToDevice(BuildContext context, String fileName, Uint8List bytes) async {
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

      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
