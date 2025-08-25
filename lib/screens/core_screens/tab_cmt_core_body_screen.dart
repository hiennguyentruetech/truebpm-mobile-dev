import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/widgets/core/core_tab_body.dart';

/// Core tab body for Comments (CMT) - Reusable for all modules
/// Handles comment display and creation with chat-like UI
class TabCmtCoreBodyScreen extends CoreTabBody {
  const TabCmtCoreBodyScreen({
    super.key,
    required super.moduleCode,
    required super.tabCode,
    super.itemId,
    super.initialData,
    super.onDataChanged,
  });

  @override
  CoreTabBodyState<TabCmtCoreBodyScreen> createState() => _TabCmtCoreBodyScreenState();
}

class _TabCmtCoreBodyScreenState extends CoreTabBodyState<TabCmtCoreBodyScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Response data
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  List<dynamic> _comments = [];
  Map<String, dynamic> _defaultComment = {}; // Base template for new comment payload
  
  // Current user info
  UserModel? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _updateDataFromInitialData();
  }

  @override
  void didUpdateWidget(TabCmtCoreBodyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.initialData != widget.initialData) {
      _updateDataFromInitialData();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final authService = AuthService();
    _currentUser = await authService.getSavedUserInfo();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _comments = List<dynamic>.from(_itemDetail['comments'] ?? []);
    _defaultComment = Map<String, dynamic>.from(_itemDetail['defaultComment'] ?? {});
    
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isCurrentUserComment(Map<String, dynamic> comment) {
    if (_currentUser == null) return false;
    final createdBy = comment['createdBy'];
    if (createdBy == null || createdBy is! Map<String, dynamic>) return false;
    return createdBy['id'] == _currentUser!.id;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      // If today, show only time
      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      // If yesterday
      else if (difference.inDays == 1) {
        return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      // If older, show date and time
      else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  void _updateDataFromProvider(CoreDetailProvider provider) {
    setState(() {
      _response = provider.rawResponse ?? {};
      _itemDetail = _response['itemDetail'] ?? {};
      _comments = _itemDetail['comments'] ?? [];

      // Update default comment template if available
      if (_itemDetail['defaultComment'] is Map<String, dynamic>) {
        _defaultComment = Map<String, dynamic>.from(_itemDetail['defaultComment']);
      }
    });

    // Scroll to bottom to show new comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty || _isLoading) return;

    setState(() { _isLoading = true; });

    try {
      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();
      
      // Ensure we have default template
      if (_defaultComment.isEmpty) {
        if (_itemDetail['defaultComment'] is Map<String, dynamic>) {
          _defaultComment = Map<String, dynamic>.from(_itemDetail['defaultComment']);
        } else {
          // Fallback minimal structure
          _defaultComment = {
            "editId": 0,
            "id": null,
            "code": null,
            "recordId": _itemDetail['id'],
            "module": _itemDetail['module'] ?? {},
          };
        }
      }
      
      // Build payload from defaultComment (root-level) updating only specified fields
      final commentPayload = Map<String, dynamic>.from(_defaultComment)
        ..['content'] = _commentController.text.trim()
        ..['createdBy'] = {
          "id": userInfo?.id ?? "",
            "code": userInfo?.code ?? "",
        }
        ..['createdDate'] = DateTime.now().toUtc().toIso8601String()
        ..['updatedDate'] = DateTime.now().toUtc().toIso8601String();
      
      // Guarantee required null fields per spec
      commentPayload['id'] = null;
      commentPayload['code'] = null;
      
      // If recordId missing try to derive from itemDetail
      commentPayload['recordId'] ??= _itemDetail['id'] ?? _response['id'];
      
      // Ensure module object present
      if (commentPayload['module'] == null || commentPayload['module'] is! Map) {
        commentPayload['module'] = {
          "editId": _itemDetail['editId'] ?? 0,
          "id": _itemDetail['id'] ?? _response['id'],
          "code": _itemDetail['code'] ?? _response['code'],
          "moduleCode": widget.moduleCode,
          "description": _itemDetail['description'] ?? _response['description'],
          "name": _itemDetail['name'] ?? _response['name'] ?? _response['title'] ?? '',
        };
      }
      
      // Call SAVE action with raw payload (not nested in itemDetail)
      final response = await CoreService.instance.performAction(
        widget.moduleCode,
        widget.tabCode,
        'SAVE',
        commentPayload,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        _commentController.clear();
        // Refresh to fetch new comment list
        final provider = Provider.of<CoreDetailProvider>(context, listen: false);
        await provider.fetchDetailData(forceRefresh: true);

        // Update local data from provider
        _updateDataFromProvider(provider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment sent successfully'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to send comment';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending comment: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget buildTabContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Comments list
          Expanded(
            child: _comments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index] as Map<String, dynamic>;
                      return _buildCommentBubble(comment);
                    },
                  ),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildTabContent(context);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to add a comment!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBubble(Map<String, dynamic> comment) {
    final isCurrentUser = _isCurrentUserComment(comment);
    final createdBy = comment['createdBy'] as Map<String, dynamic>? ?? {};
    final content = comment['content']?.toString() ?? '';
    final createdDate = comment['createdDate']?.toString();
    final userName = createdBy['fullName']?.toString() ?? 'Unknown User';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue.shade500 : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                
                if (createdDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(createdDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green.shade100,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final canSend = _commentController.text.trim().isNotEmpty && !_isLoading;
    return Row(
      children: [
        // Text input area
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 135),
            padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
            child: TextField(
              controller: _commentController,
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              enabled: !_isLoading,
            ),
          ),
        ),
        
        // Send button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: AnimatedScale(
            scale: canSend ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: GestureDetector(
              onTap: canSend ? _sendComment : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: canSend
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade300,
                          ],
                        ),
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: canSend ? Colors.white : Colors.grey.shade500,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
