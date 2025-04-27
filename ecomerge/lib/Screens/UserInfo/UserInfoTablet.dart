import 'package:e_commerce_app/Screens/UserInfo/BuildLeftColumn.dart';
import 'package:e_commerce_app/Screens/UserInfo/RightColumnContent.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/Address/AddressManagement.dart';
import 'package:e_commerce_app/widgets/Info/PersonalInfoForm.dart';
import 'package:e_commerce_app/widgets/Order/OrdersContent.dart';
import 'package:e_commerce_app/widgets/Password/ChangePasswordContent.dart';
import 'package:e_commerce_app/widgets/Password/ForgotPasswordContentInfo.dart';
import 'package:e_commerce_app/widgets/Points/PointsContent.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserInfoTablet extends StatelessWidget {
  const UserInfoTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: NavbarhomeTablet(context),
      ),
      drawer: Drawer(
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
                        // Bọc lại để tránh lỗi
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
      ),
      body: const SafeArea(
        child: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  MainSection _selectedMainSection = MainSection.profile;
  ProfileSection _selectedProfileSection = ProfileSection.personalInfo;
  bool _isProfileExpanded = true;

  // For order status tabs
  int _selectedOrderTab = 0;
  int _selectedOrderStatus = 0;
  final GlobalKey _footerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
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
      selectedMainSection: _selectedMainSection,
      selectedProfileSection: _selectedProfileSection,
      isProfileExpanded: _isProfileExpanded,
      onMainSectionChanged: (MainSection section) {
        setState(() {
          _selectedMainSection = section;
        });
      },
      onProfileSectionChanged: (ProfileSection section) {
        setState(() {
          _selectedProfileSection = section;
        });
      },
      onToggleProfileExpanded: () {
        setState(() {
          _isProfileExpanded = !_isProfileExpanded;
        });
      },
    );
  }

  // Right column content based on selection
  Widget _buildRightColumn() {
    return RightColumnContent(
      selectedMainSection: _selectedMainSection,
      selectedProfileSection: _selectedProfileSection,
      buildPersonalInfoForm: _buildPersonalInfoForm,
      buildChangePasswordContent: _buildChangePasswordContent,
      buildAddressManagement: _buildAddressManagement,
      buildOrdersContent: _buildOrdersContent,
      buildPointsContent: _buildPointsContent,
    );
  }

  // Replace these methods with calls to the respective widgets
  Widget _buildForgotPasswordContent() {
    return const ForgotPasswordContentInfo();
  }

  Widget _buildPersonalInfoForm() {
    return const PersonalInfoForm();
  }

  // Change password content
  Widget _buildChangePasswordContent() {
    return const ChangePasswordContent();
  }

  // Address management content
  Widget _buildAddressManagement() {
    return const AddressManagement();
  }

  // Orders content with tabs
  Widget _buildOrdersContent() {
    return const OrdersContent();
  }

  // Points content
  Widget _buildPointsContent() {
    return const PointsContent();
  }

  // Helper method to format currency
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
