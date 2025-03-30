import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/Password/ForgotPasswordContentInfo.dart';
import 'package:flutter/material.dart';

class RightColumnContent extends StatefulWidget {
  final MainSection selectedMainSection;
  final ProfileSection selectedProfileSection;
  final Widget Function() buildPersonalInfoForm;
  final Widget Function() buildChangePasswordContent;
  final Widget Function() buildAddressManagement;
  final Widget Function() buildOrdersContent;
  final Widget Function() buildPointsContent;

  const RightColumnContent({
    Key? key,
    required this.selectedMainSection,
    required this.selectedProfileSection,
    required this.buildPersonalInfoForm,
    required this.buildChangePasswordContent,
    required this.buildAddressManagement,
    required this.buildOrdersContent,
    required this.buildPointsContent,
  }) : super(key: key);

  @override
  State<RightColumnContent> createState() => _RightColumnContentState();
}

class _RightColumnContentState extends State<RightColumnContent> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedMainSection == MainSection.profile) {
      switch (widget.selectedProfileSection) {
        case ProfileSection.personalInfo:
          return widget.buildPersonalInfoForm();
        case ProfileSection.forgotPassword:
          return const ForgotPasswordContentInfo();
        case ProfileSection.changePassword:
          return widget.buildChangePasswordContent();
        case ProfileSection.addresses:
          return widget.buildAddressManagement();
      }
    } else if (widget.selectedMainSection == MainSection.orders) {
      return widget.buildOrdersContent();
    } else if (widget.selectedMainSection == MainSection.points) {
      return widget.buildPointsContent();
    }

    // Default fallback
    return widget.buildPersonalInfoForm();
  }
}
