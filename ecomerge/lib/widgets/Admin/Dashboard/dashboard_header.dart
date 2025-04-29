import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final bool isMobile;

  const DashboardHeader({
    Key? key,
    required this.title,
    this.onMenuTap,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Menu button for mobile and tablet
              if (onMenuTap != null)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuTap,
                ),
              const SizedBox(width: 8),
              // Page title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Right side of header
          Row(
            children: [
              // Home button
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: 'Trang chủ',
                onPressed: () {
                  // Navigate to home page
                  Navigator.pop(context);
                },
              ),
              // Chat box button
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: 'Chat',
                onPressed: () {
                  // Open chat functionality
                },
              ),
              // User profile section
              if (!isMobile) // Hide on very small screens
                const SizedBox(width: 8),
              if (!isMobile) // Hide on very small screens
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Text('A', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
