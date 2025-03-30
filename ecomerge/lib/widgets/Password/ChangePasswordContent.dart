// Change Password Content widget
import 'package:e_commerce_app/widgets/Password/PasswordField.dart';
import 'package:flutter/material.dart';

class ChangePasswordContent extends StatefulWidget {
  const ChangePasswordContent({Key? key}) : super(key: key);

  @override
  State<ChangePasswordContent> createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<ChangePasswordContent> {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PasswordField(
                label: "Mật khẩu hiện tại",
                initialValue: "",
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              PasswordField(
                label: "Mật khẩu mới",
                initialValue: "",
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              PasswordField(
                label: "Xác nhận mật khẩu mới",
                initialValue: "",
                onChanged: (value) {},
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Xác nhận thay đổi"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
