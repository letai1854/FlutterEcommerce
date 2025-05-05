// lib/pages/page_forgot_password.dart
import 'package:e_commerce_app/Screens/ForgotPassword/navbarforgotpassword.dart'; // Đảm bảo import đúng
import 'package:e_commerce_app/widgets/ForgotPassword/bodyForgotPassword.dart'; // Đảm bảo import đúng
import 'package:e_commerce_app/database/services/user_service.dart'; // Import UserService
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Bỏ các import Provider
// import 'package:provider/provider.dart';


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
  // Sử dụng một GlobalKey duy nhất cho Form
  final _formKey = GlobalKey<FormState>();

  // Các biến state quản lý trạng thái UI và bước hiện tại
  int _currentStep = 0; // 0: Xác thực Email/OTP, 1: Đặt lại mật khẩu mới
  bool _isEmailVerified = false; // Trạng thái email đã được xác thực mã
  bool _isSendingOtp = false; // Trạng thái loading cho nút xác thực email
  bool _isVerifyingOtp = false; // Trạng thái loading cho nút Tiếp tục (verify OTP)
  bool _isResettingPassword = false; // Trạng thái loading cho nút Lưu thay đổi
  String? _errorMessage; // Thông báo lỗi để hiển thị

  // Service API
  final UserService _userService = UserService();

  // --- HÀM INITSTATE (Không cần gì đặc biệt) ---
  @override
  void initState() {
    super.initState();
  }

  // --- HÀM DISPOSE ---
  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    // UserService thường không cần dispose nếu nó chỉ là lớp service thuần túy
    // Nếu UserService có http.Client riêng cần đóng, bạn có thể cần gọi _userService.dispose()
    super.dispose();
  }

  // --- HÀM DEACTIVATE (Xóa form khi rời khỏi trang) ---
  @override
  void deactivate() {
     // Reset form state khi rời khỏi trang (trừ trường hợp là pop route)
     // Chỉ reset khi không phải pop route, logic này hơi phức tạp nếu dùng Navigator 1.0
     // Cách đơn giản là luôn reset khi deactivate.
     // Để tránh reset khi resize màn hình, bạn có thể cần state theo dõi resize
     // Nhưng trong trường hợp đơn giản, reset khi deactivate là an toàn.
     _resetAllFormState(); // Gọi hàm reset form state và controllers
     super.deactivate();
  }

   // Helper để reset toàn bộ state form
   void _resetAllFormState() {
      if (mounted) { // Chỉ reset nếu widget còn mounted
          setState(() {
             _emailController.clear();
             _codeController.clear();
             _newPasswordController.clear();
             _confirmPasswordController.clear();
             _currentStep = 0;
             _isEmailVerified = false;
             _isSendingOtp = false;
             _isVerifyingOtp = false;
             _isResettingPassword = false;
             _errorMessage = null;
          });
      }
   }


  // --- CÁC HÀM XỬ LÝ LOGIC API ---

  // Hàm xử lý khi nhấn nút "Xác thực Email" (Step 0)
  Future<void> _handleVerifyEmailPressed() async {
     // Validate chỉ email field hoặc toàn bộ form nếu muốn (ví dụ: nếu code field cũng validate)
     if (_formKey.currentState!.validate()) {
          setState(() {
              _isSendingOtp = true; // Bắt đầu loading cho nút này
              _errorMessage = null; // Xóa lỗi cũ
          });

          try {
              // GỌI API YÊU CẦU MÃ OTP
              await _userService.forgotPassword(_emailController.text.trim());

              // Nếu không ném lỗi, API gọi thành công (không chắc email tồn tại, backend trả 200 OK)
              if (mounted) {
                  setState(() {
                      _isEmailVerified = true; // Đánh dấu email đã xử lý (để enable code field)
                      // Không chuyển step ở đây, vẫn ở step 0
                      _errorMessage = 'Nếu email tồn tại, mã xác thực đã được gửi. Vui lòng kiểm tra email của bạn.'; // Thông báo thành công/chung
                  });
                   // Có thể tự động focus vào code field
                   // FocusScope.of(context).requestFocus(_codeFocusNode); // Nếu có focus node cho code
              }

          } on Exception catch (e) {
              // Bắt lỗi API hoặc lỗi mạng từ UserService
              if (mounted) {
                  String errorMsg = e.toString().replaceAll('Exception: ', '');
                  setState(() {
                      _errorMessage = 'Lỗi: $errorMsg'; // Hiển thị lỗi cụ thể từ backend/mạng
                      _isEmailVerified = false; // Nếu lỗi, không coi là đã verified
                  });
                   // Có thể focus lại email field nếu lỗi liên quan đến email
              }
          } finally {
              if (mounted) {
                  setState(() {
                      _isSendingOtp = false; // Kết thúc loading
                  });
              }
          }
     }
  }

  // Hàm xử lý khi nhấn nút "Tiếp tục" (Step 0)
  Future<void> _handleContinuePressed() async {
     // Validate toàn bộ form (email và code)
     if (_formKey.currentState!.validate()) {
          setState(() {
              _isVerifyingOtp = true; // Bắt đầu loading cho nút này
              _errorMessage = null; // Xóa lỗi cũ
          });

          try {
              // GỌI API XÁC THỰC MÃ OTP
              await _userService.verifyOtp(_emailController.text.trim(), _codeController.text.trim());

              // Nếu không ném lỗi, xác thực OTP thành công
              if (mounted) {
                  setState(() {
                      _currentStep = 1; // Chuyển sang bước đặt mật khẩu mới
                      // Clear các trường cũ để không gửi lại trong request cuối
                      // _codeController.clear(); // Không cần clear ở đây, giữ lại để gửi request cuối
                      _errorMessage = null; // Xóa lỗi nếu có ở bước này
                  });
                   // Có thể tự động focus vào new password field
                   // FocusScope.of(context).requestFocus(_newPasswordFocusNode); // Nếu có focus node
              }

          } on Exception catch (e) {
              // Bắt lỗi API hoặc lỗi mạng
              if (mounted) {
                  String errorMsg = e.toString().replaceAll('Exception: ', '');
                  setState(() {
                      _errorMessage = 'Lỗi xác thực: $errorMsg'; // Hiển thị lỗi cụ thể
                      // Không chuyển step, vẫn ở step 0
                  });
                   // Có thể focus lại code field nếu lỗi liên quan đến OTP
              }
          } finally {
              if (mounted) {
                  setState(() {
                      _isVerifyingOtp = false; // Kết thúc loading
                  });
              }
          }
     }
  }

  // Hàm xử lý khi nhấn nút "Lưu thay đổi" (Step 1)
  Future<void> _handleResetPasswordPressed() async {
    // Validate form (mật khẩu mới và xác nhận mật khẩu)
     if (_formKey.currentState!.validate()) {
          setState(() {
              _isResettingPassword = true; // Bắt đầu loading cho nút này
              _errorMessage = null; // Xóa lỗi cũ
          });

          try {
              // GỌI API ĐẶT LẠI MẬT KHẨU MỚI
              await _userService.setNewPassword(
                  _emailController.text.trim(), // Cần gửi lại email
                  _codeController.text.trim(), // Cần gửi lại OTP
                  _newPasswordController.text // Mật khẩu mới
              );

              // Nếu không ném lỗi, đặt lại mật khẩu thành công
              if (mounted) {
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar( // Sử dụng const
                           content: Text('Đổi mật khẩu thành công!'),
                           backgroundColor: Colors.green,
                       ),
                  );
                  // Chờ một chút rồi điều hướng về trang đăng nhập
                  Future.delayed(const Duration(seconds: 1), () { // Sử dụng const
                       if (mounted) {
                           // Reset form state và Controllers trước khi điều hướng
                           _resetAllFormState();
                           // Điều hướng và xóa các route trước đó (đặc biệt là trang quên mật khẩu)
                           Navigator.pushReplacementNamed(context, '/login');
                       }
                   });
              }

          } on Exception catch (e) {
              // Bắt lỗi API hoặc lỗi mạng
              if (mounted) {
                   String errorMsg = e.toString().replaceAll('Exception: ', '');
                   setState(() {
                      _errorMessage = 'Lỗi đổi mật khẩu: $errorMsg'; // Hiển thị lỗi cụ thể
                       // Vẫn ở step 1
                   });
                    // Có thể focus lại field mật khẩu mới nếu lỗi liên quan
               }
          } finally {
              if (mounted) {
                  setState(() {
                      _isResettingPassword = false; // Kết thúc loading
                  });
              }
          }
     }
  }

  // Hàm xử lý khi text trong bất kỳ trường nào thay đổi (để xóa lỗi)
  void _onTextChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }


  // --- HÀM QUAY LẠI BƯỚC TRƯỚC ---
  void _goBackToVerificationStep() {
    setState(() {
       _currentStep = 0;
       // Giữ lại email (nếu cần), xóa code và password mới
       _codeController.clear(); // Xóa mã
       _newPasswordController.clear(); // Xóa mật khẩu mới
       _confirmPasswordController.clear(); // Xóa xác nhận mật khẩu
       _errorMessage = null; // Xóa lỗi
        // Reset trạng thái verified nếu cần, tùy logic backend có yêu cầu verify lại không
        // Nếu backend yêu cầu verify lại OTP mỗi lần thử đổi mật khẩu, thì giữ lại _isEmailVerified=true.
        // Nếu backend yêu cầu verify lại OTP chỉ 1 lần cho mỗi request quên mật khẩu, thì giữ lại _isEmailVerified=true.
        // Nếu bạn muốn người dùng *phải* request OTP mới khi quay lại, set _isEmailVerified = false;
        // Giả định giữ lại trạng thái verified cho OTP hiện tại
    });
  }


  // --- HÀM BUILD ---
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final screenWidth = constraints.maxWidth; // Không cần dùng screenWidth nữa

        // --- LUÔN SỬ DỤNG NAVBAR ĐÚNG ---
        // NavbarForgotPassword() đã implement PreferredSizeWidget nên có thể dùng trực tiếp
        PreferredSizeWidget appBar =  NavbarForgotPassword();

        // --- KHỞI TẠO BODY VÀ TRUYỀN PROPS ---
        Widget body = bodyForgotPassword(
          // Controllers
          emailController: _emailController,
          codeController: _codeController,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          // Form Key
          formKey: _formKey,
          // State Variables
          currentStep: _currentStep,
          isEmailVerified: _isEmailVerified,
          isSendingOtp: _isSendingOtp, // Truyền trạng thái loading
          isVerifyingOtp: _isVerifyingOtp, // Truyền trạng thái loading
          isResettingPassword: _isResettingPassword, // Truyền trạng thái loading
          errorMessage: _errorMessage, // Truyền thông báo lỗi

          // Callbacks (Hàm xử lý)
          onVerifyEmailPressed: _handleVerifyEmailPressed, // Truyền hàm
          onContinuePressed: _handleContinuePressed, // Truyền hàm
          onResetPasswordPressed: _handleResetPasswordPressed, // Truyền hàm
          goBackToVerificationStep: _goBackToVerificationStep, // Truyền hàm
          onTextChanged: _onTextChanged, // Truyền hàm xử lý text change
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
