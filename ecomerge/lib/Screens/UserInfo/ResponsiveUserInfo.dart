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
import 'dart:developer' as developer;

class ResponsiveUserInfo extends StatefulWidget {
  const ResponsiveUserInfo({super.key});

  @override
  State<ResponsiveUserInfo> createState() => _ResponsiveUserInfoState();
}

class _ResponsiveUserInfoState extends State<ResponsiveUserInfo>
    with WidgetsBindingObserver {
  // Navigation state variables
  MainSection _selectedMainSection = MainSection.profile;
  ProfileSection _selectedProfileSection = ProfileSection.personalInfo;
  bool _isProfileExpanded = true;
  int _selectedOrderTab = 0;
  int _selectedOrderStatus = 0;

  // Form state for PersonalInfoForm - with initial values and saved state
  String _name = "user  ";
  String _email = "example@gmail.com";
  String _phone = "0123456789";
  String _gender = "male";
  String _birthDate = "01/01/1990";

  // Saved state to track last saved values
  String _savedName = "user";
  String _savedEmail = "example@gmail.com";
  String _savedPhone = "0123456789";
  String _savedGender = "male";
  String _savedBirthDate = "01/01/1990";

  // Form state for ChangePasswordContent
  String _currentPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";

  // Form controllers to maintain cursor position
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State management for form visibility options
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Keys for preserving state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _personalInfoKey = GlobalKey();
  final GlobalKey _changePasswordKey = GlobalKey();
  final Key _baseKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers with values
    _nameController.text = _name;
    _emailController.text = _email;
    _phoneController.text = _phone;
    _currentPasswordController.text = _currentPassword;
    _newPasswordController.text = _newPassword;
    _confirmPasswordController.text = _confirmPassword;

    // Add listeners to track text changes
    _nameController.addListener(() {
      if (_name != _nameController.text) {
        setState(() {
          _name = _nameController.text;
        });
      }
    });

    _emailController.addListener(() {
      if (_email != _emailController.text) {
        setState(() {
          _email = _emailController.text;
        });
      }
    });

    _phoneController.addListener(() {
      if (_phone != _phoneController.text) {
        setState(() {
          _phone = _phoneController.text;
        });
      }
    });

    _currentPasswordController.addListener(() {
      if (_currentPassword != _currentPasswordController.text) {
        setState(() {
          _currentPassword = _currentPasswordController.text;
        });
      }
    });

    _newPasswordController.addListener(() {
      if (_newPassword != _newPasswordController.text) {
        setState(() {
          _newPassword = _newPasswordController.text;
        });
      }
    });

    _confirmPasswordController.addListener(() {
      if (_confirmPassword != _confirmPasswordController.text) {
        setState(() {
          _confirmPassword = _confirmPasswordController.text;
        });
      }
    });

    developer.log(
        'ResponsiveUserInfo initialized with name: $_name, email: $_email',
        name: 'UserInfo');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Listen to layout changes
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    developer.log(
        'Screen metrics changed - current form data: name=$_name, email=$_email',
        name: 'UserInfo');
    if (mounted) setState(() {});
  }

  // Navigation handlers
  void _resetPersonalInfoToSaved() {
    setState(() {
      _name = _savedName;
      _email = _savedEmail;
      _phone = _savedPhone;
      _gender = _savedGender;
      _birthDate = _savedBirthDate;

      _nameController.text = _savedName;
      _emailController.text = _savedEmail;
      _phoneController.text = _savedPhone;
    });
  }

  void _clearPasswordFields() {
    setState(() {
      _currentPassword = "";
      _newPassword = "";
      _confirmPassword = "";
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _handleMainSectionChanged(MainSection section) {
    setState(() {
      if (_selectedMainSection == MainSection.profile) {
        // Clear forms when leaving profile section
        _clearPasswordFields();
        _resetPersonalInfoToSaved();
      }
      _selectedMainSection = section;
    });
  }

  void _handleProfileSectionChanged(ProfileSection section) {
    setState(() {
      if (_selectedProfileSection == ProfileSection.changePassword &&
          section != ProfileSection.changePassword) {
        // Clear password fields when leaving password section
        _clearPasswordFields();
      }

      if (_selectedProfileSection == ProfileSection.personalInfo &&
          section != ProfileSection.personalInfo) {
        // Reset personal info when leaving without saving
        _resetPersonalInfoToSaved();
      }

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

  // PersonalInfoForm handlers
  void _handleNameChanged(String value) {
    developer.log('Name changed to: $value', name: 'UserInfo');
    if (_name != value) {
      setState(() {
        _name = value;
        _nameController.text = value;
      });
    }
  }

  void _handleEmailChanged(String value) {
    developer.log('Email changed to: $value', name: 'UserInfo');
    if (_email != value) {
      setState(() {
        _email = value;
        _emailController.text = value;
      });
    }
  }

  void _handlePhoneChanged(String value) {
    developer.log('Phone changed to: $value', name: 'UserInfo');
    if (_phone != value) {
      setState(() {
        _phone = value;
        _phoneController.text = value;
      });
    }
  }

  void _savePersonalInfo() {
    setState(() {
      _savedName = _name;
      _savedEmail = _email;
      _savedPhone = _phone;
      _savedGender = _gender;
      _savedBirthDate = _birthDate;
    });
  }

  void _handleGenderChanged(String value) {
    developer.log('Gender changed to: $value', name: 'UserInfo');
    setState(() {
      _gender = value;
    });
  }

  void _handleBirthDateChanged(String value) {
    developer.log('Birth date changed to: $value', name: 'UserInfo');
    setState(() {
      _birthDate = value;
    });
  }

  // ChangePasswordContent handlers
  void _handleCurrentPasswordChanged(String value) {
    developer.log('Current password changed', name: 'UserInfo');
    if (_currentPassword != value) {
      setState(() {
        _currentPassword = value;
        _currentPasswordController.text = value;
      });
    }
  }

  void _handleNewPasswordChanged(String value) {
    developer.log('New password changed', name: 'UserInfo');
    if (_newPassword != value) {
      setState(() {
        _newPassword = value;
        _newPasswordController.text = value;
      });
    }
  }

  void _handleConfirmPasswordChanged(String value) {
    developer.log('Confirm password changed', name: 'UserInfo');
    if (_confirmPassword != value) {
      setState(() {
        _confirmPassword = value;
        _confirmPasswordController.text = value;
      });
    }
  }

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // Content building functions with proper state management
  Widget buildPersonalInfoForm() {
    developer.log('Building PersonalInfoForm with name: $_name, email: $_email',
        name: 'UserInfo');
    return PersonalInfoForm(
      key: _personalInfoKey,
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
      onSave: _savePersonalInfo,
    );
  }

  Widget buildChangePasswordContent() {
    developer.log('Building ChangePasswordContent', name: 'UserInfo');
    return ChangePasswordContent(
      key: _changePasswordKey,
      currentPassword: _currentPassword,
      newPassword: _newPassword,
      confirmPassword: _confirmPassword,
      currentPasswordController: _currentPasswordController,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
      obscureCurrentPassword: _obscureCurrentPassword,
      obscureNewPassword: _obscureNewPassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      onCurrentPasswordChanged: _handleCurrentPasswordChanged,
      onNewPasswordChanged: _handleNewPasswordChanged,
      onConfirmPasswordChanged: _handleConfirmPasswordChanged,
      onToggleCurrentPasswordVisibility: _toggleCurrentPasswordVisibility,
      onToggleNewPasswordVisibility: _toggleNewPasswordVisibility,
      onToggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
    );
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
    developer.log(
        'Building ResponsiveUserInfo layout with name: $_name, email: $_email',
        name: 'UserInfo');

    // Check if we're on an actual mobile device (not just small screen)
    final bool isRealMobileDevice = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    // If on real mobile device, use mobile layout regardless of screen size
    if (isRealMobileDevice) {
      return const UserInfoMobile();
    }

    // For web or desktop, use responsive layouts based on screen size and wrap with Form
    return Form(
      key: _formKey,
      child: RepaintBoundary(
        child: ResponsiveLayout(
          key: _baseKey,
          mobileScaffold: _buildScaffold(isMobile: true),
          tableScaffold: _buildScaffold(isTablet: true),
          destopScaffold: _buildScaffold(isDesktop: true),
        ),
      ),
    );
  }

  // Create unified scaffold builder to ensure consistent props
  Widget _buildScaffold(
      {bool isMobile = false, bool isTablet = false, bool isDesktop = false}) {
    return isDesktop
        ? UserInfoDesktop(
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
          )
        : UserInfoTablet(
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
          );
  }
}
