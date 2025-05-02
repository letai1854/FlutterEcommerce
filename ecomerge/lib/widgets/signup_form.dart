import 'package:e_commerce_app/Controllers/User_controller.dart';
import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/widgets/SuccessMessage.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  final UserController _userController = UserController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  @override
  void initState() {
    super.initState();
  }

  void _handleLocationSelected(String province, String district, String ward) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
  }

  String getFullAddress() {
    final specificAddress = _addressController.text;
    final locationParts = [_selectedWard, _selectedDistrict, _selectedProvince]
        .where((part) => part.isNotEmpty)
        .join(', ');
    return [specificAddress, locationParts]
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  Future<void> _handleSignup() async {
    print(_emailController.text);
    print(_nameController.text);
    print(_passwordController.text);
    print(_addressController.text);
    print(_rePasswordController.text);
    // Validate fields
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _rePasswordController.text.isEmpty ||
        _addressController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin';
      });
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _rePasswordController.text) {
      setState(() {
        _errorMessage = 'mật khẩu không trùng khớp';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prepare user data
      final userData = {
        'email': _emailController.text,
        'full_name': _nameController.text, // Changed from fullName to full_name
        'password': _passwordController.text,
        'address': _addressController.text,
        'role': 'customer',
        'status': true,
        'customer_points': 0,
        'avatar': null,
        'created_date': DateTime.now().toIso8601String(),
        'chat_id': null // Will be set by controller
      };
      print('Sending user data: $userData');

      // Call register method
      await _userController.register(userData);

      // Show success message and navigate
// In your _handleSignup method, replace the existing SnackBar with:

      if (mounted) {
        // Clear all input fields
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _addressController.clear();
        _rePasswordController.clear();

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
      setState(() {
        // Extract clean error message
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _errorMessage = errorMsg;

        // Show specific message for email duplicate
        if (errorMsg.contains('Email đã tồn tại')) {
          _emailFocusNode.requestFocus(); // Focus email field
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            'Đăng ký',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            focusNode: _emailFocusNode,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
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
            controller: _nameController,
            focusNode: _nameFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_addressFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'Nhập tên người dùng',
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
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _addressController,
            focusNode: _addressFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            decoration: InputDecoration(
              hintText: 'Nhập địa chỉ chi tiết khác',
              prefixIcon: Icon(
                Icons.location_city,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            obscureText: !_isPasswordVisible,
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Mật khẩu',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[600],
              ),
              suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  )),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _rePasswordController,
            focusNode: _rePasswordFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            obscureText: !_isRePasswordVisible,
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Nhập lại Mật khẩu',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[600],
              ),
              suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isRePasswordVisible = !_isRePasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isRePasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[600],
                  )),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(
            width: double.infinity, // Làm cho button rộng hết cỡ
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(vertical: 18), // Tăng chiều cao button
                backgroundColor:
                    const Color.fromARGB(255, 234, 29, 7), // Màu nền button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: _isLoading ? null : _handleSignup,
              child: _isLoading
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
