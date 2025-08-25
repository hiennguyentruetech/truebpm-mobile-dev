import 'package:flutter/material.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/utils/task_utils.dart';
import 'package:truebpm/widgets/task/task_list_item_card.dart';
import 'package:truebpm/widgets/task/task_app_bar.dart';
import 'package:truebpm/widgets/core_task_list/task_loading_state.dart';
import 'package:truebpm/widgets/core_task_list/task_error_state.dart';
import 'package:truebpm/widgets/core_task_list/task_empty_state.dart';
import 'package:truebpm/services/task_action_service.dart';

class ListTaskScreen extends StatefulWidget {
  const ListTaskScreen({super.key});

  @override
  State<ListTaskScreen> createState() => _ListTaskScreenState();
}

class _ListTaskScreenState extends State<ListTaskScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _taskList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaskList();
  }

  Future<void> _fetchTaskList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await CoreService.instance.fetchListTaskProcess();
      if (result != null) {
        // Process task list với parsed display description
        final processed = TaskDisplayDescriptionUtils.processTaskList(result);

        setState(() {
          _taskList = processed;
          _isLoading = false;
        });
        logger.i('Task list loaded: ${_taskList.length} items');
      } else {
        setState(() {
          _errorMessage = 'Failed to load task list';
          _isLoading = false;
        });
      }
    } catch (e) {
      // logger.e('Error loading task list: $e');
      setState(() {
        _errorMessage = 'Error loading task list: $e';
        _isLoading = false;
      });
    }
  }

  void _onTaskTap(Map<String, dynamic> task, int index) {
    TaskActionService.handleTaskTap(
      context,
      task,
      index,
      onTaskUpdated: () {
        // Update UI khi task đã được updated
        setState(() {
          final taskIndex = _taskList.indexWhere((t) => t['id'] == task['id']);
          if (taskIndex != -1) {
            _taskList[taskIndex] = task;
          }
        });
        // Refresh task list sau khi navigate back
        _fetchTaskList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TaskAppBar(
        title: 'Task List',
        onRefresh: _fetchTaskList,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const TaskLoadingState();
    }

    if (_errorMessage != null) {
      return TaskErrorState(
        errorMessage: _errorMessage!,
        onRetry: _fetchTaskList,
      );
    }

    if (_taskList.isEmpty) {
      return TaskEmptyState(
        onRefresh: _fetchTaskList,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTaskList,
      child: ListView.builder(
        padding: const EdgeInsets.all(3),
        itemCount: _taskList.length,
        itemBuilder: (context, index) {
          final task = _taskList[index];
          return _buildTaskItem(task, index);
        },
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, int index) {
    return TaskListItemCard(
      item: task,
      index: index,
      headers: const [
        'code',
        'Module',
        'Status',
        'Requester',
        'Created Date',
      ],
      contents: const [
        'displayDescriptionParsed.code',
        'rootContainerId.displayName',
        'displayName',
        'displayDescriptionParsed.createdBy',
        'displayDescriptionParsed.createdDate(date)',
      ],
      onTap: () => _onTaskTap(task, index),
    );
  }
}

