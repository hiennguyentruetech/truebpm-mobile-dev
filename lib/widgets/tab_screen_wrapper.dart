import 'package:flutter/material.dart';

class TabScreenWrapper extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> stackNavigators;

  const TabScreenWrapper({
    super.key,
    required this.selectedIndex,
    required this.stackNavigators,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8F9FA),
            Colors.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: IndexedStack(
        index: selectedIndex,
        children: stackNavigators,
      ),
    );
  }
}
