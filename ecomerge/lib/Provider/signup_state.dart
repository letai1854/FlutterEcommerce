import 'package:flutter/material.dart';
import 'package:e_commerce_app/Controllers/User_controller.dart';

class SignUpState extends ChangeNotifier {
  final UserController _userController = UserController();
  bool _isLoading = false;
  String? _errorMessage;
  final ScrollController scrollController = ScrollController();

  // Form Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController rePasswordController = TextEditingController();

  // Location state
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  // Password visibility
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isRePasswordVisible => _isRePasswordVisible;
  String get selectedProvince => _selectedProvince;
  String get selectedDistrict => _selectedDistrict;
  String get selectedWard => _selectedWard;

  // Location selection handler
  void handleLocationSelected(String province, String district, String ward) {
    _selectedProvince = province;
    _selectedDistrict = district;
    _selectedWard = ward;
    notifyListeners();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRePasswordVisibility() {
    _isRePasswordVisible = !_isRePasswordVisible;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  String getFullAddress() {
    final specificAddress = addressController.text;
    final locationParts = [_selectedWard, _selectedDistrict, _selectedProvince]
        .where((part) => part.isNotEmpty)
        .join(', ');
    return [specificAddress, locationParts]
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  Future<bool> handleSignup(BuildContext context) async {
    // Validate fields
    if (emailController.text.isEmpty ||
        nameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        rePasswordController.text.isEmpty ||
        addressController.text.isEmpty) {
      _errorMessage = 'Vui lòng điền đầy đủ thông tin';
      notifyListeners();
      return false;
    }

    // Validate passwords match
    if (passwordController.text != rePasswordController.text) {
      _errorMessage = 'mật khẩu không trùng khớp';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Prepare user data
      final userData = {
        'email': emailController.text,
        'full_name': nameController.text,
        'password': passwordController.text,
        'address': getFullAddress(),
        'role': 'customer',
        'status': true,
        'customer_points': 0,
        'avatar': null,
        'created_date': DateTime.now().toIso8601String(),
        'chat_id': null
      };

      // Call register method
      await _userController.register(userData);

      // Clear all input fields
      clearForm();
      return true;
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    addressController.clear();
    rePasswordController.clear();
    _selectedProvince = '';
    _selectedDistrict = '';
    _selectedWard = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose all controllers
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    rePasswordController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
