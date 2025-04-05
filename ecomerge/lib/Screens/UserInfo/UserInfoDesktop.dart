import 'package:e_commerce_app/Screens/UserInfo/BuildLeftColumn.dart';
import 'package:e_commerce_app/Screens/UserInfo/RightColumnContent.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/Address/AddressManagement.dart';
import 'package:e_commerce_app/widgets/Info/PersonalInfoForm.dart';
import 'package:e_commerce_app/widgets/Order/OrdersContent.dart';
import 'package:e_commerce_app/widgets/Password/ChangePasswordContent.dart';
import 'package:e_commerce_app/widgets/Password/ForgotPasswordContentInfo.dart';
import 'package:e_commerce_app/widgets/Points/PointsContent.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserInfoDesktop extends StatefulWidget {
  const UserInfoDesktop({super.key});

  @override
  State<UserInfoDesktop> createState() => _UserInfoDesktopState();
}

class _UserInfoDesktopState extends State<UserInfoDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Navbarhomedesktop(),
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

  final GlobalKey _footerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust ratio based on screen width
    // For smaller screens, increase left column proportion
    final leftColumnRatio = screenWidth < 1400 ? 0.35 : 0.27;
    final rightColumnRatio = 1.0 - leftColumnRatio;

    // Adjust horizontal padding based on screen width
    final horizontalPadding =
        screenWidth < 1200 ? 20.0 : (screenWidth < 1400 ? 60.0 : 140.0);

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column with responsive width
                  Container(
                    width: (constraints.maxWidth - horizontalPadding * 2) *
                            leftColumnRatio -
                        20,
                    constraints: BoxConstraints(
                      minWidth: 200, // Minimum width for left column
                      maxWidth: 350, // Maximum width for left column
                    ),
                    child: BuildLeftColumn(
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
