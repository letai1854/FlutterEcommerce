import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  bool _isProcessing = false;

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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    } else if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                    }
                    return null;
                  },
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
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            // Check if user is logged in
                            if (UserInfo().currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Bạn cần đăng nhập để đổi mật khẩu"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isProcessing = true;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đang xử lý..."),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            final userService = UserService();

                            // Call API to change password
                            bool changeSuccess =
                                await userService.changeCurrentUserPassword(
                              widget.currentPasswordController.text,
                              widget.newPasswordController.text,
                            );

                            setState(() {
                              _isProcessing = false;
                            });

                            // Show result based on API response
                            if (changeSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Mật khẩu đã được đổi thành công"),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Clear form fields after successful change
                              widget.currentPasswordController.clear();
                              widget.newPasswordController.clear();
                              widget.confirmPasswordController.clear();

                              // Return to the previous screen if on mobile
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Không thể đổi mật khẩu. Mật khẩu hiện tại không đúng."),
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
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("Xác nhận thay đổi"),
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
            } else if (value.length < 8) {
              return 'Mật khẩu phải có ít nhất 8 ký tự';
            }
            return null;
          },
    );
  }
}
