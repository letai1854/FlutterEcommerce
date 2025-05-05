import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';

// Import widget components
import 'package:e_commerce_app/widgets/UserInfo/UserInfoHeader.dart';
import 'package:e_commerce_app/widgets/UserInfo/OrdersSection.dart';
import 'package:e_commerce_app/widgets/UserInfo/UserFeatureButtons.dart';

class UserInfoMobile extends StatefulWidget {
  const UserInfoMobile({super.key});

  @override
  State<UserInfoMobile> createState() => _UserInfoMobileState();
}

class _UserInfoMobileState extends State<UserInfoMobile> {
  // Form state for PersonalInfoForm
  String _name = UserInfo().currentUser?.fullName ?? "";
  String _email = UserInfo().currentUser?.email ?? "";
  String _phone = "0123456789";
  String _gender = "male";
  String _birthDate = "01/01/1990";

  // Form controllers for PersonalInfoForm
  final TextEditingController _nameController =
      TextEditingController(text: UserInfo().currentUser?.fullName ?? "");
  final TextEditingController _emailController =
      TextEditingController(text: UserInfo().currentUser?.email ?? "");
  final TextEditingController _phoneController =
      TextEditingController(text: "0123456789");

  // Form state for ChangePasswordContent
  String _currentPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Form controllers for ChangePasswordContent
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for UserInfo changes and trigger rebuild
    UserInfo().addListener(_onUserInfoChanged);
  }

  @override
  void dispose() {
    UserInfo().removeListener(_onUserInfoChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUserInfoChanged() {
    if (mounted) setState(() {});
  }

  // Handlers for PersonalInfoForm
  void _handleNameChanged(String value) {
    setState(() {
      _name = value;
    });
  }

  void _handleEmailChanged(String value) {
    setState(() {
      _email = value;
    });
  }

  void _handlePhoneChanged(String value) {
    setState(() {
      _phone = value;
    });
  }

  void _handleGenderChanged(String value) {
    setState(() {
      _gender = value;
    });
  }

  void _handleBirthDateChanged(String value) {
    setState(() {
      _birthDate = value;
    });
  }

  // Handlers for ChangePasswordContent
  void _handleCurrentPasswordChanged(String value) {
    setState(() {
      _currentPassword = value;
    });
  }

  void _handleNewPasswordChanged(String value) {
    setState(() {
      _newPassword = value;
    });
  }

  void _handleConfirmPasswordChanged(String value) {
    setState(() {
      _confirmPassword = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header section with user info and action buttons
            const UserInfoHeader(),

            // Divider
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

            // Main content - scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const OrdersSection(),
                    const SizedBox(height: 24),
                    UserFeatureButtons(
                      name: _name,
                      email: _email,
                      phone: _phone,
                      gender: _gender,
                      birthDate: _birthDate,
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      onNameChanged: _handleNameChanged,
                      onEmailChanged: _handleEmailChanged,
                      onPhoneChanged: _handlePhoneChanged,
                      onGenderChanged: _handleGenderChanged,
                      onBirthDateChanged: _handleBirthDateChanged,
                      currentPassword: _currentPassword,
                      newPassword: _newPassword,
                      confirmPassword: _confirmPassword,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                      onCurrentPasswordChanged: _handleCurrentPasswordChanged,
                      onNewPasswordChanged: _handleNewPasswordChanged,
                      onConfirmPasswordChanged: _handleConfirmPasswordChanged,
                      onPasswordSave: (current, newPw, confirm) {
                        setState(() {
                          _currentPassword = current;
                          _newPassword = newPw;
                          _confirmPassword = confirm;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
