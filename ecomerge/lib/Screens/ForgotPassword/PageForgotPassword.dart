// --- GIỮ NGUYÊN CÁC IMPORT GỐC CỦA BẠN ---
import 'package:e_commerce_app/Screens/ForgotPassword/navbarforgotpassword.dart';
import 'package:e_commerce_app/widgets/ForgotPassword/bodyForgotPassword.dart';
// import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart'; // Bỏ import này
// import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart'; // Bỏ import này
import 'package:e_commerce_app/widgets/navbar.dart'; // --- SỬ DỤNG NAVBAR NÀY ---
// import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart'; // Bỏ import này
import 'package:flutter/material.dart';

class Pageforgotpassword extends StatefulWidget {
  const Pageforgotpassword({super.key});

  @override
  State<Pageforgotpassword> createState() => _PageforgotpasswordState();
}

class _PageforgotpasswordState extends State<Pageforgotpassword> {
  // --- STATE VÀ CONTROLLERS ĐƯỢC QUẢN LÝ Ở ĐÂY ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isEmailVerified = false;
  bool _isVerifying = false;
  // bool _obscurePassword = true; // State này chuyển vào bodyForgotPassword
  // bool _obscureConfirmPassword = true; // State này chuyển vào bodyForgotPassword

  // --- HÀM DISPOSE ---
  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- CÁC HÀM XỬ LÝ LOGIC ---
  Future<void> _verifyEmail() async {
    // --- Giữ nguyên logic hàm _verifyEmail gốc của bạn ---
    // (Validate email trước nếu muốn)
    // if (!_formKey.currentState!.validate()) return; // Cần key riêng cho email step?

    setState(() { _isVerifying = true; });
    print('Verifying email: ${_emailController.text}');
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;
    setState(() { _isVerifying = false; _isEmailVerified = true; });

    if (mounted) { // Kiểm tra mounted trước khi dùng context
       ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Mã xác thực đã gửi đến email của bạn'), backgroundColor: Colors.green, ), );
    }
  }

  void _continueToPasswordReset() {
    // --- Giữ nguyên logic hàm _continueToPasswordReset gốc của bạn ---
    // Validate form (chứa cả email và code ở bước này)
    if (_formKey.currentState!.validate()) {
      print('Verification code submitted: ${_codeController.text}');
      // TODO: Check code validity
      setState(() { _currentStep = 1; });
    }
    // Validation errors hiển thị tự động
  }


  void _resetPassword() {
    // --- Giữ nguyên logic hàm _resetPassword gốc của bạn ---
    if (_formKey.currentState!.validate()) {
      print('Resetting password...');
      // TODO: Call API to reset password

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Đổi mật khẩu thành công'), backgroundColor: Colors.green, ), );
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) { Navigator.pushReplacementNamed(context, '/login'); }
        });
      }
    }
  }

  // --- HÀM QUAY LẠI BƯỚC TRƯỚC ---
  void _goBackToVerificationStep() {
    setState(() {
       _currentStep = 0;
       // Giữ lại email, xóa code và password
       _codeController.clear();
       _newPasswordController.clear();
       _confirmPasswordController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    // --- KHÔNG CẦN KHAI BÁO LẠI CONTROLLER/STATE/HÀM Ở ĐÂY ---

    return LayoutBuilder(
      builder: (context, constraints) {
        // final screenWidth = constraints.maxWidth; // Không cần dùng screenWidth nữa

        // --- LUÔN SỬ DỤNG NAVBAR() ---
        // Navbar() đã implement PreferredSizeWidget nên có thể dùng trực tiếp
        PreferredSizeWidget appBar =  NavbarForgotPassword();

        // --- KHỞI TẠO BODY VÀ TRUYỀN PROPS ---
        Widget body = bodyForgotPassword(
          emailController: _emailController,
          codeController: _codeController,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          formKey: _formKey,
          currentStep: _currentStep,
          isEmailVerified: _isEmailVerified,
          isVerifying: _isVerifying,
          verifyEmail: _verifyEmail, // Truyền hàm
          continueToPasswordReset: _continueToPasswordReset, // Truyền hàm
          resetPassword: _resetPassword, // Truyền hàm
          goBackToVerificationStep: _goBackToVerificationStep, // Truyền hàm
          // Không cần truyền các state/hàm của obscure nữa
        );

        // --- TRẢ VỀ SCAFFOLD DUY NHẤT ---
        // Không cần if/else cho các layout khác nhau vì dùng cùng AppBar và Body
        return Scaffold(
          appBar: appBar, // Sử dụng Navbar() đã khởi tạo
          body: body,     // Sử dụng bodyForgotPassword đã khởi tạo
        );
      },
    );
  }
}
