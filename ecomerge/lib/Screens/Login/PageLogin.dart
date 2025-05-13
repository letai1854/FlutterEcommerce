// lib/pages/page_login.dart
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/login_form.dart'; // Đảm bảo import đúng
import 'package:e_commerce_app/widgets/navbar.dart';
import 'package:e_commerce_app/database/services/user_service.dart'; // Import UserService
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Bỏ các import Provider
// import 'package:provider/provider.dart';
// import 'package:e_commerce_app/Provider/UserProvider.dart'; // Assuming this was related to Provider
// import 'package:e_commerce_app/providers/login_form_provider.dart'; // Assuming this was related to Provider

class Pagelogin extends StatefulWidget {
  const Pagelogin({super.key});

  @override
  State<Pagelogin> createState() => _PageloginState();
}

class _PageloginState extends State<Pagelogin> {
  // === State Variables Managed by _PageloginState ===

  // Focus Nodes (managed here)
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // API Service (managed here)
  final UserService _userService = UserService(); // Create UserService instance

  // Form Controllers (managed here)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // UI State (managed here)
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  // === Lifecycle Methods ===

  @override
  void initState() {
    super.initState();
    // Có thể không cần logic initState đặc biệt ở đây sau khi bỏ Provider
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes managed by THIS state
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // Nếu UserService cần dispose, gọi ở đây (_userService.dispose() nếu tồn tại)

    super.dispose();
  }

  // Bỏ hàm deactivate nếu không còn logic reset form Provider đặc biệt
  // @override
  // void deactivate() {
  //   super.deactivate();
  // }

  // === Helper Methods & Handlers ===

  // Common text change handler (clears error when any text field changes)
  void _onTextChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // Toggle password visibility (updates local state and rebuilds)
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  // Signup handler (uses local state, calls API, updates state, navigates)
  // Hàm này giờ không nhận provider nữa, nó dùng state/controllers/service của chính _PageloginState
// lib/pages/page_login.dart
// ... (các import và state variables như trước)

  Future<void> _handleLogin() async {
    // Validate fields (using local controllers)
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin';
      });
      _emailFocusNode.requestFocus(); // Focus vào trường đầu tiên bị trống
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error on new attempt
    });

    // Biến để lưu kết quả bool từ UserService
    bool loginSuccess = false; // Giả định ban đầu là thất bại

    try {
      // Call login method. UserService.loginUser trả về true khi thành công (status 200),
      // và false khi thất bại (status khác 200 hoặc lỗi mạng).
      loginSuccess = await _userService.loginUser(
        _emailController.text,
        _passwordController.text,
      );

      // Check mounted trước khi tương tác với context sau await
      if (mounted) {
        if (loginSuccess) {
          // Đăng nhập thành công (UserService trả về true)
          // UserInfo singleton đã được cập nhật trong UserService
          // Điều hướng đến trang home và xóa các route trước đó
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        } else {
          // Đăng nhập thất bại (UserService trả về false)
          // Điều này có thể do lỗi API (email/mật khẩu sai, tài khoản chưa kích hoạt...)
          // hoặc lỗi mạng (tùy cách UserService xử lý catch).
          // Với UserService trả về false cho mọi thất bại, chỉ hiển thị thông báo chung.
          setState(() {
            // Hiển thị thông báo lỗi chung
            _errorMessage =
                'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin hoặc kết nối mạng.';
          });
          // Focus vào trường email hoặc mật khẩu khi thất bại
          _emailFocusNode
              .requestFocus(); // Hoặc _passwordFocusNode.requestFocus();
        }
      }
    }
    // Bắt các Exception khác mà UserService có thể ném ra (nếu có logic khác)
    // Tuy nhiên, với code UserService bạn cung cấp, catch block này có thể ít khi được chạy
    // vì UserService đã bắt lỗi trong hàm của nó và trả về false.
    on Exception catch (e) {
      if (mounted) {
        String errorMsg = 'Đã xảy ra lỗi không xác định: ${e.toString()}';
        if (e.toString().contains('Exception: ')) {
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }
        setState(() {
          _errorMessage =
              'Lỗi: $errorMsg'; // Hiển thị thông báo lỗi từ exception
        });
        _emailFocusNode
            .requestFocus(); // Focus vào trường email hoặc mật khẩu khi có lỗi
      }
    } finally {
      // Luôn đặt trạng thái loading về false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === Build Method ===

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Tạo widget LoginForm một lần duy nhất và truyền các dependency vào constructor
        Widget loginFormWidget = LoginForm(
          // Controllers
          emailController: _emailController,
          passwordController: _passwordController,
          // FocusNodes
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          // State variables
          isLoading: _isLoading, // Truyền state isLoading
          errorMessage: _errorMessage, // Truyền state errorMessage
          isPasswordVisible: _isPasswordVisible, // Truyền state visibility
          // Callbacks/Functions
          onLoginPressed: _handleLogin, // Truyền hàm xử lý login
          togglePasswordVisibility:
              _togglePasswordVisibility, // Truyền hàm toggle visibility
          onTextChanged: _onTextChanged, // Truyền hàm xử lý text change
        );

        // --- Layout Logic based on screenWidth ---
        if (screenWidth < 768) {
          return Scaffold(
            body: Stack(
              children: [
                // Background gradient covering entire screen
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 234, 29, 7),
                        Color.fromARGB(255, 255, 85, 0),
                      ],
                    ),
                  ),
                ),
                // Content
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Logo section with white background
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logoSNew.png', // Đảm bảo đường dẫn đúng
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Shopii',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 255, 85, 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Login form section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 30.0),
                        child: Container(
                          color: Colors.white.withOpacity(0.9),
                          child: loginFormWidget, // Sử dụng widget đã tạo
                        ),
                      ),
                      if (kIsWeb) const Footer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (screenWidth < 1100) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 234, 29, 7),
            appBar: const PreferredSize(
              // Sử dụng const
              preferredSize: Size.fromHeight(80),
              child: Navbar(),
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  // Loại bỏ LayoutBuilder không cần thiết ở đây
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth > 600 ? 400 : double.infinity,
                        ),
                        child: loginFormWidget, // Sử dụng widget đã tạo
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (kIsWeb) const Footer(),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Desktop layout
          return Scaffold(
            // AppBar không cần PreferredSize nếu đặt trong Column và Row
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const Navbar(), // Sử dụng const
                  SizedBox(
                    // Bọc phần body còn lại trong SizedBox để đảm bảo chiều cao
                    height: MediaQuery.of(context).size.height -
                        80, // Trừ chiều cao navbar
                    child: Container(
                      decoration: const BoxDecoration(
                        // Sử dụng const
                        color: Color.fromARGB(255, 234, 29, 7),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                // Sử dụng const
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/banner.jpg'), // Đảm bảo đường dẫn đúng
                                  fit: BoxFit.cover, // Thêm fit
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 400, // Có thể điều chỉnh width
                                constraints: const BoxConstraints(
                                  // Sử dụng const
                                  maxHeight:
                                      400, // Có thể điều chỉnh max/minHeight
                                  minHeight: 350,
                                ),
                                child: loginFormWidget, // Sử dụng widget đã tạo
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kIsWeb)
                    const Column(
                      // Sử dụng const
                      children: [
                        Footer(),
                      ],
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
//commit
