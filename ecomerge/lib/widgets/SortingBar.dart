import 'package:flutter/material.dart';
class SortingBar extends StatelessWidget {
  final double width;
  final Function(String)? onSortChanged;

  const SortingBar({
    Key? key,
    required this.width,
    this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sắp xếp theo:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 12, // horizontal spacing
            runSpacing: 12, // vertical spacing
            children: [
              _buildSortButton(
                icon: Icons.sort_by_alpha,
                label: 'Tên (A-Z)',
                onTap: () => onSortChanged?.call('name'),
              ),
              _buildSortButton(
                icon: Icons.attach_money,
                label: 'Giá',
                trailing: Icon(Icons.unfold_more, size: 16),
                onTap: () => onSortChanged?.call('price'),
              ),
              _buildSortButton(
                icon: Icons.new_releases_outlined,
                label: 'Mới nhất',
                onTap: () => onSortChanged?.call('new'),
              ),
              _buildSortButton(
                icon: Icons.star_border,
                label: 'Đánh giá',
                onTap: () => onSortChanged?.call('rating'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
