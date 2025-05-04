import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:flutter/material.dart';

class ChangePasswordContent extends StatefulWidget {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final Function(String) onCurrentPasswordChanged;
  final Function(String) onNewPasswordChanged;
  final Function(String) onConfirmPasswordChanged;
  final VoidCallback onToggleCurrentPasswordVisibility;
  final VoidCallback onToggleNewPasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  const ChangePasswordContent({
    Key? key,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrentPassword,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.onCurrentPasswordChanged,
    required this.onNewPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onToggleCurrentPasswordVisibility,
    required this.onToggleNewPasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  }) : super(key: key);

  @override
  State<ChangePasswordContent> createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<ChangePasswordContent> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Đổi mật khẩu",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Để bảo mật tài khoản, vui lòng không chia sẻ mật khẩu cho người khác",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordField(
                  "Mật khẩu hiện tại",
                  widget.currentPasswordController,
                  widget.onCurrentPasswordChanged,
                  widget.obscureCurrentPassword,
                  widget.onToggleCurrentPasswordVisibility,
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  "Mật khẩu mới",
                  widget.newPasswordController,
                  widget.onNewPasswordChanged,
                  widget.obscureNewPassword,
                  widget.onToggleNewPasswordVisibility,
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  "Xác nhận mật khẩu mới",
                  widget.confirmPasswordController,
                  widget.onConfirmPasswordChanged,
                  widget.obscureConfirmPassword,
                  widget.onToggleConfirmPasswordVisibility,
                  validator: (value) {
                    if (value != widget.newPassword) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đang xử lý..."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final userService = UserService();
                      // userService.testRegistration();
                      // // Login to get token - use your test account
                      // final loginResult =
                      //     await userService.loginUser("ha@gmail.com", "123456");

                      // if (loginResult == null) {
                      //   throw Exception("Đăng nhập thất bại");
                      // }

                      // Change password with the authenticated session
                      bool changeSuccess =
                          await userService.changeCurrentUserPassword(
                        widget.currentPasswordController.text,
                        widget.newPasswordController.text,
                      );

                      // Show result based on API response
                      if (changeSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Mật khẩu đã được đổi thành công"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Không thể đổi mật khẩu. Vui lòng thử lại."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Xác nhận thay đổi"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    bool obscureText,
    VoidCallback toggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
      ),
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập $label';
            } else if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
    );
  }
}
