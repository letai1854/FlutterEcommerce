import 'package:e_commerce_app/Screens/UserInfo/BuildLeftColumn.dart';
import 'package:e_commerce_app/Screens/UserInfo/RightColumnContent.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserInfoTablet extends StatefulWidget {
  // Props received from parent
  final MainSection selectedMainSection;
  final ProfileSection selectedProfileSection;
  final bool isProfileExpanded;
  final int selectedOrderTab;
  final int selectedOrderStatus;

  // Callbacks
  final Function(MainSection) onMainSectionChanged;
  final Function(ProfileSection) onProfileSectionChanged;
  final VoidCallback onToggleProfileExpanded;
  final Function(int) onOrderTabChanged;
  final Function(int) onOrderStatusChanged;

  // Content builder functions
  final Widget Function() buildPersonalInfoForm;
  final Widget Function() buildChangePasswordContent;
  final Widget Function() buildAddressManagement;
  final Widget Function() buildOrdersContent;
  final Widget Function() buildPointsContent;
  final Widget Function() buildForgotPasswordContent;

  const UserInfoTablet({
    super.key,
    required this.selectedMainSection,
    required this.selectedProfileSection,
    required this.isProfileExpanded,
    required this.selectedOrderTab,
    required this.selectedOrderStatus,
    required this.onMainSectionChanged,
    required this.onProfileSectionChanged,
    required this.onToggleProfileExpanded,
    required this.onOrderTabChanged,
    required this.onOrderStatusChanged,
    required this.buildPersonalInfoForm,
    required this.buildChangePasswordContent,
    required this.buildAddressManagement,
    required this.buildOrdersContent,
    required this.buildPointsContent,
    required this.buildForgotPasswordContent,
  });

  @override
  State<UserInfoTablet> createState() => _UserInfoTabletState();
}

class _UserInfoTabletState extends State<UserInfoTablet> {
  final GlobalKey _footerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: NavbarhomeTablet(context),
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _buildContent(),
      ),
      bottomNavigationBar: isMobile ? BottomNavBar() : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: GestureDetector(
              onTap: () {
                print("Nhấn vào thông tin người dùng");
              },
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: const [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Le Van Tai',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt),
            title: const Text('Đăng ký'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person_3_rounded),
            title: const Text('Đăng nhập'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Nhắn tin'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Get responsive measurements
    final screenWidth = MediaQuery.of(context).size.width;

    // For tablet, we need more flexible padding
    final horizontalPadding = screenWidth < 600 ? 10.0 : 20.0;

    return LayoutBuilder(builder: (context, constraints) {
      // For tablet, we might want to switch to a column layout if width is too small
      final useColumnLayout = constraints.maxWidth < 780;

      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 30),
              child: useColumnLayout
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column navigation - full width in column layout
                        Container(
                          width: double.infinity,
                          child: _buildLeftColumn(),
                        ),
                        const SizedBox(height: 30),
                        // Right column content
                        Container(
                          width: double.infinity,
                          child: _buildRightColumn(),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - fixed width for stability
                        Container(
                          width: 250,
                          child: _buildLeftColumn(),
                        ),
                        const SizedBox(width: 20),
                        // Right column - expanding to take remaining space
                        Expanded(
                          child: _buildRightColumn(),
                        ),
                      ],
                    ),
            ),

            // Footer
            if (kIsWeb) Footer(key: _footerKey),
          ],
        ),
      );
    });
  }

  // Extracted left column to avoid code duplication
  Widget _buildLeftColumn() {
    return BuildLeftColumn(
      selectedMainSection: widget.selectedMainSection,
      selectedProfileSection: widget.selectedProfileSection,
      isProfileExpanded: widget.isProfileExpanded,
      onMainSectionChanged: widget.onMainSectionChanged,
      onProfileSectionChanged: widget.onProfileSectionChanged,
      onToggleProfileExpanded: widget.onToggleProfileExpanded,
    );
  }

  // Right column content based on selection
  Widget _buildRightColumn() {
    return RightColumnContent(
      selectedMainSection: widget.selectedMainSection,
      selectedProfileSection: widget.selectedProfileSection,
      buildPersonalInfoForm: widget.buildPersonalInfoForm,
      buildChangePasswordContent: widget.buildChangePasswordContent,
      buildAddressManagement: widget.buildAddressManagement,
      buildOrdersContent: widget.buildOrdersContent,
      buildPointsContent: widget.buildPointsContent,
      buildForgotPasswordContent: widget.buildForgotPasswordContent,
    );
  }
}
