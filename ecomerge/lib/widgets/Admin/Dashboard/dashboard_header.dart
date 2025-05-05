import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';

class DashboardHeader extends StatefulWidget {
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
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Listen for UserInfo changes and update UI
    UserInfo().addListener(_onUserInfoChanged);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    UserInfo().removeListener(_onUserInfoChanged);
    super.dispose();
  }

  // Called when UserInfo changes (like avatar or name updates)
  void _onUserInfoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info
    final currentUser = UserInfo().currentUser;
    final String? avatarUrl = currentUser?.avatar;
    final String userName = currentUser?.fullName ?? 'User';

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
              if (widget.onMenuTap != null)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: widget.onMenuTap,
                ),
              const SizedBox(width: 8),
              // Page title
              Text(
                widget.title,
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
                  Navigator.pop(context, "/home");
                },
              ),

              // Always show user name on mobile
              if (widget.isMobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // User profile section - show for all screens
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? FutureBuilder<Uint8List?>(
                          future: _userService.getAvatarBytes(avatarUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator(strokeWidth: 2);
                            } else if (snapshot.hasData &&
                                snapshot.data != null) {
                              // Use cached image if available
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackAvatar(userName),
                              );
                            } else {
                              // Fall back to network image if cache failed
                              return Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackAvatar(userName),
                              );
                            }
                          },
                        )
                      : _buildFallbackAvatar(userName),
                ),
              ),

              // Show username next to avatar on tablet/desktop
              if (!widget.isMobile)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to create fallback avatar with first letter of name
  Widget _buildFallbackAvatar(String userName) {
    return Container(
      color: Colors.grey,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
