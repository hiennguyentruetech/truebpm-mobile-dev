part of 'detail_core_screen.dart';

extension _DetailCoreScreenTabsExt on _DetailCoreScreenState {
  PreferredSizeWidget? _buildTabsAreaInAppBar() {
    final tabs = widget.availableTabs;
    if (tabs.isEmpty || _tabController == null) return null;

    final hasDocSubTabs =
        widget.docSubTabs != null && (widget.docSubTabs!.isNotEmpty);

    return PreferredSize(
      preferredSize: Size.fromHeight(
        hasDocSubTabs && _currentTabCode.toUpperCase() == 'DOC' ? 105.0 : 60.0,
      ),
      child: Consumer<CoreDetailProvider>(
        builder: (context, provider, child) {
          final isNewRecord = _isNewRecord(provider);

          // Filter out hidden tabs and for new records, only show default tab (DTLS)
          List<TabConfig> visibleTabs;
          if (isNewRecord) {
            visibleTabs = tabs
                .where(
                  (tab) =>
                      !provider.isTabHidden(tab.code) &&
                      (tab.code.toUpperCase() == 'DTLS' ||
                          tab.isDefault == true),
                )
                .toList();
          } else {
            visibleTabs = tabs
                .where((tab) => !provider.isTabHidden(tab.code))
                .toList();
          }

          // Ensure TabController length matches the number of tabs we render
          if (_tabController != null &&
              _tabController!.length != visibleTabs.length) {
            final int currentVisibleIndex = visibleTabs.indexWhere(
              (t) => t.code == _currentTabCode,
            );
            final int newIndex = currentVisibleIndex >= 0
                ? currentVisibleIndex
                : 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _tabController!.dispose();
              _safeSetState(() {
                _tabController = TabController(
                  length: visibleTabs.length,
                  vsync: this,
                  initialIndex: newIndex.clamp(
                    0,
                    (visibleTabs.length - 1).clamp(0, visibleTabs.length - 1),
                  ),
                );
                _currentTabCode = visibleTabs.isNotEmpty
                    ? visibleTabs.first.code
                    : _currentTabCode;
              });
            });
            return const SizedBox.shrink();
          }

          if (visibleTabs.isEmpty) {
            return Container();
          }

          final bool shouldShowMoreTabs = _shouldShowTabMoreButton(visibleTabs);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.78),
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                        onTap: (index) async {
                          final selectedTab = visibleTabs[index];
                          final isTabDisabled = provider.isTabDisabled(
                            selectedTab.code,
                          );
                          if (!isTabDisabled) {
                            await _changeTab(selectedTab.code);
                          }
                        },
                        tabs: visibleTabs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tab = entry.value;
                          final isTabDisabled = provider.isTabDisabled(
                            tab.code,
                          );

                          return AnimatedBuilder(
                            animation: _tabController!,
                            builder: (context, child) {
                              final isSelected = _tabController!.index == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 170),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTabIcon(tab.code),
                                      size: isSelected ? 17 : 16,
                                      color: isTabDisabled
                                          ? Colors.white.withOpacity(0.30)
                                          : isSelected
                                          ? Colors.blue.shade700
                                          : Colors.white.withOpacity(0.92),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      tab.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isTabDisabled
                                            ? Colors.white.withOpacity(0.30)
                                            : isSelected
                                            ? Colors.blue.shade700
                                            : Colors.white.withOpacity(0.92),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    if (shouldShowMoreTabs) ...[
                      const SizedBox(width: 6),
                      _buildTabMoreButton(visibleTabs, provider),
                    ],
                  ],
                ),
              ),
              if (widget.docSubTabs != null &&
                  widget.docSubTabs!.isNotEmpty &&
                  _currentTabCode.toUpperCase() == 'DOC')
                _buildDocSubTabBar(context, provider, widget.docSubTabs!),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowTabMoreButton(List<TabConfig> visibleTabs) {
    if (visibleTabs.length >= 4) return true;
    return visibleTabs.any((tab) => tab.name.length > 12);
  }

  Widget _buildTabMoreButton(
    List<TabConfig> visibleTabs,
    CoreDetailProvider provider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTabQuickSwitcher(visibleTabs, provider),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }

  Future<void> _showTabQuickSwitcher(
    List<TabConfig> visibleTabs,
    CoreDetailProvider provider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.68;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'All Tabs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleTabs.length} tabs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                    shrinkWrap: true,
                    itemCount: visibleTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final tab = visibleTabs[index];
                      final bool isActive = tab.code == _currentTabCode;
                      final bool isDisabled = provider.isTabDisabled(tab.code);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isDisabled
                              ? null
                              : () async {
                                  Navigator.of(sheetContext).pop();
                                  if (_tabController != null &&
                                      index < _tabController!.length) {
                                    _tabController!.index = index;
                                  }
                                  await _changeTab(tab.code);
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFE8F2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? Colors.blue.shade300
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? Colors.blue : Colors.black)
                                      .withOpacity(isActive ? 0.10 : 0.04),
                                  blurRadius: isActive ? 10 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: isActive
                                        ? LinearGradient(
                                            colors: [
                                              Colors.blue.shade600,
                                              Colors.blue.shade400,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isActive
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getTabIcon(tab.code),
                                    size: 18,
                                    color: isDisabled
                                        ? Colors.grey.shade400
                                        : isActive
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tab.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : isActive
                                          ? Colors.blue.shade800
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                                if (isDisabled)
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  )
                                else
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.blue.shade600
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.check_rounded
                                          : Icons.chevron_right_rounded,
                                      size: isActive ? 16 : 18,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ensure doc sub-tab initialized (no longer needs to load data separately)

  Widget _buildDocSubTabBar(
    BuildContext context,
    CoreDetailProvider provider,
    List<TabDocConfig> subTabs,
  ) {
    // Ensure current selected exists
    if (_currentDocSubTabCode == null ||
        !subTabs.any((t) => t.code == _currentDocSubTabCode)) {
      _currentDocSubTabCode = (subTabs
          .firstWhere((t) => t.isDefault, orElse: () => subTabs.first)
          .code);
    }

    final itemKeys = List.generate(subTabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex = subTabs.indexWhere(
        (t) => t.code == _currentDocSubTabCode,
      );
      if (selectedIndex != -1 &&
          itemKeys[selectedIndex].currentContext != null) {
        Scrollable.ensureVisible(
          itemKeys[selectedIndex].currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutExpo,
          alignment: 0.5,
        );
      }
    });
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.separated(
        controller: _docSubTabScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: subTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = subTabs[index];
          final bool selected = t.code == _currentDocSubTabCode;
          final isDisabled = false;
          final icon = Icons.insert_drive_file_rounded;
          return GestureDetector(
            key: itemKeys[index],
            onTap: isDisabled || selected
                ? null
                : () async {
                    _safeSetState(() {
                      _currentDocSubTabCode = t.code;
                    });
                    await provider.switchDocSubTab(t.code);
                    // Scroll to show selected (TabBar-like)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (itemKeys[index].currentContext != null) {
                        Scrollable.ensureVisible(
                          itemKeys[index].currentContext!,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutExpo,
                          alignment: 0.5,
                        );
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutExpo,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          Color(0xFF1E88E5), // blue 600
                          Color.fromARGB(255, 62, 149, 220), // blue 300
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Color(
                            0xFF1E88E5,
                          ).withOpacity(0.13), // blue shadow
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.22),
                  width: selected ? 2.2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: selected ? 18 : 15,
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutExpo,
                    style: TextStyle(
                      fontSize: selected ? 14 : 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.85),
                      letterSpacing: 0.5,
                    ),
                    child: Text(t.name),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method để lấy icon cho mỗi tab
  IconData _getTabIcon(String tabCode) {
    switch (tabCode.toUpperCase()) {
      case 'DTLS':
        return Icons.info_outline_rounded;
      case 'DETAIL':
        return Icons.insert_chart_outlined_rounded;
      case 'DOC':
        return Icons.insert_drive_file_rounded;
      case 'CMT':
        return Icons.comment_rounded;
      case 'QUERY':
        return Icons.search_rounded;
      case 'CONFIG':
        return Icons.settings_outlined;
      case 'TBPMS':
        return Icons.table_chart_outlined;
      case 'ATPMS':
        return Icons.security_rounded;
      case 'TABPMS':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.tab_rounded;
    }
  }

  Widget _buildBody(CoreDetailProvider provider) {
    if (provider.loading) {
      // Avoid double loaders; rely on provider.showLoadingOverlay with unified overlay
      return const SizedBox.shrink();
    }

    return KeyboardUtils.withKeyboardDismissal(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: _createTabBody(
          _currentTabCode,
          moduleCode: widget.moduleCode,
          currentTabCode: _currentTabCode,
          itemId: provider.itemDetail?.value['id']?.toString(),
          initialData: provider.rawResponse, // Truyền toàn bộ raw response động
          onDataChanged: (updatedData) =>
              _handleDataChanged(provider, updatedData),
        ),
      ),
    );
  }

  /// Create tab body using TabConfig.tabBodyBuilder or fallback to TabBodyRegistry
  Widget _createTabBody(
    String tabCode, {
    required String moduleCode,
    required String currentTabCode,
    String? itemId,
    Map<String, dynamic>? initialData,
    Function(Map<String, dynamic>)? onDataChanged,
  }) {
    // Find tab config with tabBodyBuilder
    final tabConfig = widget.availableTabs.firstWhere(
      (tab) => tab.code == currentTabCode,
      orElse: () => TabConfig(code: currentTabCode, name: currentTabCode),
    );

    // Use tabBodyBuilder if available
    if (tabConfig.tabBodyBuilder != null) {
      return tabConfig.tabBodyBuilder!(
        moduleCode: moduleCode,
        tabCode: currentTabCode,
        itemId: itemId,
        initialData: initialData,
        onDataChanged: onDataChanged,
      );
    }

    // Fallback to TabBodyRegistry if no tabBodyBuilder
    return TabBodyRegistry.createTabBody(
          moduleCode: moduleCode,
          tabCode: currentTabCode,
          itemId: itemId,
          initialData: initialData,
          onDataChanged: onDataChanged,
        ) ??
        Container(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.extension_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tab Not Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tab "$currentTabCode" is not implemented yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
  }
}
