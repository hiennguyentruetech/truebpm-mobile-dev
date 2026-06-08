import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/session_handler.dart';
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
  CoreTabBodyState<TabCmtCoreBodyScreen> createState() =>
      _TabCmtCoreBodyScreenState();
}

class _TabCmtCoreBodyScreenState
    extends CoreTabBodyState<TabCmtCoreBodyScreen> {
  final _MentionTextEditingController _commentController =
      _MentionTextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  // Response data
  Map<String, dynamic> _response = {};
  Map<String, dynamic> _itemDetail = {};
  List<dynamic> _comments = [];
  Map<String, dynamic> _defaultComment =
      {}; // Base template for new comment payload

  // Current user info
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoadingMentionUsers = false;
  List<_MentionUser> _mentionUsers = [];
  List<_MentionUser> _suggestedMentionUsers = [];
  _MentionQuery? _activeMentionQuery;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMentionUsers();
    _updateDataFromInitialData();
    _commentFocusNode.addListener(_handleCommentFocusChanged);
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
    _commentFocusNode
      ..removeListener(_handleCommentFocusChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final authService = AuthService();
    _currentUser = await authService.getSavedUserInfo();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMentionUsers() async {
    setState(() => _isLoadingMentionUsers = true);
    try {
      final response = await CoreService.instance.getDropdownData(
        'DROPDOWN.RESOURCE/USER',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final users = _normalizeMentionUsers(response['data']);
        setState(() {
          _mentionUsers = users;
          _isLoadingMentionUsers = false;
        });
        _refreshMentionState();
      } else if (response['statusCode'] == 401) {
        setState(() => _isLoadingMentionUsers = false);
        await SessionHandler.handleSessionExpired(context);
      } else {
        setState(() => _isLoadingMentionUsers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMentionUsers = false);
    }
  }

  List<_MentionUser> _normalizeMentionUsers(dynamic source) {
    final rawList = source is List
        ? source
        : source is Map
        ? (source['data'] is List
              ? source['data']
              : source['items'] is List
              ? source['items']
              : source['value'] is List
              ? source['value']
              : const [])
        : const [];

    final users = <_MentionUser>[];
    final seenIds = <String>{};

    for (final raw in rawList) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final id = map['id']?.toString() ?? '';
      final fullName = (map['fullName'] ?? map['name'] ?? map['label'] ?? '')
          .toString()
          .trim();
      final code = (map['code'] ?? map['userName'] ?? map['username'] ?? '')
          .toString()
          .trim();

      if (id.isEmpty || (fullName.isEmpty && code.isEmpty)) continue;
      if (!seenIds.add(id)) continue;

      users.add(
        _MentionUser(
          id: id,
          code: code,
          fullName: fullName.isNotEmpty ? fullName : code,
        ),
      );
    }

    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users;
  }

  void _handleCommentFocusChanged() {
    _refreshMentionState();
    if (mounted) setState(() {});
  }

  void _handleCommentChanged(String _) {
    _refreshMentionState();
    if (mounted) setState(() {});
  }

  void _updateDataFromInitialData() {
    _response = Map<String, dynamic>.from(widget.initialData ?? {});
    _itemDetail = Map<String, dynamic>.from(_response['itemDetail'] ?? {});
    _comments = List<dynamic>.from(_itemDetail['comments'] ?? []);
    _defaultComment = Map<String, dynamic>.from(
      _itemDetail['defaultComment'] ?? {},
    );

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
        _defaultComment = Map<String, dynamic>.from(
          _itemDetail['defaultComment'],
        );
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

  void _refreshMentionState() {
    final selectedUsers = _extractMentionUsers(_commentController.text);
    _commentController.mentionUsers = selectedUsers;

    if (!_commentFocusNode.hasFocus || _mentionUsers.isEmpty || _isLoading) {
      if (_suggestedMentionUsers.isNotEmpty || _activeMentionQuery != null) {
        setState(() {
          _suggestedMentionUsers = [];
          _activeMentionQuery = null;
        });
      }
      return;
    }

    final mentionQuery = _findMentionQuery();
    final fallbackQuery = mentionQuery == null ? _findFallbackQuery() : null;
    final activeQuery = mentionQuery ?? fallbackQuery;
    final suggestions = activeQuery == null
        ? <_MentionUser>[]
        : _filterMentionUsers(
            activeQuery.query,
            allowEmptyQuery: mentionQuery != null,
          );

    setState(() {
      _activeMentionQuery = mentionQuery;
      _suggestedMentionUsers = suggestions;
    });
  }

  _MentionQuery? _findMentionQuery() {
    final text = _commentController.text;
    final cursor = _commentController.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return null;

    final beforeCursor = text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;
    if (atIndex > 0 && !_isMentionBoundary(beforeCursor[atIndex - 1])) {
      return null;
    }

    final query = beforeCursor.substring(atIndex + 1);
    if (query.contains(RegExp(r'[\n\r]'))) return null;

    return _MentionQuery(
      start: atIndex,
      end: cursor,
      query: query.trimLeft().toLowerCase(),
    );
  }

  _MentionQuery? _findFallbackQuery() {
    final text = _commentController.text;
    final cursor = _commentController.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return null;

    final beforeCursor = text.substring(0, cursor);
    final match = RegExp(r'([^\s@]+)$').firstMatch(beforeCursor);
    if (match == null) return null;

    final query = match.group(1)!.trim().toLowerCase();
    if (query.length < 2) return null;
    return _MentionQuery(start: match.start, end: match.end, query: query);
  }

  bool _isMentionBoundary(String char) {
    return char.trim().isEmpty || '([{'.contains(char);
  }

  List<_MentionUser> _filterMentionUsers(
    String query, {
    required bool allowEmptyQuery,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty && !allowEmptyQuery) return const [];

    final matches = _mentionUsers
        .where((user) {
          if (normalizedQuery.isEmpty) return true;
          return user.fullName.toLowerCase().contains(normalizedQuery) ||
              user.code.toLowerCase().contains(normalizedQuery);
        })
        .take(6)
        .toList();
    return matches;
  }

  void _selectMentionUser(_MentionUser user) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final cursor = selection.baseOffset >= 0
        ? selection.baseOffset
        : text.length;
    final query = _activeMentionQuery ?? _findFallbackQuery();
    final start = query?.start ?? cursor;
    final end = query?.end ?? cursor;
    final mentionText = '${user.mentionLabel} ';

    final nextText = text.replaceRange(start, end, mentionText);
    final nextCursor = start + mentionText.length;

    _commentController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
    _commentFocusNode.requestFocus();
    _refreshMentionState();
  }

  List<_MentionUser> _extractMentionUsers(String content) {
    final seenIds = <String>{};
    final selected = <_MentionUser>[];

    for (final user in _mentionUsers) {
      final label = RegExp.escape(user.mentionLabel);
      final regex = RegExp('(^|\\s)$label(?=\\s|\$)', caseSensitive: false);
      if (regex.hasMatch(content) && seenIds.add(user.id)) {
        selected.add(user);
      }
    }

    return selected;
  }

  List<_MentionUser> _mentionsForContent(String content, dynamic sendUser) {
    final fromPayload = _normalizeMentionUsers(sendUser);
    if (fromPayload.isNotEmpty) return fromPayload;
    return _extractMentionUsers(content);
  }

  TextSpan _buildMentionSpan(
    String content,
    List<_MentionUser> users,
    TextStyle baseStyle, {
    TextStyle? mentionStyle,
  }) {
    final resolvedMentionStyle =
        mentionStyle ??
        baseStyle.copyWith(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w800,
        );
    if (content.isEmpty || users.isEmpty) {
      return TextSpan(text: content, style: baseStyle);
    }

    final labels =
        users
            .map((user) => user.mentionLabel)
            .where((label) => label.isNotEmpty)
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final children = <TextSpan>[];
    var index = 0;

    while (index < content.length) {
      String? matchedLabel;
      for (final label in labels) {
        if (content
            .substring(index)
            .toLowerCase()
            .startsWith(label.toLowerCase())) {
          matchedLabel = content.substring(index, index + label.length);
          break;
        }
      }

      if (matchedLabel != null) {
        children.add(TextSpan(text: matchedLabel, style: resolvedMentionStyle));
        index += matchedLabel.length;
        continue;
      }

      final nextMentionIndex = _nextMentionIndex(content, labels, index + 1);
      final end = nextMentionIndex < 0 ? content.length : nextMentionIndex;
      children.add(
        TextSpan(text: content.substring(index, end), style: baseStyle),
      );
      index = end;
    }

    return TextSpan(children: children, style: baseStyle);
  }

  int _nextMentionIndex(String content, List<String> labels, int start) {
    var next = -1;
    final lowerContent = content.toLowerCase();
    for (final label in labels) {
      final found = lowerContent.indexOf(label.toLowerCase(), start);
      if (found >= 0 && (next < 0 || found < next)) next = found;
    }
    return next;
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final userInfo = await authService.getSavedUserInfo();

      // Ensure we have default template
      if (_defaultComment.isEmpty) {
        if (_itemDetail['defaultComment'] is Map<String, dynamic>) {
          _defaultComment = Map<String, dynamic>.from(
            _itemDetail['defaultComment'],
          );
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
      final content = _commentController.text.trim();
      final sendUsers = _extractMentionUsers(content);
      final now = DateTime.now().toUtc().toIso8601String();
      final commentPayload = Map<String, dynamic>.from(_defaultComment)
        ..['content'] = content
        ..['createdBy'] = {
          "id": userInfo?.id ?? "",
          "code": userInfo?.code ?? "",
          "fullName": userInfo?.fullName ?? "",
        }
        ..['createdDate'] = now
        ..['updatedDate'] = now
        ..['updatedBy'] = null
        ..['sendUser'] = sendUsers.map((user) => user.toPayload()).toList();

      // Guarantee required null fields per spec
      commentPayload['id'] = null;
      commentPayload['code'] = null;

      // If recordId missing try to derive from itemDetail
      commentPayload['recordId'] ??= _itemDetail['id'] ?? _response['id'];

      // Ensure module object present
      if (commentPayload['module'] == null ||
          commentPayload['module'] is! Map) {
        commentPayload['module'] = {
          "editId": _itemDetail['editId'] ?? 0,
          "id": _itemDetail['id'] ?? _response['id'],
          "code": _itemDetail['code'] ?? _response['code'],
          "moduleCode": widget.moduleCode,
          "description": _itemDetail['description'] ?? _response['description'],
          "name":
              _itemDetail['name'] ??
              _response['name'] ??
              _response['title'] ??
              '',
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
        _commentController.mentionUsers = const [];
        _activeMentionQuery = null;
        _suggestedMentionUsers = [];
        // Refresh to fetch new comment list
        final provider = Provider.of<CoreDetailProvider>(
          context,
          listen: false,
        );
        await provider.fetchDetailData(forceRefresh: true);

        // Update local data from provider
        _updateDataFromProvider(provider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment sent successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final errorMsg = response?['message'] ?? 'Failed to send comment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          colors: [Colors.blue.shade50, Colors.white],
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
    final mentionedUsers = _mentionsForContent(content, comment['sendUser']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Colors.blue.shade500
                        : Colors.grey.shade100,
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
                  child: RichText(
                    text: _buildMentionSpan(
                      content,
                      mentionedUsers,
                      TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      mentionStyle: TextStyle(
                        color: isCurrentUser
                            ? const Color(0xFFE3F2FD)
                            : Colors.blue.shade700,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
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
    final isFocused = _commentFocusNode.hasFocus;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMentionSuggestions(),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFD7E8F7))),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 112,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFocused
                            ? const Color(0xFF4E7FB9)
                            : const Color(0xFFE3EEF9),
                        width: isFocused ? 1.2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      onChanged: _handleCommentChanged,
                      decoration: InputDecoration(
                        hintText: _isLoadingMentionUsers
                            ? 'Loading...'
                            : 'Type @ to mention someone',
                        hintStyle: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.38,
                        color: Colors.black87,
                      ),
                      enabled: !_isLoading,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  child: AnimatedScale(
                    scale: canSend ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: GestureDetector(
                      onTap: canSend ? _sendComment : null,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: canSend
                              ? const Color(0xFF2598E8)
                              : const Color(0xFFECEFF3),
                          boxShadow: canSend
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2598E8,
                                    ).withOpacity(0.22),
                                    blurRadius: 9,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: canSend
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions() {
    if (!_commentFocusNode.hasFocus ||
        _suggestedMentionUsers.isEmpty ||
        _isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 190),
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _suggestedMentionUsers.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.blueGrey.shade50, indent: 54),
        itemBuilder: (context, index) {
          final user = _suggestedMentionUsers[index];
          return InkWell(
            onTap: () => _selectMentionUser(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  _buildMentionAvatar(user),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF243447),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (user.code.isNotEmpty)
                          Text(
                            '@${user.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.alternate_email_rounded,
                    color: Colors.blue.shade300,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMentionAvatar(_MentionUser user) {
    final label = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : '@';
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MentionUser {
  const _MentionUser({
    required this.id,
    required this.code,
    required this.fullName,
  });

  final String id;
  final String code;
  final String fullName;

  String get mentionLabel => '@$fullName';

  Map<String, dynamic> toPayload() {
    return {'id': id, 'code': code, 'fullName': fullName};
  }
}

class _MentionQuery {
  const _MentionQuery({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}

class _MentionTextEditingController extends TextEditingController {
  List<_MentionUser> _mentionUsers = const [];

  set mentionUsers(List<_MentionUser> users) {
    _mentionUsers = List<_MentionUser>.from(users);
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty || _mentionUsers.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final mentionStyle = baseStyle.copyWith(
      color: Colors.blue.shade700,
      fontWeight: FontWeight.w800,
    );
    final labels =
        _mentionUsers
            .map((user) => user.mentionLabel)
            .where((label) => label.isNotEmpty)
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final children = <TextSpan>[];
    var index = 0;

    while (index < text.length) {
      String? matchedLabel;
      for (final label in labels) {
        if (text
            .substring(index)
            .toLowerCase()
            .startsWith(label.toLowerCase())) {
          matchedLabel = text.substring(index, index + label.length);
          break;
        }
      }

      if (matchedLabel != null) {
        children.add(TextSpan(text: matchedLabel, style: mentionStyle));
        index += matchedLabel.length;
        continue;
      }

      final next = _nextMentionIndex(text, labels, index + 1);
      final end = next < 0 ? text.length : next;
      children.add(
        TextSpan(text: text.substring(index, end), style: baseStyle),
      );
      index = end;
    }

    return TextSpan(children: children, style: baseStyle);
  }

  int _nextMentionIndex(String value, List<String> labels, int start) {
    var next = -1;
    final lowerValue = value.toLowerCase();
    for (final label in labels) {
      final found = lowerValue.indexOf(label.toLowerCase(), start);
      if (found >= 0 && (next < 0 || found < next)) next = found;
    }
    return next;
  }
}
