// lib/widgets/signup_form.dart
// Bỏ các import liên quan đến Provider nếu không còn dùng nữa

import 'package:flutter/material.dart';
import 'location_selection.dart'; // Đảm bảo import đúng đường dẫn

// Định nghĩa các kiểu hàm (typedef) để code rõ ràng hơn
// Callback cho locationSelected vẫn nhận TÊN tỉnh, huyện, xã
typedef LocationSelectedCallback = void Function(String provinceName, String districtName, String wardName);
// Không cần callback cho signup nữa, vì nút signup sẽ gọi trực tiếp hàm được truyền vào

class SignForm extends StatefulWidget {
  // Thêm các tham số required vào constructor. Đảm bảo tên khớp.
  const SignForm({
    Key? key,
    // Controllers
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.addressController,
    required this.rePasswordController,
    // FocusNodes
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.nameFocusNode,
    required this.addressFocusNode,
    required this.rePasswordFocusNode,
    // State variables (Initial values for LocationSelection - DÙNG TÊN MỚI)
    required this.isLoading, // Đảm bảo tham số này tồn tại
    required this.errorMessage, // Đảm bảo tham số này tồn tại
    required this.isPasswordVisible, // Đảm bảo tham số này tồn tại
    required this.isRePasswordVisible, // Đảm bảo tham số này tồn tại
    required this.initialProvinceName, // Đổi tên tham số
    required this.initialDistrictName, // Đổi tên tham số
    required this.initialWardName,     // Đổi tên tham số
    // Callbacks/Functions
    required this.onLocationSelected, // Hàm xử lý chọn địa điểm (mong đợi nhận TÊN)
    required this.onSignup,           // Hàm xử lý đăng ký khi nhấn nút
    required this.togglePasswordVisibility, // Hàm toggle ẩn/hiện mk
    required this.toggleRePasswordVisibility, // Hàm toggle ẩn/hiện nhập lại mk
    required this.onTextChanged, // Hàm xử lý khi text thay đổi (để clear lỗi)
  }) : super(key: key);

  // Khai báo các biến final để lưu giá trị truyền vào. Đảm bảo tên khớp.
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController rePasswordController;

  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode nameFocusNode;
  final FocusNode addressFocusNode;
  final FocusNode rePasswordFocusNode;

  final bool isLoading; // Đảm bảo biến final này tồn tại
  final String? errorMessage; // Đảm bảo biến final này tồn tại
  final bool isPasswordVisible; // Đảm bảo biến final này tồn tại
  final bool isRePasswordVisible; // Đảm bảo biến final này tồn tại


  // Biến lưu trữ initial values cho LocationSelection (DÙNG TÊN MỚI)
  final String initialProvinceName;
  final String initialDistrictName;
  final String initialWardName;

  final LocationSelectedCallback onLocationSelected; // Callback nhận TÊN
  final VoidCallback onSignup;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback toggleRePasswordVisibility;
  final VoidCallback onTextChanged;

  @override
  State<SignForm> createState() => _SignFormState();
}

class _SignFormState extends State<SignForm> {
  // Không cần khai báo FocusNode, Controller, hoặc State variables ở đây nữa
  // Chúng ta sẽ truy cập chúng qua widget.propertyName

  @override
  Widget build(BuildContext context) {
    // Không dùng Provider nữa

    return Container(
      width: 400, // Có thể điều chỉnh kích thước này tùy theo bố cục
      padding: const EdgeInsets.all(20), // Sử dụng const
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      // *** Bọc nội dung bằng SingleChildScrollView ***
      child: SingleChildScrollView( // Thêm SingleChildScrollView ở đây
        child: Column(
          mainAxisSize: MainAxisSize.min, // Giúp column chỉ chiếm không gian cần thiết
          children: [
            const Text( // Sử dụng const
              'Đăng ký',
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
              onChanged: (value) {
                // Gọi hàm callback được truyền vào khi text thay đổi
                widget.onTextChanged();
              },
              onFieldSubmitted: (_) {
                // Yêu cầu focus node tiếp theo (được truyền vào)
                FocusScope.of(context).requestFocus(widget.nameFocusNode);
              },
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey[600],
                ),
                border: const OutlineInputBorder(), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
            TextFormField(
              controller: widget.nameController,
              focusNode: widget.nameFocusNode, // Sử dụng FocusNode được truyền vào
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                widget.onTextChanged();
              },
              onFieldSubmitted: (_) {
                 FocusScope.of(context).requestFocus(widget.addressFocusNode); // Yêu cầu focus node tiếp theo
              },
              decoration: InputDecoration(
                hintText: 'Nhập tên người dùng',
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                ),
                border: const OutlineInputBorder(), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
            // Truyền hàm onLocationSelected và initial values được nhận qua constructor
            LocationSelection(
              onLocationSelected: widget.onLocationSelected, // Truyền callback nhận TÊN
              // TRUYỀN INITIAL NAMES VỚI TÊN THAM SỐ ĐÃ SỬA TRONG LOCATIONSELECTION
              initialProvinceName: widget.initialProvinceName,
              initialDistrictName: widget.initialDistrictName,
              initialWardName: widget.initialWardName,
            ),
            const SizedBox(height: 10), // Sử dụng const
            TextFormField(
              controller: widget.addressController,
              focusNode: widget.addressFocusNode, // Sử dụng FocusNode được truyền vào
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
               onChanged: (value) {
                 widget.onTextChanged();
              },
              onFieldSubmitted: (_) {
                 FocusScope.of(context).requestFocus(widget.passwordFocusNode); // Yêu cầu focus node tiếp theo
              },
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ chi tiết khác',
                prefixIcon: Icon(
                  Icons.location_city,
                  color: Colors.grey[600],
                ),
                border: const OutlineInputBorder(), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
            TextFormField(
              controller: widget.passwordController,
              focusNode: widget.passwordFocusNode, // Sử dụng FocusNode được truyền vào
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              // Sử dụng state visibility được truyền vào
              obscureText: !widget.isPasswordVisible,
               onChanged: (value) {
                 widget.onTextChanged();
              },
              decoration: InputDecoration(
                hintText: 'Mật khẩu',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey[600],
                ),
                // Thêm helper text để chỉ dẫn yêu cầu về mật khẩu
                helperText: 'Mật khẩu phải có ít nhất 8 ký tự',
                helperStyle: TextStyle(
                  color: widget.passwordController.text.isNotEmpty && 
                         widget.passwordController.text.length < 8 ? 
                         Colors.red : Colors.grey[600],
                ),
                // Gọi hàm toggle visibility được truyền vào
                suffixIcon: IconButton(
                  onPressed: widget.togglePasswordVisibility,
                  icon: Icon(
                    widget.isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                ),
                border: const OutlineInputBorder(), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
            TextFormField(
              controller: widget.rePasswordController,
              focusNode: widget.rePasswordFocusNode, // Sử dụng FocusNode được truyền vào
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done, // Hành động cuối cùng
              // Sử dụng state visibility được truyền vào
              obscureText: !widget.isRePasswordVisible,
               onChanged: (value) {
                 widget.onTextChanged();
              },
              // Khi hoàn thành field cuối cùng, có thể gọi hàm đăng ký
               onFieldSubmitted: (_) {
                if (!widget.isLoading) { // Kiểm tra isLoading được truyền vào
                  widget.onSignup(); // Gọi hàm đăng ký được truyền vào
                }
              },
              decoration: InputDecoration(
                hintText: 'Nhập lại Mật khẩu',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey[600],
                ),
                 // Gọi hàm toggle visibility được truyền vào
                suffixIcon: IconButton(
                  onPressed: widget.toggleRePasswordVisibility,
                  icon: Icon(
                    widget.isRePasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                ),
                border: const OutlineInputBorder(), // Sử dụng const
              ),
            ),
            const SizedBox(height: 10), // Sử dụng const
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
                onPressed: widget.isLoading ? null : widget.onSignup,
                child: widget.isLoading // Sử dụng state isLoading được truyền vào
                    ? const SizedBox( // Sử dụng const
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text( // Sử dụng const
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            // Thêm phần "đã có tài khoản"
            const SizedBox(height: 15), // Sử dụng const
            GestureDetector(
              onTap: () {
                // Điều hướng vẫn dùng context từ widget
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text( // Sử dụng const
                'Bạn đã có tài khoản? Đăng nhập ngay!',
                style: TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
