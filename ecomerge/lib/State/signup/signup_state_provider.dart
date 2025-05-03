import 'package:flutter/material.dart';
import '../core/state_widget.dart';
import '../location/location_state_provider.dart';
import 'base_state_provider.dart';

class SignupStateProvider extends BaseStateProvider {
  // Form controllers
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  // Location state
  late final LocationStateProvider locationState;

  // Password visibility states
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  SignupStateProvider() {
    locationState = LocationStateProvider();

    // Add listeners to persist form data
    emailController.addListener(_handleStateChange);
    nameController.addListener(_handleStateChange);
    addressController.addListener(_handleStateChange);
    passwordController.addListener(_handleStateChange);
    rePasswordController.addListener(_handleStateChange);
  }

  // Getters
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isRePasswordVisible => _isRePasswordVisible;

  // Form data persistence
  void _handleStateChange() {
    setState('formData', {
      'email': emailController.text,
      'name': nameController.text,
      'address': addressController.text,
      'province': locationState.selectedProvince,
      'district': locationState.selectedDistrict,
      'ward': locationState.selectedWard,
    });
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

  // Location selection handler
  void handleLocationSelected(String province, String district, String ward) {
    locationState.selectProvince(province);
    locationState.selectDistrict(district);
    locationState.selectWard(ward);
    _handleStateChange();
  }

  // Form validation
  bool validateForm() {
    if (emailController.text.isEmpty) {
      setError('Vui lòng nhập email');
      return false;
    }

    if (nameController.text.isEmpty) {
      setError('Vui lòng nhập tên người dùng');
      return false;
    }

    if (!locationState.isLocationComplete()) {
      setError('Vui lòng chọn địa chỉ đầy đủ');
      return false;
    }

    if (addressController.text.isEmpty) {
      setError('Vui lòng nhập địa chỉ chi tiết');
      return false;
    }

    if (passwordController.text.isEmpty) {
      setError('Vui lòng nhập mật khẩu');
      return false;
    }

    if (rePasswordController.text != passwordController.text) {
      setError('Mật khẩu nhập lại không khớp');
      return false;
    }

    return true;
  }

  // Form submission
  Future<bool> handleSignup(BuildContext context) async {
    if (!validateForm()) {
      return false;
    }

    setLoading(true);
    try {
      // TODO: Implement actual signup logic here
      await Future.delayed(const Duration(seconds: 1)); // Simulated API call
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Clear error message
  void clearError() {
    setError(null);
  }

  // Export form data
  Map<String, dynamic> exportFormData() {
    return {
      'email': emailController.text,
      'name': nameController.text,
      'address': addressController.text,
      'province': locationState.selectedProvince,
      'district': locationState.selectedDistrict,
      'ward': locationState.selectedWard,
    };
  }

  // Import form data
  void importFormData(Map<String, dynamic> data) {
    emailController.text = data['email'] ?? '';
    nameController.text = data['name'] ?? '';
    addressController.text = data['address'] ?? '';
    if (data['province'] != null) {
      handleLocationSelected(
        data['province'],
        data['district'] ?? '',
        data['ward'] ?? '',
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    addressController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    locationState.dispose();
    super.dispose();
  }
}
