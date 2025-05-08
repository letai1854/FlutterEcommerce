import 'package:flutter/material.dart';

class SortingBar extends StatefulWidget {
  final double width;
  final Function(String) onSortChanged;
  final String currentSortMethod;
  final String currentSortDir;
  final Widget Function(String)? buildSortDirectionIndicator;

  const SortingBar({
    Key? key,
    required this.width,
    required this.onSortChanged,
    required this.currentSortMethod,
    required this.currentSortDir,
    this.buildSortDirectionIndicator,
  }) : super(key: key);

  @override
  State<SortingBar> createState() => _SortingBarState();
}

class _SortingBarState extends State<SortingBar> {
  // Define sorting options with display names and method identifiers
  final List<Map<String, String>> _sortOptions = [
    {'name': 'Mới nhất', 'method': 'createdDate'},
    {'name': 'Giá', 'method': 'price'},
    {'name': 'A-Z', 'method': 'name'},
    {'name': 'Đánh giá', 'method': 'rating'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Sắp xếp theo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(_sortOptions.length, (index) {
              final option = _sortOptions[index];
              final bool isSelected = widget.currentSortMethod == option['method'];
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => widget.onSortChanged(option['method'] ?? ''),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option['name'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.blue : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected && widget.buildSortDirectionIndicator != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: widget.buildSortDirectionIndicator!(option['method'] ?? ''),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
