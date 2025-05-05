import 'package:flutter/material.dart';
import 'package:e_commerce_app/Screens/UserInfo/MobilePersonalInfoScreen.dart';
import 'package:e_commerce_app/Screens/UserInfo/MobilePasswordChangeScreen.dart';
import 'package:e_commerce_app/widgets/Address/AddressManagement.dart';

class UserFeatureButtons extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String birthDate;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Function(String) onNameChanged;
  final Function(String) onEmailChanged;
  final Function(String) onPhoneChanged;
  final Function(String) onGenderChanged;
  final Function(String) onBirthDateChanged;

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final Function(String) onCurrentPasswordChanged;
  final Function(String) onNewPasswordChanged;
  final Function(String) onConfirmPasswordChanged;
  final Function(String, String, String) onPasswordSave;

  const UserFeatureButtons({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthDate,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onGenderChanged,
    required this.onBirthDateChanged,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onCurrentPasswordChanged,
    required this.onNewPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onPasswordSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tài khoản của tôi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Feature buttons with icons in a grid
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureButton(
                  "Thông tin cá nhân",
                  Icons.person,
                  () => _navigateToPersonalInfo(context),
                  context,
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Đổi mật khẩu",
                  Icons.lock,
                  () => _navigateToPasswordChange(context),
                  context,
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Địa chỉ giao hàng",
                  Icons.location_on,
                  () => _navigateToAddressManagement(context),
                  context,
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Admin",
                  Icons.admin_panel_settings,
                  () => Navigator.pushNamed(context, '/admin'),
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual feature button
  Widget _buildFeatureButton(
    String title,
    IconData icon,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _navigateToPersonalInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobilePersonalInfoScreen(
          initialName: name,
          initialEmail: email,
          initialPhone: phone,
          initialGender: gender,
          initialBirthDate: birthDate,
          onSave: (name, email, phone, gender, birthDate) {
            onNameChanged(name);
            onEmailChanged(email);
            onPhoneChanged(phone);
            onGenderChanged(gender);
            onBirthDateChanged(birthDate);
          },
        ),
      ),
    );
  }

  void _navigateToPasswordChange(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobilePasswordChangeScreen(
          onSave: onPasswordSave,
        ),
      ),
    );
  }

  void _navigateToAddressManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Tài khoản", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            elevation: 0,
          ),
          body: const AddressManagement(),
        ),
      ),
    );
  }
}
