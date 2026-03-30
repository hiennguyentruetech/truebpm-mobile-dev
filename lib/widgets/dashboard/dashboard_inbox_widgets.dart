part of 'dashboard_widgets.dart';

class DashboardInboxCard extends StatelessWidget {
  final InboxDataItem item;
  final VoidCallback? onTap;
  final int index;

  const DashboardInboxCard({
    super.key,
    required this.item,
    this.onTap,
    this.index = 0,
  });

  // Icon colors based on index (matching web design)
  Color get _iconColor {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  Color get _iconBgColor {
    final bgColors = [
      const Color(0xFFEFF6FF), // Light Blue
      const Color(0xFFFFF7ED), // Light Orange
      const Color(0xFFECFDF5), // Light Green
      const Color(0xFFF5F3FF), // Light Purple
      const Color(0xFFFDF2F8), // Light Pink
      const Color(0xFFECFEFF), // Light Cyan
    ];
    return bgColors[index % bgColors.length];
  }

  // Value color based on value (negative = blue, zero/positive = default)
  Color get _valueColor {
    // Safely check if value is negative
    final numValue = item.value is num ? item.value as num : 0;
    if (numValue < 0) {
      return const Color(0xFF3B82F6); // Blue for negative
    }
    return _iconColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 100,
      margin: const EdgeInsets.only(right: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon + Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _iconBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, color: _iconColor, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Value + Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      item.formattedValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _valueColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (item.unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        item.unit!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling inbox list with web-style design
class DashboardInboxList extends StatelessWidget {
  final List<InboxDataItem> items;
  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int>? onYearChanged;
  final bool isLoading;

  const DashboardInboxList({
    super.key,
    required this.items,
    required this.selectedYear,
    required this.availableYears,
    this.onYearChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blue.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Label on left, Year selector on right
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label on left
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'My Watchlist',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Year selector on right
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        isDense: true,
                        dropdownColor: Colors.blue.shade700,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        items: availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onYearChanged?.call(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inbox cards - horizontal scroll
            SizedBox(
              height: 110,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    )
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return DashboardInboxCard(
                          item: items[index],
                          index: index,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

/// Chart card wrapper with title and actions - Premium Design
