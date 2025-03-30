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
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
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
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                          const SizedBox(width: 10),
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
              title: const Text('Đăng ký'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person_3_rounded),
              title: const Text('Đăng nhập'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Nhắn tin'),
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

// Main sections in the left navigation

class _BodyState extends State<Body> {
  MainSection _selectedMainSection = MainSection.profile;
  ProfileSection _selectedProfileSection = ProfileSection.personalInfo;
  bool _isProfileExpanded = true;

  // For order status tabs
  int _selectedOrderTab = 0;

  final GlobalKey _footerKey = GlobalKey(); // Thêm key cho footer

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final screenWidth = MediaQuery.of(context).size.width;

    // Điều chỉnh tỷ lệ dựa trên kích thước màn hình
    // Màn hình nhỏ: left column chiếm 35-40%, right column chiếm phần còn lại
    // Màn hình lớn: left column chiếm 25%, right column chiếm 75%
    final leftColumnRatio = screenWidth < 1400 ? 0.35 : 0.27;
    final rightColumnRatio = 1.0 - leftColumnRatio;

    // Căn chỉnh padding dựa trên kích thước màn hình
    final horizontalPadding = screenWidth < 1400 ? 140.0 : 140.0;

    return SingleChildScrollView(
      child: Column(
        // Đổi Container thành Column để chứa cả body và footer
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - tỷ lệ thay đổi theo kích thước màn hình
                SizedBox(
                  width: MediaQuery.of(context).size.width * leftColumnRatio -
                      horizontalPadding, // Trừ đi padding
                  child: BuildLeftColumn(
                    // Truyền các biến và callback cần thiết
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
                  ),
                ),

                const SizedBox(width: 40),

                // Right column - tỷ lệ thay đổi theo kích thước màn hình
                Expanded(
                  child: SizedBox(
                    width:
                        MediaQuery.of(context).size.width * rightColumnRatio -
                            horizontalPadding -
                            40, // Trừ đi padding và khoảng cách giữa 2 cột
                    child: _buildRightColumn(),
                  ),
                ),
              ],
            ),
          ),

          // Thêm Footer vào đây
          if (kIsWeb) Footer(key: _footerKey),
        ],
      ),
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
