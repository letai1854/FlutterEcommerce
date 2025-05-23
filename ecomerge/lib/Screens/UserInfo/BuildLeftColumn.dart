import 'dart:typed_data';
import 'package:e_commerce_app/database/models/user_model.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';

class BuildLeftColumn extends StatefulWidget {
  final MainSection selectedMainSection;
  final ProfileSection selectedProfileSection;
  final bool isProfileExpanded;
  final Function(MainSection) onMainSectionChanged;
  final Function(ProfileSection) onProfileSectionChanged;
  final VoidCallback onToggleProfileExpanded;

  const BuildLeftColumn({
    super.key,
    required this.selectedMainSection,
    required this.selectedProfileSection,
    required this.isProfileExpanded,
    required this.onMainSectionChanged,
    required this.onProfileSectionChanged,
    required this.onToggleProfileExpanded,
  });

  @override
  State<BuildLeftColumn> createState() => _BuildLeftColumnState();
}

class _BuildLeftColumnState extends State<BuildLeftColumn> {
  Future<Uint8List?>? _avatarFuture;
  String?
      _fetchedAvatarUrl; // To track the URL for which _avatarFuture was created

  @override
  void initState() {
    super.initState();
    _updateAvatarFutureBasedOnUserInfo();
    UserInfo().addListener(_onUserInfoChanged);
  }

  @override
  void dispose() {
    UserInfo().removeListener(_onUserInfoChanged);
    super.dispose();
  }

  void _onUserInfoChanged() {
    if (mounted) {
      final newAvatarUrl = UserInfo().currentUser?.avatar;
      if (newAvatarUrl != _fetchedAvatarUrl) {
        _updateAvatarFutureBasedOnUserInfo();
      }
      setState(
          () {}); // Rebuild to reflect changes (e.g., username or new avatar future)
    }
  }

  void _updateAvatarFutureBasedOnUserInfo() {
    final currentUrl = UserInfo().currentUser?.avatar;
    _fetchedAvatarUrl = currentUrl; // Update the tracking URL

    if (currentUrl != null && currentUrl.isNotEmpty) {
      _avatarFuture = UserService().getAvatarBytes(currentUrl);
    } else {
      _avatarFuture = Future.value(null); // Use a completed future with null
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = UserInfo().currentUser;
    final String? currentActualAvatarUrl =
        currentUser?.avatar; // Get the most current URL for display logic
    final String userName = currentUser?.fullName ?? 'user';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and user name
        Center(
          child: Column(
            children: [
              (currentActualAvatarUrl != null &&
                      currentActualAvatarUrl.isNotEmpty)
                  ? FutureBuilder<Uint8List?>(
                      future: _avatarFuture, // Use the stored future
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _avatarFuture != null) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundImage: MemoryImage(snapshot.data!),
                          );
                        } else {
                          // Fallback to NetworkImage if future failed or has no data,
                          // using the currentActualAvatarUrl.
                          // This branch is also hit if _avatarFuture was Future.value(null)
                          if (currentActualAvatarUrl != null &&
                              currentActualAvatarUrl.isNotEmpty) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: NetworkImage(
                                  currentActualAvatarUrl), // Use currentActualAvatarUrl
                              onBackgroundImageError: (_, __) {},
                            );
                          }
                          // If all else fails
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person,
                                size: 50, color: Colors.grey),
                          );
                        }
                      },
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person,
                          size: 50, color: Colors.grey),
                    ),
              const SizedBox(height: 16),
              Text(
                userName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),

        // Navigation menu
        ListTile(
          title: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              const Text('Quản lý hồ sơ'),
              const Spacer(),
              Icon(widget.isProfileExpanded
                  ? Icons.expand_less
                  : Icons.expand_more),
            ],
          ),
          selected: widget.selectedMainSection == MainSection.profile,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {
            widget.onMainSectionChanged(MainSection.profile);
            widget.onToggleProfileExpanded();
          },
        ),

        // Profile sub-menu (expandable)
        const SizedBox(height: 3),
        if (widget.isProfileExpanded)
          Column(
            children: [
              _buildProfileSubItem(
                'Sửa thông tin cá nhân',
                ProfileSection.personalInfo,
                Icons.edit,
              ),
              // _buildProfileSubItem(
              //   'Quên mật khẩu',
              //   ProfileSection.forgotPassword,
              //   Icons.lock_reset,
              // ),
              _buildProfileSubItem(
                'Đổi mật khẩu',
                ProfileSection.changePassword,
                Icons.lock,
              ),
              _buildProfileSubItem(
                'Quản lý địa chỉ giao hàng',
                ProfileSection.addresses,
                Icons.location_on,
                refreshAction: () {
                  // This will be called when the address section is selected
                  // The reload functionality is already in the AddressManagement widget
                  print('Loading addresses...');
                },
              ),
            ],
          ),

        ListTile(
          leading: const Icon(Icons.shopping_bag),
          title: const Text('Đơn hàng'),
          selected: widget.selectedMainSection == MainSection.orders,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {
            widget.onMainSectionChanged(MainSection.orders);
          },
        ),

        ListTile(
          leading: const Icon(Icons.stars),
          title: const Text('Điểm tích lũy'),
          selected: widget.selectedMainSection == MainSection.points,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {
            widget.onMainSectionChanged(MainSection.points);
          },
        ),
        if (UserInfo().currentUser != null &&
            UserInfo().currentUser!.role.toString() == UserRole.quan_tri.name)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin'),
            selected: widget.selectedMainSection ==
                MainSection.admin, // Use correct section
            selectedTileColor: Colors.blue.withOpacity(0.1),
            onTap: () {
              // Navigate to admin page
              Navigator.pushNamed(context, '/admin');
            },
          ),
      ],
    );
  }

  // Profile sub-menu items with optional refresh action
  Widget _buildProfileSubItem(
      String title, ProfileSection section, IconData icon,
      {VoidCallback? refreshAction}) {
    // Check if user is logged in
    final bool isLoggedIn = UserInfo().currentUser != null;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        selected: widget.selectedProfileSection == section &&
            widget.selectedMainSection == MainSection.profile,
        selectedTileColor:
            const Color.fromARGB(255, 149, 150, 151).withOpacity(0.1),
        dense: true,
        onTap: isLoggedIn
            ? () {
                widget.onMainSectionChanged(MainSection.profile);
                widget.onProfileSectionChanged(section);
                // Call refresh action if provided (for address section)
                if (refreshAction != null) {
                  refreshAction();
                }
              }
            : () {
                // Show login message when not logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Vui lòng đăng nhập để sử dụng tính năng này'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        // Add visual indication that item is disabled
        enabled: isLoggedIn,
        tileColor: !isLoggedIn ? Colors.grey.withOpacity(0.1) : null,
      ),
    );
  }
}
