part of 'list_core_screen.dart';

class ListCoreScreen extends StatefulWidget {
  final String moduleCode;
  final String? moduleName;
  final String? tabModuleCode;
  final List<TabConfig>? availableTabs;
  final Widget? Function(BuildContext context, Map<String, dynamic> listItem)?
  detailScreenBuilder;
  final List<PrintReportOption>? printReports;

  const ListCoreScreen({
    super.key,
    required this.moduleCode,
    this.moduleName,
    this.tabModuleCode,
    this.availableTabs,
    this.detailScreenBuilder,
    this.printReports,
  });

  @override
  State<ListCoreScreen> createState() => _ListCoreScreenState();
}

class _ListCoreScreenState extends State<ListCoreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  late CoreListProvider _provider;
  AnimationController? _fabAnimationController;
  Animation<double>? _fabScaleAnimation;
  bool _isSearchFocused = false;
  bool _canSwipeDelete = false;

  @override
  void initState() {
    super.initState();
    _provider = CoreListProvider();
    _provider.initialize(
      widget.moduleCode,
      widget.moduleName,
      onSessionExpired: _handleSessionExpired,
    );
    _loadSwipeDeletePermission();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _fabAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _provider.dispose();
    _fabAnimationController?.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            CoreConstants.scrollThreshold) {
      _provider.loadMoreData(widget.moduleCode, widget.tabModuleCode);
    }

    // Dismiss keyboard when scrolling if search is focused
    if (_isSearchFocused) {
      _dismissKeyboard();
    }
  }

  void _dismissKeyboard() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    FocusScope.of(context).unfocus();
  }

  void _handleSearchSubmit(String value) {
    _dismissKeyboard();
    if (value.trim().isNotEmpty) {
      _provider.performSearch(
        widget.moduleCode,
        widget.tabModuleCode,
        value.trim(),
      );
    }
  }

  void _handleSearchClear() {
    _searchController.clear();
    _dismissKeyboard();
    if (_provider.currentFilterInput.isNotEmpty) {
      _provider.performSearch(widget.moduleCode, widget.tabModuleCode, "");
    }
  }

  Future<void> _handleSessionExpired() async {
    // Show session expired dialog and handle re-login
    final success = await SessionHandler.handleSessionExpired(context);
    if (success && mounted) {
      // If auto-login successful, retry fetching data
      await _provider.fetchData(widget.moduleCode);
      await _loadSwipeDeletePermission();
    }
  }

  Future<void> _loadSwipeDeletePermission() async {
    final authService = AuthService();
    final userInfo = await authService.getSavedUserInfo();
    final userData = userInfo?.toJson() ?? const <String, dynamic>{};
    final canSwipeDelete = _hasSwipeDeleteDepartmentPermission(userData);

    if (!mounted) return;
    setState(() {
      _canSwipeDelete = canSwipeDelete;
    });
  }

  bool _hasSwipeDeleteDepartmentPermission(Map<String, dynamic> userData) {
    const allowedDepartmentNames = {'admin department', 'r&d department'};

    final departments = userData['departments'];
    if (departments is! List) return false;

    for (final department in departments) {
      final departmentName = _extractDepartmentName(department);
      if (departmentName != null &&
          allowedDepartmentNames.contains(
            _normalizeDepartmentName(departmentName),
          )) {
        return true;
      }
    }
    return false;
  }

  String _normalizeDepartmentName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _extractDepartmentName(dynamic department) {
    if (department is String) {
      final value = department.trim();
      return value.isEmpty ? null : value;
    }

    if (department is Map) {
      final directName = department['name'] ?? department['departmentName'];
      if (directName != null) {
        final value = directName.toString().trim();
        if (value.isNotEmpty) return value;
      }

      final nestedDepartment = department['department'];
      if (nestedDepartment is Map) {
        final nestedName =
            nestedDepartment['name'] ?? nestedDepartment['departmentName'];
        if (nestedName != null) {
          final value = nestedName.toString().trim();
          if (value.isNotEmpty) return value;
        }
      }
    }

    return null;
  }

  Future<void> _refreshListKeepingScroll(CoreListProvider provider) async {
    final double savedOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    await provider.refreshData(widget.moduleCode, widget.tabModuleCode);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final target = savedOffset.clamp(0.0, max);
      try {
        _scrollController.jumpTo(target);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoreListProvider>.value(
      value: _provider,
      child: Consumer<CoreListProvider>(
        builder: (context, provider, child) {
          // Handle generic server/network error: show message and go back
          if (provider.lastErrorStatusCode != null &&
              (provider.lastErrorStatusCode! >= 500 ||
                  provider.lastErrorStatusCode == 0)) {
            final msg =
                provider.lastErrorMessage ??
                'Connection error. Please try again later.';
            // Clear to avoid repeat
            provider.clearLastError();
            _showGenericErrorAndBack(msg);
          }

          return Stack(
            children: [
              Scaffold(
                appBar: CoreAppBar(
                  title: provider.displayModuleName ?? 'List Core Menu',
                  isSearchVisible: provider.isSearchVisible,
                  onSearchToggle: () {
                    provider.toggleSearch();
                    if (!provider.isSearchVisible) {
                      _searchController.clear();
                      if (provider.currentFilterInput.isNotEmpty) {
                        _handleSearchClear();
                      }
                    }
                  },
                  dataSpies: provider.dataSpies,
                  selectedDataSpyId: provider.selectedId,
                  onDataSpyChanged: (val) {
                    provider.selectDataSpy(
                      val,
                      widget.moduleCode,
                      widget.tabModuleCode,
                    );
                  },
                  searchController: _searchController,
                  onSearch: () {
                    _handleSearchSubmit(_searchController.text);
                  },
                  moduleCode: widget.moduleCode,
                  searchFocusNode: _searchFocusNode,
                  onSearchClear: _handleSearchClear,
                ),
                body: _buildBody(provider),
                floatingActionButton: provider.shouldShowNewButton
                    ? AnimatedBuilder(
                        animation: _fabScaleAnimation ?? Listenable.merge([]),
                        builder: (context, child) {
                          final isEnabled = provider.isNewButtonEnabled;
                          return Transform.scale(
                            scale: _fabScaleAnimation?.value ?? 1.0,
                            child: FloatingAddButton(
                              onPressed: isEnabled
                                  ? () {
                                      _fabAnimationController?.forward().then(
                                        (_) =>
                                            _fabAnimationController?.reverse(),
                                      );
                                      _navigateToNewRecord(provider);
                                    }
                                  : () {},
                            ),
                          );
                        },
                      )
                    : null,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
              ),

              // Loading Overlay (unified with detail screen)
              if (provider.showLoadingOverlay) const LoadingOverlayWidget(),
            ],
          );
        },
      ),
    );
  }
}
