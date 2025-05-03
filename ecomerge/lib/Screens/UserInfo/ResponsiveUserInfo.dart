import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoDesktop.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoMobile.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTablet.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/Address/AddressManagement.dart';
import 'package:e_commerce_app/widgets/Info/PersonalInfoForm.dart';
import 'package:e_commerce_app/widgets/Order/OrdersContent.dart';
import 'package:e_commerce_app/widgets/Password/ChangePasswordContent.dart';
import 'package:e_commerce_app/widgets/Password/ForgotPasswordContentInfo.dart';
import 'package:e_commerce_app/widgets/Points/PointsContent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveUserInfo extends StatefulWidget {
  const ResponsiveUserInfo({super.key});

  @override
  State<ResponsiveUserInfo> createState() => _ResponsiveUserInfoState();
}

class _ResponsiveUserInfoState extends State<ResponsiveUserInfo> {
  // Centralized state variables moved from UserInfoDesktop/Tablet
  MainSection _selectedMainSection = MainSection.profile;
  ProfileSection _selectedProfileSection = ProfileSection.personalInfo;
  bool _isProfileExpanded = true;
  int _selectedOrderTab = 0;
  int _selectedOrderStatus = 0;

  // Handler methods
  void _handleMainSectionChanged(MainSection section) {
    setState(() {
      _selectedMainSection = section;
    });
  }

  void _handleProfileSectionChanged(ProfileSection section) {
    setState(() {
      _selectedProfileSection = section;
    });
  }

  void _handleToggleProfileExpanded() {
    setState(() {
      _isProfileExpanded = !_isProfileExpanded;
    });
  }

  void _handleOrderTabChanged(int tabIndex) {
    setState(() {
      _selectedOrderTab = tabIndex;
    });
  }

  void _handleOrderStatusChanged(int statusIndex) {
    setState(() {
      _selectedOrderStatus = statusIndex;
    });
  }

  // Content building functions that can be shared between layouts
  Widget buildPersonalInfoForm() {
    return const PersonalInfoForm();
  }

  Widget buildChangePasswordContent() {
    return const ChangePasswordContent();
  }

  Widget buildAddressManagement() {
    return const AddressManagement();
  }

  Widget buildOrdersContent() {
    return OrdersContent(
      selectedTab: _selectedOrderTab,
      onTabChanged: _handleOrderTabChanged,
    );
  }

  Widget buildPointsContent() {
    return const PointsContent();
  }

  Widget buildForgotPasswordContent() {
    return const ForgotPasswordContentInfo();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on an actual mobile device (not just small screen)
    final bool isRealMobileDevice = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    // If on real mobile device, use mobile layout regardless of screen size
    if (isRealMobileDevice) {
      return const UserInfoMobile();
    }

    // For web or desktop, use responsive layouts based on screen size
    return ResponsiveLayout(
      mobileScaffold: UserInfoTablet(
        selectedMainSection: _selectedMainSection,
        selectedProfileSection: _selectedProfileSection,
        isProfileExpanded: _isProfileExpanded,
        selectedOrderTab: _selectedOrderTab,
        selectedOrderStatus: _selectedOrderStatus,
        onMainSectionChanged: _handleMainSectionChanged,
        onProfileSectionChanged: _handleProfileSectionChanged,
        onToggleProfileExpanded: _handleToggleProfileExpanded,
        onOrderTabChanged: _handleOrderTabChanged,
        onOrderStatusChanged: _handleOrderStatusChanged,
        buildPersonalInfoForm: buildPersonalInfoForm,
        buildChangePasswordContent: buildChangePasswordContent,
        buildAddressManagement: buildAddressManagement,
        buildOrdersContent: buildOrdersContent,
        buildPointsContent: buildPointsContent,
        buildForgotPasswordContent: buildForgotPasswordContent,
      ),
      tableScaffold: UserInfoTablet(
        selectedMainSection: _selectedMainSection,
        selectedProfileSection: _selectedProfileSection,
        isProfileExpanded: _isProfileExpanded,
        selectedOrderTab: _selectedOrderTab,
        selectedOrderStatus: _selectedOrderStatus,
        onMainSectionChanged: _handleMainSectionChanged,
        onProfileSectionChanged: _handleProfileSectionChanged,
        onToggleProfileExpanded: _handleToggleProfileExpanded,
        onOrderTabChanged: _handleOrderTabChanged,
        onOrderStatusChanged: _handleOrderStatusChanged,
        buildPersonalInfoForm: buildPersonalInfoForm,
        buildChangePasswordContent: buildChangePasswordContent,
        buildAddressManagement: buildAddressManagement,
        buildOrdersContent: buildOrdersContent,
        buildPointsContent: buildPointsContent,
        buildForgotPasswordContent: buildForgotPasswordContent,
      ),
      destopScaffold: UserInfoDesktop(
        selectedMainSection: _selectedMainSection,
        selectedProfileSection: _selectedProfileSection,
        isProfileExpanded: _isProfileExpanded,
        selectedOrderTab: _selectedOrderTab,
        selectedOrderStatus: _selectedOrderStatus,
        onMainSectionChanged: _handleMainSectionChanged,
        onProfileSectionChanged: _handleProfileSectionChanged,
        onToggleProfileExpanded: _handleToggleProfileExpanded,
        onOrderTabChanged: _handleOrderTabChanged,
        onOrderStatusChanged: _handleOrderStatusChanged,
        buildPersonalInfoForm: buildPersonalInfoForm,
        buildChangePasswordContent: buildChangePasswordContent,
        buildAddressManagement: buildAddressManagement,
        buildOrdersContent: buildOrdersContent,
        buildPointsContent: buildPointsContent,
        buildForgotPasswordContent: buildForgotPasswordContent,
      ),
    );
  }
}
