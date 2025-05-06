import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';

class MobilePasswordChangeScreen extends StatefulWidget {
  final Function(String, String, String) onSave;

  const MobilePasswordChangeScreen({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<MobilePasswordChangeScreen> createState() =>
      _MobilePasswordChangeScreenState();
}

class _MobilePasswordChangeScreenState
    extends State<MobilePasswordChangeScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đổi mật khẩu", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Text(
                  "Để bảo mật tài khoản, vui lòng không chia sẻ mật khẩu cho người khác",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 24),

                // Password fields
                _buildPasswordField(
                  "Mật khẩu hiện tại",
                  _currentPasswordController,
                  _obscureCurrentPassword,
                  () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),

                _buildPasswordField(
                  "Mật khẩu mới",
                  _newPasswordController,
                  _obscureNewPassword,
                  () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    } else if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                _buildPasswordField(
                  "Xác nhận mật khẩu mới",
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                  () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới';
                    } else if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Submit button - full width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: UserInfo().currentUser == null
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave(
                                _currentPasswordController.text,
                                _newPasswordController.text,
                                _confirmPasswordController.text,
                              );
                              final userService = UserService();

                              bool checkChangePass =
                                  await userService.changeCurrentUserPassword(
                                _currentPasswordController.text,
                                _newPasswordController.text,
                              );

                              if (checkChangePass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Mật khẩu đã được đổi thành công"),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      UserInfo().currentUser == null
                          ? "Đăng nhập để tiếp tục"
                          : "Xác nhận thay đổi",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: toggleVisibility,
              ),
            ),
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập $label';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}
