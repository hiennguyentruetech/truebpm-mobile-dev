import 'package:flutter/material.dart';
import 'package:truebpm/utils/core_constants.dart';

class CoreSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onClear;

  const CoreSearchInput({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.hintText,
    this.focusNode,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoreConstants.searchBorderRadius),
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 7,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(7),
              child: Icon(
                Icons.search,
                color: Colors.blue.shade400,
                size: 20,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear button (only show when there's text)
                if (controller.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () {
                          controller.clear();
                          onClear?.call();
                          focusNode?.requestFocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            Icons.clear,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Search button
                Container(
                  margin: const EdgeInsets.all(10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: onSearch,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade500, Colors.blue.shade700],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          onSubmitted: (_) => onSearch(),
          onChanged: (value) {
            // Trigger rebuild to show/hide clear button
            (context as Element).markNeedsBuild();
          },
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
        ),
      ),
    );
  }
}
