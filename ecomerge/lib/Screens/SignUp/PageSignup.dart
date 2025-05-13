// lib/pages/page_signup.dart
import 'package:e_commerce_app/database/services/user_service.dart'; // Import đúng UserService
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbar.dart';
import 'package:e_commerce_app/widgets/signup_form.dart'; // Đảm bảo import đúng
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Bỏ import UserInfo nếu không còn dùng cho đăng ký
// import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // Xóa dòng này
import 'package:e_commerce_app/widgets/SuccessMessage.dart'; // Import SuccessMessage

class PageSignup extends StatefulWidget {
  const PageSignup({super.key});

  @override
  State<PageSignup> createState() => _PageSignupState();
}

class _PageSignupState extends State<PageSignup> {
  // === State Variables Managed by _PageSignupState ===

  // Focus Nodes (managed here)
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _rePasswordFocusNode = FocusNode();

  // API Service (managed here)
  final UserService _userService = UserService(); // Sử dụng UserService

  // Form Controllers (managed here)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // Địa chỉ chi tiết (ví dụ: số nhà, tên đường)
  final TextEditingController _rePasswordController = TextEditingController();

  // Location state (managed here) - Lưu trữ TÊN tỉnh/huyện/xã được chọn
  // Các biến này SẼ chứa TÊN (String) sau khi _handleLocationSelected được gọi với dữ liệu TÊN từ LocationSelection
  String _selectedProvinceName = '';
  String _selectedDistrictName = '';
  String _selectedWardName = '';

  // UI State (managed here)
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  // === Lifecycle Methods ===

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _rePasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _rePasswordFocusNode.dispose();
    super.dispose();
  }

  // === Helper Methods & Handlers ===

  // Location selection handler (RECEIVES NAME STRINGS from LocationSelection, updates local state, and rebuilds)
  // HÀM NÀY MONG ĐỢI NHẬN TÊN (STRING) TỪ LocationSelection
  void _handleLocationSelected(
      String provinceName, String districtName, String wardName) {
    // Hàm này KHÔNG CHUYỂN ĐỔI nữa, nó giả định LocationSelection đã gửi tên đúng
    setState(() {
      _selectedProvinceName = provinceName; // Lưu TÊN tỉnh được truyền vào
      _selectedDistrictName = districtName; // Lưu TÊN huyện được truyền vào
      _selectedWardName = wardName; // Lưu TÊN xã được truyền vào
      _errorMessage = null; // Clear error on location change
    });
  }

  // Helper to get full address string to send to backend
  // Combines detailed address and selected location NAMES (now stored in state variables that should contain NAMEs)
  String _getFullAddressString() {
    final specificAddress = _addressController.text.trim();
    // Nối các biến state đã lưu tên (nếu LocationSelection truyền đúng)
    final locationParts =
        [_selectedWardName, _selectedDistrictName, _selectedProvinceName]
            .where((part) => part.isNotEmpty) // Loại bỏ các chuỗi rỗng
            .join(', '); // Nối các chuỗi không rỗng bằng ", "

    // Combine specific address and location parts
    if (specificAddress.isEmpty) {
      return locationParts;
    } else if (locationParts.isEmpty) {
      // Trường hợp này chỉ xảy ra nếu LocationSelection không hoạt động đúng (ví dụ: không chọn đủ 3 cấp)
      // hoặc validation form bị bỏ qua. Validation phía client đã cố gắng bắt trường hợp này.
      return specificAddress;
    } else {
      // Kết quả mong muốn: "địa chỉ chi tiết, Tên Xã, Tên Huyện, Tên Tỉnh"
      return '$specificAddress, $locationParts';
    }
  }

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

  // Toggle re-password visibility (updates local state and rebuilds)
  void _toggleRePasswordVisibility() {
    setState(() {
      _isRePasswordVisible = !_isRePasswordVisible;
    });
  }

  // Clear form fields and state (updates local state and rebuilds)
  void _clearForm() {
    setState(() {
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _addressController.clear();
      _rePasswordController.clear();
      // Reset location state NAMES
      _selectedProvinceName = '';
      _selectedDistrictName = '';
      _selectedWardName = '';
      _errorMessage = null;
      _isLoading = false; // Reset loading just in case
    });
  }

  // Signup handler (uses local state, calls API, updates state, navigates)
  Future<void> _handleSignup() async {
    // Reset error message before validation
    setState(() {
      _errorMessage = null;
    });

    // Validate fields (using local controllers and state)
    // Validate specific address and check if location NAMES are populated (means something was selected)
    if (_emailController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _rePasswordController.text.isEmpty ||
        _addressController.text.trim().isEmpty || // Specific address validation
        _selectedProvinceName
            .isEmpty || // Location validation (check if NAME is empty)
        _selectedDistrictName.isEmpty ||
        _selectedWardName.isEmpty) {
      setState(() {
        _errorMessage =
            'Vui lòng điền đầy đủ thông tin, bao gồm cả địa chỉ chi tiết và khu vực (Tỉnh/Thành phố, Quận/Huyện, Phường/Xã).';
      });
      // Consider focusing the first empty field for better UX
      if (_emailController.text.trim().isEmpty)
        _emailFocusNode.requestFocus();
      else if (_nameController.text.trim().isEmpty)
        _nameFocusNode.requestFocus();
      else if (_addressController.text.trim().isEmpty)
        _addressFocusNode.requestFocus();
      // Cannot easily focus LocationSelection, but _addressFocusNode is related
      else if (_passwordController.text.isEmpty)
        _passwordFocusNode.requestFocus();
      else if (_rePasswordController.text.isEmpty)
        _rePasswordFocusNode.requestFocus();

      return;
    }

    // Validate passwords match (using local controllers)
    if (_passwordController.text != _rePasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu không trùng khớp';
      });
      _rePasswordFocusNode
          .requestFocus(); // Focus re-password field on mismatch
      return;
    }

    // Optional: Validate password complexity (add your logic here if needed)

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors on new attempt
    });

    bool? success; // Sử dụng biến success để lưu kết quả từ UserService (bool?)

    try {
      success = await _userService.registerUser(
        email: _emailController.text.trim(), // Trim whitespace
        fullName: _nameController.text.trim(), // Trim whitespace
        password: _passwordController.text, // Don't trim password
        address:
            _getFullAddressString(), // Pass the combined address string with NAMES
      );

      // Check mounted before interacting with context after await
      if (mounted) {
        if (success == true) {
          // Registration successful
          _clearForm(); // Call helper to clear

          // Show success message and navigate
          SuccessMessage.show(
            context,
            title: 'Đăng ký thành công!',
            duration: const Duration(seconds: 2),
            onDismissed: () {
              // Navigate to login page, removing all routes below it
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          );
        } else {
          // Registration failed (success is false or null based on your UserService return)
          // Since UserService returns bool? and prints errors, we set a generic error message.
          setState(() {
            _errorMessage =
                'Đăng ký thất bại. Vui lòng kiểm tra lại thông tin hoặc thử lại sau.';
            // Cannot focus on specific field as we don't know the exact error cause from backend
          });
        }
      }
    } catch (e) {
      // This catch block handles EXCEPTIONS (e.g., network errors, or if UserService IS modified to throw for API errors)
      if (mounted) {
        String errorMsg = 'Đã xảy ra lỗi không xác định: ${e.toString()}';
        if (e is Exception) {
          // Nếu là Exception thông thường, có thể lấy message
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }
        setState(() {
          _errorMessage = 'Lỗi: $errorMsg'; // Show the error message
        });

        // If you modify UserService to throw specific Exceptions, you can add specific focusing logic here.
        // Example:
        // if (errorMsg.toLowerCase().contains('email đã tồn tại')) {
        //    _emailFocusNode.requestFocus();
        // }
        // ... other error types ...
      }
    } finally {
      // Always set loading state back to false
      if (mounted) {
        // Check mounted again
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === Build Method ===

  @override
  Widget build(BuildContext context) {
    // Sử dụng LayoutBuilder để lấy chiều rộng màn hình
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Tạo widget SignForm một lần duy nhất và truyền các dependency vào constructor
        // Sử dụng các biến state, controllers, focus nodes và hàm xử lý được quản lý ở đây
        Widget signFormWidget = SignForm(
          // Controllers
          emailController: _emailController,
          passwordController: _passwordController,
          nameController: _nameController,
          addressController:
              _addressController, // Pass detailed address controller
          rePasswordController: _rePasswordController,
          // FocusNodes
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          nameFocusNode: _nameFocusNode,
          addressFocusNode: _addressFocusNode,
          rePasswordFocusNode: _rePasswordFocusNode,
          // State variables
          isLoading: _isLoading, // Truyền state isLoading
          errorMessage: _errorMessage, // Truyền state errorMessage
          isPasswordVisible: _isPasswordVisible, // Truyền state visibility
          isRePasswordVisible: _isRePasswordVisible, // Truyền state visibility
          // Location state (initial values for LocationSelection widget inside SignForm)
          // Truyền TÊN đã lưu trữ (hoặc rỗng) để LocationSelection hiển thị
          // TÊN THAM SỐ ĐÃ KHỚP VỚI LOCATIONSELECTION BỊ SỬA TÊN Ở TRƯỚC
          initialProvinceName: _selectedProvinceName,
          initialDistrictName: _selectedDistrictName,
          initialWardName: _selectedWardName,
          // Callbacks/Functions
          // Truyền hàm xử lý location. HÀM NÀY MONG ĐỢI NHẬN TÊN TỪ LocationSelection
          onLocationSelected: _handleLocationSelected,
          onSignup: _handleSignup, // Truyền hàm xử lý signup
          togglePasswordVisibility:
              _togglePasswordVisibility, // Truyền hàm toggle password visibility
          toggleRePasswordVisibility:
              _toggleRePasswordVisibility, // Truyền hàm toggle re-password visibility
          onTextChanged: _onTextChanged, // Truyền hàm xử lý thay đổi text chung
        );

        // --- Layout Logic based on screenWidth ---
        // Sử dụng signFormWidget ở các bố cục khác nhau
        if (screenWidth < 768) {
          // Mobile layout
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
                      // Signup form section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 30.0),
                        child: Container(
                          color: Colors.white.withOpacity(0.9),
                          child: signFormWidget, // Sử dụng widget đã tạo
                        ),
                      ),
                      if (kIsWeb) const Footer(), // Sử dụng const
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return Scaffold(
            backgroundColor:
                const Color.fromARGB(255, 234, 29, 7), // Sử dụng const
            appBar: const PreferredSize(
              // Sử dụng const
              preferredSize: Size.fromHeight(80),
              child: Navbar(),
            ),
            body: SizedBox(
              height: MediaQuery.of(context)
                  .size
                  .height, // Sử dụng MediaQuery để lấy chiều cao
              child: SingleChildScrollView(
                child: Column(
                  // Loại bỏ LayoutBuilder không cần thiết ở đây
                  children: [
                    const SizedBox(height: 20), // Sử dụng const
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth > 600 ? 500 : double.infinity,
                          minWidth: screenWidth > 600 ? 500 : double.infinity,
                        ),
                        child: signFormWidget, // Sử dụng widget đã tạo
                      ),
                    ),
                    const SizedBox(height: 20), // Sử dụng const
                    if (kIsWeb) const Footer(), // Sử dụng const
                  ],
                ),
              ),
            ),
          );
        } else {
          // Desktop layout
          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      children: [
                        const Navbar(), // Sử dụng const
                        Expanded(
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
                                      width: 500, // Có thể điều chỉnh width
                                      constraints: const BoxConstraints(
                                        // Sử dụng const
                                        maxHeight: 510,
                                        minHeight: 350,
                                      ),
                                      child:
                                          signFormWidget, // Sử dụng widget đã tạo
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

// NOTE: Bạn cần đảm bảo đã import và định nghĩa các widget/class sau:
// - footer.dart
// - navbar.dart
// - signup_form.dart (file đã sửa ở trên)
// - UserService (trong database/services/user_service.dart - file đã sửa ở trên)
// - SuccessMessage (trong widgets/SuccessMessage.dart - Đảm bảo có phương thức show)
// - LocationSelection (file đã sửa ở trên)
// - database_helper.dart (chứa baseurl)
// - user_model.dart (chứa class User và fromMap constructor - nếu cần cho UserService logic khác)
// - Không cần UserInfo (từ Storage) hay Provider cho PageSignup
