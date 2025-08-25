import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';
import 'package:truebpm/widgets/core_tree.dart';

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
    if (mounted) setState(() {});
  }

  void _onChanged(dynamic value) {
    setState(() {
      // Update the tree data
      if (_itemDetail['tree'] == null) {
        _itemDetail['tree'] = {};
      }
      if (value is List) {
        _itemDetail['tree']['data'] = value;
      } else if (value is Map<String, dynamic>) {
        if (value['data'] is List) {
          _itemDetail['tree']['data'] = value['data'];
        }
        if (value['removedRows'] is List) {
          _itemDetail['tree']['removedRows'] = value['removedRows'];
        }
      }
      _response['itemDetail'] = Map<String, dynamic>.from(_itemDetail);
    });
    
    if (widget.onDataChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onDataChanged!(_response);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  @override
  Widget buildTabContent(BuildContext context) {
    if (_itemDetail.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CoreTree(
      dataKey: 'tree',
      itemDetail: _itemDetail,
      label: 'Project Folder Structure',
      children: [
        {
          'dataKey': 'name',
          'label': 'Folder Name',
          'required': true,
          'type': 'input',
        },
        {
          'dataKey': 'displayText',
          'label': 'Display Text',
          'required': false,
          'type': 'input',
        },
        {
          'dataKey': 'isMainFolder',
          'label': 'Is Main Folder',
          'required': false,
          'type': 'checkbox',
        },
        {
          'dataKey': 'projectDocTypeId',
          'label': 'Document Type',
          'required': false,
          'type': 'select',
          'data': 'DROPDOWN.PROJECT_DOC_TYPES.ALL',
          'display': 'name',
        },
        {
          'dataKey': 'formatId',
          'label': 'Format',
          'required': false,
          'type': 'select',
          'data': 'DROPDOWN.FORMATS.ALL',
          'display': 'name',
        },
      ],
      onChanged: _onChanged,
      allowAdd: true,
      allowEdit: true,
      allowDelete: true,
    );
  }
}
