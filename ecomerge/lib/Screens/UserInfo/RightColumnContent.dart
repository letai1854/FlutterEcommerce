import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:flutter/material.dart';

class RightColumnContent extends StatelessWidget {
  final MainSection selectedMainSection;
  final ProfileSection selectedProfileSection;
  final Widget Function() buildPersonalInfoForm;
  final Widget Function() buildChangePasswordContent;
  final Widget Function() buildAddressManagement;
  final Widget Function() buildOrdersContent;
  final Widget Function() buildPointsContent;
  final Widget Function() buildForgotPasswordContent;

  const RightColumnContent({
    Key? key,
    required this.selectedMainSection,
    required this.selectedProfileSection,
    required this.buildPersonalInfoForm,
    required this.buildChangePasswordContent,
    required this.buildAddressManagement,
    required this.buildOrdersContent,
    required this.buildPointsContent,
    required this.buildForgotPasswordContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedMainSection == MainSection.profile) {
      switch (selectedProfileSection) {
        case ProfileSection.personalInfo:
          return buildPersonalInfoForm();
        case ProfileSection.forgotPassword:
          return buildForgotPasswordContent();
        case ProfileSection.changePassword:
          return buildChangePasswordContent();
        case ProfileSection.addresses:
          return buildAddressManagement();
      }
    } else if (selectedMainSection == MainSection.orders) {
      return buildOrdersContent();
    } else if (selectedMainSection == MainSection.points) {
      return buildPointsContent();
    }

    // Default fallback
    return buildPersonalInfoForm();
  }
}
