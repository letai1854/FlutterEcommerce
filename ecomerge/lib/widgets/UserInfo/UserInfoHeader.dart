import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/widgets/Points/PointsContent.dart';

class UserInfoHeader extends StatelessWidget {
  const UserInfoHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {'selectedIndex': 0},
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),

          // User avatar - Using cached image and FutureBuilder
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: UserInfo().currentUser?.avatar != null
                  ? FutureBuilder<Uint8List?>(
                      future: UserService()
                          .getAvatarBytes(UserInfo().currentUser?.avatar),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                              child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)));
                        } else if (snapshot.hasData && snapshot.data != null) {
                          // Use cached image if available
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        } else {
                          // Fall back to network image if cache failed
                          return Image.network(
                            UserInfo().currentUser!.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                child: const Icon(Icons.person,
                                    color: Colors.white),
                              );
                            },
                          );
                        }
                      },
                    )
                  : Container(
                      color: Colors.grey,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Username - Get from UserInfo
          Expanded(
            child: Text(
              UserInfo().currentUser?.fullName ?? "",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Rewards button
              _buildIconButtonWithBadge(
                icon: Icons.star,
                iconColor: Colors.amber,
                badgeColor: Colors.amber[600]!,
                badgeText: '5',
                onPressed: () => _navigateToPoints(context),
                tooltip: 'Điểm thưởng',
              ),
              const SizedBox(width: 16),

              // Cart button
              _buildIconButtonWithBadge(
                icon: Icons.shopping_cart,
                badgeColor: Colors.red,
                badgeText: '2',
                onPressed: () => Navigator.pushNamed(context, '/cart',
                    arguments: {'selectedIndex': -1}),
                tooltip: 'Giỏ hàng',
              ),
              const SizedBox(width: 16),

              // Chat button
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat',
                      arguments: {'selectedIndex': -1});
                },
                tooltip: 'Chat',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for icon buttons with badges
  Widget _buildIconButtonWithBadge({
    required IconData icon,
    Color iconColor = Colors.black,
    required Color badgeColor,
    required String badgeText,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Stack(
        alignment: icon == Icons.star ? Alignment.center : Alignment.topRight,
        children: [
          Icon(icon, color: iconColor),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  // Navigation helper
  void _navigateToPoints(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              "Điểm thưởng",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
          body: const PointsContent(),
        ),
        settings: RouteSettings(
          arguments: {'selectedIndex': -1},
        ),
      ),
    );
  }
}
