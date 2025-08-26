import 'package:flutter/material.dart';
import 'package:truebpm/models/core_data_model.dart';
import 'package:truebpm/widgets/core/dataspy_selector.dart';
import 'package:truebpm/widgets/core/core_search_input.dart';

class CoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;
  final DataSpies? dataSpies;
  final String? selectedDataSpyId;
  final ValueChanged<String?> onDataSpyChanged;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final String moduleCode;

  const CoreAppBar({
    super.key,
    required this.title,
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.dataSpies,
    required this.selectedDataSpyId,
    required this.onDataSpyChanged,
    required this.searchController,
    required this.onSearch,
    required this.moduleCode,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(isSearchVisible ? Icons.close : Icons.search),
          onPressed: onSearchToggle,
        ),
      ],
      bottom: dataSpies != null ? PreferredSize(
        preferredSize: Size.fromHeight(isSearchVisible ? 120 : 60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // DataSpy Selector
              DataSpySelector(
                dataSpies: dataSpies,
                selectedId: selectedDataSpyId,
                onChanged: onDataSpyChanged,
              ),
              // Search Input
              if (isSearchVisible) ...[
                const SizedBox(height: 7),
                CoreSearchInput(
                  controller: searchController,
                  onSearch: onSearch,
                  hintText: 'Tìm kiếm...',
                ),
              ],
            ],
          ),
        ),
      ) : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (dataSpies != null ? (isSearchVisible ? 120 : 60) : 0),
  );
}
