import 'package:e_commerce_app/Controllers/User_controller.dart';
import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/providers/signup_form_provider.dart';
import 'package:e_commerce_app/widgets/SuccessMessage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'location_selection.dart';

class SignForm extends StatefulWidget {
  const SignForm({Key? key}) : super(key: key);

  @override
  State<SignForm> createState() => _SignFormState();
}

class _SignFormState extends State<SignForm> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _rePasswordFocusNode = FocusNode();

  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
  }

  void _handleLocationSelected(String province, String district, String ward) {
    final formProvider =
        Provider.of<SignupFormProvider>(context, listen: false);
    formProvider.setLocation(province, district, ward);
  }

  String getFullAddress() {
    final formProvider =
        Provider.of<SignupFormProvider>(context, listen: false);
    final specificAddress = formProvider.addressController.text;
    final locationParts = [
      formProvider.selectedWard,
      formProvider.selectedDistrict,
      formProvider.selectedProvince
    ].where((part) => part.isNotEmpty).join(', ');

    return [specificAddress, locationParts]
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  Future<void> _handleSignup() async {
    final formProvider =
        Provider.of<SignupFormProvider>(context, listen: false);

    // Validate fields
    if (formProvider.emailController.text.isEmpty ||
        formProvider.nameController.text.isEmpty ||
        formProvider.passwordController.text.isEmpty ||
        formProvider.rePasswordController.text.isEmpty ||
        formProvider.addressController.text.isEmpty) {
      formProvider.setErrorMessage('Vui lòng điền đầy đủ thông tin');
      return;
    }

    // Validate passwords match
    if (formProvider.passwordController.text !=
        formProvider.rePasswordController.text) {
      formProvider.setErrorMessage('mật khẩu không trùng khớp');
      return;
    }

    formProvider.setLoading(true);
    formProvider.setErrorMessage(null);

    try {
      // Prepare user data
      final userData = {
        'email': formProvider.emailController.text,
        'full_name': formProvider.nameController.text,
        'password': formProvider.passwordController.text,
        'address': formProvider.addressController.text,
        'role': 'customer',
        'status': true,
        'customer_points': 0,
        'avatar': null,
        'created_date': DateTime.now().toIso8601String(),
        'chat_id': null
      };

      // Call register method
      await _userController.register(userData);

      if (mounted) {
        // Clear all input fields
        formProvider.emailController.clear();
        formProvider.passwordController.clear();
        formProvider.nameController.clear();
        formProvider.addressController.clear();
        formProvider.rePasswordController.clear();

        SuccessMessage.show(
          context,
          title: 'Đăng ký thành công!',
          duration: const Duration(seconds: 2),
          onDismissed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      // Extract clean error message
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      formProvider.setErrorMessage(errorMsg);

      // Show specific message for email duplicate
      if (errorMsg.contains('Email đã tồn tại')) {
        _emailFocusNode.requestFocus(); // Focus email field
      }
    } finally {
      if (mounted) {
        formProvider.setLoading(false);
      }
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _rePasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = Provider.of<SignupFormProvider>(context);

    return Container(
      width: 400,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Text(
            'Đăng ký',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            focusNode: _emailFocusNode,
            controller: formProvider.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (formProvider.errorMessage != null) {
                formProvider.setErrorMessage(null);
              }
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_nameFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: formProvider.nameController,
            focusNode: _nameFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (formProvider.errorMessage != null) {
                formProvider.setErrorMessage(null);
              }
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_addressFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'Nhập tên người dùng',
              prefixIcon: Icon(
                Icons.person,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          LocationSelection(
            onLocationSelected: _handleLocationSelected,
            initialProvince: formProvider.selectedProvince,
            initialDistrict: formProvider.selectedDistrict,
            initialWard: formProvider.selectedWard,
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: formProvider.addressController,
            focusNode: _addressFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (formProvider.errorMessage != null) {
                formProvider.setErrorMessage(null);
              }
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'Nhập địa chỉ chi tiết khác',
              prefixIcon: Icon(
                Icons.location_city,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: formProvider.passwordController,
            focusNode: _passwordFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            obscureText: !formProvider.isPasswordVisible,
            onChanged: (value) {
              if (formProvider.errorMessage != null) {
                formProvider.setErrorMessage(null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Mật khẩu',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[600],
              ),
              suffixIcon: IconButton(
                onPressed: () => formProvider.togglePasswordVisibility(),
                icon: Icon(
                  formProvider.isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey[600],
                ),
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: formProvider.rePasswordController,
            focusNode: _rePasswordFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            obscureText: !formProvider.isRePasswordVisible,
            onChanged: (value) {
              if (formProvider.errorMessage != null) {
                formProvider.setErrorMessage(null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Nhập lại Mật khẩu',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[600],
              ),
              suffixIcon: IconButton(
                onPressed: () => formProvider.toggleRePasswordVisibility(),
                icon: Icon(
                  formProvider.isRePasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey[600],
                ),
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          if (formProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                formProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color.fromARGB(255, 234, 29, 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: formProvider.isLoading ? null : _handleSignup,
              child: formProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
