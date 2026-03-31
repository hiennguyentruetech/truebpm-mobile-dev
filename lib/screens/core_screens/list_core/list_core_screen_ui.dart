part of 'list_core_screen.dart';

extension _ListCoreScreenUiExt on _ListCoreScreenState {
  Widget _buildBody(CoreListProvider provider) {
    // Removed in-list loading indicator; rely on loading overlay instead.
    if (provider.dataSpies == null) {
      return const Center(child: Text('No data available'));
    }

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: _buildDataList(provider),
      ),
    );
  }

  Widget _buildDataList(CoreListProvider provider) {
    if (provider.listData.isEmpty) {
      return CoreEmptyState(
        onRefresh: () =>
            provider.refreshData(widget.moduleCode, widget.tabModuleCode),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: RefreshIndicator(
        onRefresh: () => _refreshListKeepingScroll(provider),
        color: Colors.blue,
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: provider.listData.length,
          itemBuilder: (context, index) {
            final item = provider.listData[index] as Map<String, dynamic>;
            final statusStyle = _buildStatusStyle(item);
            final card = CoreListItemCard(
              item: item,
              index: index + 1,
              headers: provider.headers,
              contents: provider.contents,
              statusStyle: statusStyle,
              onTap: () {
                // Dismiss keyboard before navigation
                _dismissKeyboard();

                // Navigate to detail screen
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) {
                          // Use custom detail screen if provided, otherwise use default
                          final customScreen = widget.detailScreenBuilder?.call(
                            context,
                            item,
                          );
                          if (customScreen != null) {
                            return customScreen;
                          }

                          return GenericDetailCoreScreen(
                            moduleCode: widget.moduleCode,
                            moduleName: provider.displayModuleName,
                            listItem: item,
                            initialTabCode: widget.tabModuleCode ?? 'DTLS',
                            dataSpy: provider.dataSpy,
                            availableTabs:
                                widget.availableTabs ?? _getDefaultTabs(),
                            printReports:
                                widget.printReports ??
                                _getExamplePrintReports(),
                            onOperationSuccess: () async {
                              // Refresh list and keep scroll for copy/delete, etc.
                              await _refreshListKeepingScroll(provider);
                            },
                          );
                        },
                      ),
                    )
                    .then((_) async {
                      await _refreshListKeepingScroll(provider);
                    });
              },
            );

            if (!_canSwipeDelete) {
              return card;
            }

            return Dismissible(
              key: Key('item_${item['id'] ?? index}'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.shade400.withOpacity(0.1),
                      Colors.red.shade500.withOpacity(0.8),
                      Colors.red.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              confirmDismiss: (direction) async {
                await _handleSwipeDelete(provider, item, index);
                return false;
              },
              child: card,
            );
          },
        ),
      ),
    );
  }
}
