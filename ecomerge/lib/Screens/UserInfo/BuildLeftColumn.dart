import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and user name
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage:
                    NetworkImage('https://via.placeholder.com/150'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lê Văn Tài',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                'Sửa thông tin cá nhân',
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
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Admin'),
          selected: widget.selectedMainSection == MainSection.points,
          selectedTileColor: Colors.blue.withOpacity(0.1),
          onTap: () {},
        ),
      ],
    );
  }

  // Profile sub-menu items
  Widget _buildProfileSubItem(
      String title, ProfileSection section, IconData icon) {
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
        onTap: () {
          widget.onMainSectionChanged(MainSection.profile);
          widget.onProfileSectionChanged(section);
        },
      ),
    );
  }
}
