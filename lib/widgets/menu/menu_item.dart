import 'package:flutter/material.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/widgets/menu/menu_utils.dart';
import 'package:truebpm/services/menu/menu_navigation_service.dart';
import 'package:truebpm/utils/menu_constants.dart';

class MenuItem extends StatefulWidget {
  final MenuModel menu;
  final int level;
  final VoidCallback? onMenuUpdated;

  const MenuItem({
    super.key,
    required this.menu,
    required this.level,
    this.onMenuUpdated,
  });

  @override
  State<MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  void _handleMenuTap() {
    if (widget.menu.hasChildren) {
      setState(() {
        widget.menu.isExpanded = !widget.menu.isExpanded;
      });
      widget.onMenuUpdated?.call();
    } else if (MenuNavigationService.canNavigate(widget.menu)) {
      MenuNavigationService.navigateToPage(context, widget.menu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuColor = MenuUtils.getMenuColor(widget.level);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: MenuConstants.menuItemMarginBottom,
        left: MenuUtils.getMarginLeft(widget.level),
        right: 2,
      ),
      child: Card(
        elevation: widget.level == 0 ? 4 : 2,
        shadowColor: menuColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MenuConstants.defaultBorderRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MenuConstants.defaultBorderRadius),
            gradient: widget.level == 0 ? LinearGradient(
              colors: [Colors.white, menuColor.withOpacity(0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: widget.level > 0 ? Colors.white : null,
            border: Border.all(
              color: menuColor.withOpacity(0.15),
              width: widget.level == 0 ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            children: [
              _buildMenuHeader(menuColor),
              if (widget.menu.hasChildren && widget.menu.isExpanded)
                _buildChildrenMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHeader(Color menuColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(MenuConstants.defaultBorderRadius),
        onTap: _handleMenuTap,
        child: Container(
          padding: MenuUtils.getItemPadding(widget.level),
          child: Row(
            children: [
              _buildMenuIcon(menuColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.menu.displayName,
                  style: TextStyle(
                    fontSize: widget.level == 0 ? 15 : 13,
                    fontWeight: widget.level == 0 ? FontWeight.bold : FontWeight.w600,
                    color: Colors.grey[800],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _buildTrailingIcon(menuColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(Color menuColor) {
    return Container(
      padding: EdgeInsets.all(widget.level == 0 ? 6 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            menuColor.withOpacity(0.8),
            menuColor,
          ],
        ),
        borderRadius: BorderRadius.circular(MenuConstants.iconContainerBorderRadius),
        boxShadow: [
          BoxShadow(
            color: menuColor.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        MenuUtils.getMenuIcon(widget.menu),
        color: Colors.white,
        size: MenuUtils.getIconSize(widget.level),
      ),
    );
  }

  Widget _buildTrailingIcon(Color menuColor) {
    if (widget.menu.hasChildren) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: menuColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(MenuConstants.trailingIconBorderRadius),
        ),
        child: AnimatedRotation(
          turns: widget.menu.isExpanded ? 0.5 : 0,
          duration: MenuConstants.fastAnimationDuration,
          curve: MenuConstants.menuExpansionCurve,
          child: Icon(
            Icons.keyboard_arrow_down,
            color: menuColor,
            size: MenuConstants.trailingIconSize,
          ),
        ),
      );
    } else if (MenuNavigationService.canNavigate(widget.menu)) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: menuColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(MenuConstants.trailingIconBorderRadius),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: MenuConstants.navigationIconSize,
          color: menuColor,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildChildrenMenu() {
    return AnimatedContainer(
      duration: MenuConstants.menuExpansionDuration,
      curve: MenuConstants.menuExpansionCurve,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: widget.menu.children
              .map((child) => MenuItem(
                    menu: child,
                    level: widget.level + 1,
                    onMenuUpdated: widget.onMenuUpdated,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
