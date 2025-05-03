import 'package:e_commerce_app/Screens/UserInfo/BuildLeftColumn.dart';
import 'package:e_commerce_app/Screens/UserInfo/RightColumnContent.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserInfoDesktop extends StatefulWidget {
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

  const UserInfoDesktop({
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
  State<UserInfoDesktop> createState() => _UserInfoDesktopState();
}

class _UserInfoDesktopState extends State<UserInfoDesktop> {
  final GlobalKey _footerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust ratio based on screen width
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
                      minWidth: 200,
                      maxWidth: 350,
                    ),
                    child: BuildLeftColumn(
                      selectedMainSection: widget.selectedMainSection,
                      selectedProfileSection: widget.selectedProfileSection,
                      isProfileExpanded: widget.isProfileExpanded,
                      onMainSectionChanged: widget.onMainSectionChanged,
                      onProfileSectionChanged: widget.onProfileSectionChanged,
                      onToggleProfileExpanded: widget.onToggleProfileExpanded,
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
