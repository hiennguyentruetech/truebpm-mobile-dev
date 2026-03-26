import 'package:flutter/material.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/widgets/menu/menu_item.dart';
import 'package:truebpm/widgets/menu/menu_utils.dart';

class MenuList extends StatefulWidget {
  final List<MenuModel> menuData;

  const MenuList({
    super.key,
    required this.menuData,
  });

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  void _onMenuUpdated() {
    // Force rebuild when menu state changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visibleMenus = widget.menuData
        .where((m) => !MenuUtils.shouldHideMenu(m))
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.all(3),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return MenuItem(
              menu: visibleMenus[index],
              level: 0,
              onMenuUpdated: _onMenuUpdated,
            );
          },
          childCount: visibleMenus.length,
        ),
      ),
    );
  }
}
