import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Custom calendar widget với active state highlighting
class CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final DateTime? minDate;
  final DateTime? maxDate;

  const CustomCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.minDate,
    this.maxDate,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime currentMonth;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Month navigation
        _buildMonthNavigation(primaryColor),
        
        // Week headers
        _buildWeekHeaders(),
        
        const SizedBox(height: 8),
        
        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(primaryColor, daysInMonth, firstWeekday),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous month button
        IconButton(
          icon: Icon(Icons.chevron_left, color: primaryColor),
          onPressed: () {
            setState(() {
              currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
            });
          },
        ),
        
        // Month and Year selectors
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Month selector
              _buildMonthSelector(primaryColor),
              const SizedBox(width: 12),
              // Year selector  
              _buildYearSelector(primaryColor),
            ],
          ),
        ),
        
        // Next month button
        IconButton(
          icon: Icon(Icons.chevron_right, color: primaryColor),
          onPressed: () {
            setState(() {
              currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonthSelector(Color primaryColor) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return GestureDetector(
      onTap: () => _showMonthPicker(primaryColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              primaryColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.calendar_month,
                color: primaryColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              months[currentMonth.month - 1],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(Color primaryColor) {
    return GestureDetector(
      onTap: () => _showYearPicker(primaryColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              primaryColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.event,
                color: primaryColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              currentMonth.year.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(Color primaryColor) async {
    final months = [
      {'name': 'January', 'short': 'Jan'},
      {'name': 'February', 'short': 'Feb'},
      {'name': 'March', 'short': 'Mar'},
      {'name': 'April', 'short': 'Apr'},
      {'name': 'May', 'short': 'May'},
      {'name': 'June', 'short': 'Jun'},
      {'name': 'July', 'short': 'Jul'},
      {'name': 'August', 'short': 'Aug'},
      {'name': 'September', 'short': 'Sep'},
      {'name': 'October', 'short': 'Oct'},
      {'name': 'November', 'short': 'Nov'},
      {'name': 'December', 'short': 'Dec'},
    ];

    final result = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select Month',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Month Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthNumber = index + 1;
                  final isSelected = monthNumber == currentMonth.month;
                  
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(monthNumber),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                          ? LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                        color: isSelected ? null : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                            ? primaryColor 
                            : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            months[index]['short']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            monthNumber.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        currentMonth = DateTime(currentMonth.year, result);
      });
    }
  }

  Future<void> _showYearPicker(Color primaryColor) async {
    final minYear = widget.minDate?.year ?? 1900;
    final maxYear = widget.maxDate?.year ?? 2300;
    final years = List.generate(maxYear - minYear + 1, (index) => minYear + index);

    // Grid layout config to match gridDelegate
    const itemsPerRow = 4;
    const childAspectRatio = 1.4; // width / height
    const crossAxisSpacing = 8.0;
    const mainAxisSpacing = 8.0;

    // Key + guard to ensure scroll to selected just once
    final selectedYearKey = GlobalKey();
    bool didScrollToSelected = false;

    final result = await showDialog<int>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width * 0.9;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dialogWidth,
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.event,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Year',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            '$minYear - $maxYear',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Year Grid with precise auto-scroll
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use actual grid width to compute precise row height for initial approximation
                      final contentWidth = constraints.maxWidth;
                      final childCrossAxisExtent =
                          (contentWidth - (crossAxisSpacing * (itemsPerRow - 1))) / itemsPerRow;
                      final childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
                      final rowHeight = childMainAxisExtent + mainAxisSpacing;
                      final currentYearIndex = years.indexOf(currentMonth.year);
                      final rowsBefore = currentYearIndex >= 0 ? (currentYearIndex ~/ itemsPerRow) : 0;
                      double initialOffset = (rowsBefore * rowHeight) - rowHeight; // show one row above
                      if (initialOffset < 0) initialOffset = 0;
                      final controller = ScrollController(initialScrollOffset: initialOffset);

                      // Precisely compute the offset using RenderAbstractViewport.getOffsetToReveal
                      void jumpToSelectedWhenReady([int tries = 0]) {
                        if (didScrollToSelected) return;
                        if (controller.hasClients && selectedYearKey.currentContext != null) {
                          final renderObject = selectedYearKey.currentContext!.findRenderObject();
                          if (renderObject != null) {
                            final viewport = RenderAbstractViewport.of(renderObject);
                            final reveal = viewport.getOffsetToReveal(renderObject, 0.35).offset;
                            final max = controller.position.maxScrollExtent;
                            double target = reveal;
                            if (target < 0) target = 0;
                            if (target > max) target = max;
                            controller.jumpTo(target);
                            didScrollToSelected = true;
                            return;
                          }
                        }
                        if (tries < 24) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => jumpToSelectedWhenReady(tries + 1));
                        }
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToSelectedWhenReady());

                      return GridView.builder(
                        controller: controller,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: itemsPerRow,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: mainAxisSpacing,
                        ),
                        itemCount: years.length,
                        itemBuilder: (context, index) {
                          final year = years[index];
                          final isSelected = year == currentMonth.year;
                          final isCurrentYear = year == DateTime.now().year;
                          
                          return GestureDetector(
                            key: isSelected ? selectedYearKey : null,
                            onTap: () => Navigator.of(context).pop(year),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isSelected
                                  ? LinearGradient(
                                      colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : isCurrentYear
                                    ? LinearGradient(
                                        colors: [
                                          Colors.orange.withValues(alpha: 0.1),
                                          Colors.orange.withValues(alpha: 0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected || isCurrentYear ? null : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                    ? primaryColor 
                                    : isCurrentYear
                                      ? Colors.orange.withValues(alpha: 0.5)
                                      : Colors.grey.shade200,
                                  width: isSelected || isCurrentYear ? 1.5 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ] : isCurrentYear ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ] : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      year.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected 
                                          ? Colors.white 
                                          : isCurrentYear
                                            ? Colors.orange.shade700
                                            : primaryColor,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentYear && !isSelected)
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(2.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Footer info
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Current Year',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        currentMonth = DateTime(result, currentMonth.month);
      });
    }
  }

  Widget _buildWeekHeaders() {
    return Row(
      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          .map((day) => Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(Color primaryColor, int daysInMonth, int firstWeekday) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final dayNumber = index - (firstWeekday - 2);
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox(); // Empty cell
        }
        final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
        final isSelected = _isSameDay(date, widget.selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final isDisabled = _isDateDisabled(date);
        // Use orange for today
        const todayColor = Colors.orange;
        return GestureDetector(
          onTap: isDisabled ? null : () => widget.onDateChanged(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                ? primaryColor 
                : isToday 
                  ? todayColor.withOpacity(0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                ? Border.all(color: todayColor, width: 1)
                : null,
            ),
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                    ? Colors.white
                    : isDisabled
                      ? Colors.grey.shade400
                      : isToday
                        ? todayColor
                        : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return true;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return true;
    }
    return false;
  }
}
