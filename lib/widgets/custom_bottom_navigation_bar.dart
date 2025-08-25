import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _slideController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), // giảm horizontal padding
          child: Stack(
            children: [
              // Animated background indicator - fixed positioning
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  double screenWidth = MediaQuery.of(context).size.width;
                  double availableWidth = screenWidth - 8; // Account for horizontal padding (4 left + 4 right)
                  double itemWidth = availableWidth / widget.items.length;
                  double indicatorWidth = itemWidth; // Khít với availableWidth của mỗi item
                  double indicatorHeight = 65; // Khít với container height (height - vertical padding)
                  double left = widget.currentIndex * itemWidth + (itemWidth - indicatorWidth) / 2;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    left: left,
                    top: 0,
                    child: Container(
                      width: indicatorWidth,
                      height: indicatorHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.16),
                            Colors.blue.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Tab items with proper constraints
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.items.asMap().entries.map((entry) {
                  int index = entry.key;
                  BottomNavItem item = entry.value;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.zero,
                        onTap: () => widget.onTap(index),
                        child: SimpleBottomNavItem(
                          icon: item.icon,
                          label: item.label,
                          isSelected: widget.currentIndex == index,
                          onTap: () => widget.onTap(index),
                          index: index,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

class SimpleBottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const SimpleBottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<SimpleBottomNavItem> createState() => _SimpleBottomNavItemState();
}

class _SimpleBottomNavItemState extends State<SimpleBottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(SimpleBottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      // Trigger bounce animation when item becomes selected
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _bounceAnimation.value : _scaleAnimation.value,
            child: Container(
              height: 44, // Reduce height to prevent overflow
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), // Reduce vertical padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon - fixed size
                  Container(
                    height: 24,
                    width: 24,
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected ? Colors.blue : Colors.grey[600],
                      size: widget.isSelected ? 25 : 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label with fixed constraints
                  SizedBox(
                    height: 13, // Reduce height for text
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      style: TextStyle(
                        color: widget.isSelected ? Colors.blue : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                        height: 1.0,
                      ),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
