// lib/widgets/login_form.dart
import 'package:flutter/material.dart';
// Không cần import Provider hay LoginFormProvider nữa
// import 'package:provider/provider.dart';
// import 'package:e_commerce_app/providers/login_form_provider.dart';
// Import UserService nếu nó cần thiết cho logic điều hướng (forgot password, signup)
// import '../database/services/user_service.dart'; // Chỉ cần nếu logic login ở đây

class LoginForm extends StatefulWidget {
  // Định nghĩa constructor mới nhận tất cả dependency
  const LoginForm({
    Key? key,
    // Controllers
    required this.emailController,
    required this.passwordController,
    // FocusNodes
    required this.emailFocusNode,
    required this.passwordFocusNode,
    // State variables
    required this.isLoading,
    required this.errorMessage,
    required this.isPasswordVisible,
    // Callbacks/Functions
    required this.onLoginPressed,         // Hàm xử lý khi nhấn nút đăng nhập
    required this.togglePasswordVisibility, // Hàm xử lý ẩn/hiện mật khẩu
    required this.onTextChanged,          // Hàm xử lý khi text thay đổi (để clear lỗi)
  }) : super(key: key);

  // Khai báo các biến final để lưu giá trị truyền vào
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordVisible;
  final VoidCallback onLoginPressed;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback onTextChanged; // Callback chung khi text thay đổi

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Không cần khai báo FocusNode, Controller, hoặc State variables ở đây nữa
  // Chúng ta sẽ truy cập chúng qua widget.propertyName

  @override
  Widget build(BuildContext context) {
    // Không dùng Provider nữa

    return Container(
      width: 400, // Đảm bảo kích thước hợp lý
      padding: const EdgeInsets.all(20), // Sử dụng const
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      // Bọc nội dung bằng SingleChildScrollView nếu cần tránh overflow
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Giúp column chỉ chiếm không gian cần thiết
          children: [
            const Text( // Sử dụng const
              'Đăng nhập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Sử dụng const
            TextFormField(
              // Sử dụng FocusNode và Controller được truyền vào qua widget
              focusNode: widget.emailFocusNode,
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                // Yêu cầu focus node tiếp theo (được truyền vào)
                FocusScope.of(context).requestFocus(widget.passwordFocusNode);
              },
              onChanged: (value) {
                // Gọi hàm callback được truyền vào khi text thay đổi
                widget.onTextChanged();
              },
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey[600],
                ),
                border: OutlineInputBorder( // Sử dụng const cho BorderSide nếu có thể
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                 focusedBorder: const OutlineInputBorder( // Sử dụng const
                   borderSide: BorderSide(color: Color.fromARGB(255, 255, 85, 0)),
                 ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
            TextFormField(
              focusNode: widget.passwordFocusNode,
              controller: widget.passwordController,
              obscureText: !widget.isPasswordVisible, // Sử dụng state visibility được truyền vào
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                 // Gọi hàm callback được truyền vào khi text thay đổi
                widget.onTextChanged();
              },
              // Khi hoàn thành field cuối cùng, có thể gọi hàm đăng nhập
               onFieldSubmitted: (_) {
                 if (!widget.isLoading) { // Kiểm tra isLoading được truyền vào
                   widget.onLoginPressed(); // Gọi hàm đăng nhập được truyền vào
                 }
               },
              decoration: InputDecoration(
                hintText: 'Mật khẩu',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey[600],
                ),
                 // Gọi hàm toggle visibility được truyền vào
                suffixIcon: IconButton(
                  icon: Icon(
                    widget.isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: widget.togglePasswordVisibility,
                ),
                border: OutlineInputBorder( // Sử dụng const cho BorderSide nếu có thể
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                 focusedBorder: const OutlineInputBorder( // Sử dụng const
                   borderSide: BorderSide(color: Color.fromARGB(255, 255, 85, 0)),
                 ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Sử dụng const
              ),
            ),
            const SizedBox(height: 16), // Sử dụng const
            // Hiển thị lỗi được truyền vào
            if (widget.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  widget.errorMessage!,
                  style: const TextStyle(color: Colors.red), // Sử dụng const
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18), // Sử dụng const
                  backgroundColor: const Color.fromARGB(255, 234, 29, 7), // Sử dụng const
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                 // Nút bị disable nếu isLoading là true (state được truyền vào)
                onPressed: widget.isLoading ? null : widget.onLoginPressed, // Gọi hàm login được truyền vào
                child: widget.isLoading // Sử dụng state isLoading được truyền vào
                    ? const SizedBox( // Sử dụng const
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text( // Sử dụng const
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12), // Sử dụng const
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  // Điều hướng vẫn dùng context từ widget
                  Navigator.pushNamed(context, '/forgot_password');
                },
                child: Text(
                  'Quên mật khẩu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Sử dụng const
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Bạn mới biết đến Shopi? '), // Sử dụng const
                TextButton(
                  onPressed: () {
                     // Điều hướng vẫn dùng context từ widget
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text( // Sử dụng const
                    'Đăng ký',
                    style: TextStyle(
                      color: Color.fromARGB(255, 234, 29, 7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//commit
