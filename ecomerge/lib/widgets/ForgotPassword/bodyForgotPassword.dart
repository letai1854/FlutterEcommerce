
import 'package:flutter/material.dart';

class bodyForgotPassword extends StatefulWidget {
  const bodyForgotPassword({super.key});

  @override
  State<bodyForgotPassword> createState() => _bodyForgotPasswordState();
}

class _bodyForgotPasswordState extends State<bodyForgotPassword> {
  // Controllers for the text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Form keys for validation
  final _formKey = GlobalKey<FormState>();
  
  // Page state - 0: email, 1: verification, 2: new password
  int _currentStep = 0;
  
  // Email verification state
  bool _isEmailVerified = false;
  bool _isVerifying = false;
  
  // Password visibility toggle
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Simulate email verification
  Future<void> _verifyEmail() async {
    setState(() {
      _isVerifying = true;
    });
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _isVerifying = false;
      _isEmailVerified = true;
    });
    
    // Optional: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã xác thực đã được gửi đến email của bạn'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Simulate verification code check and move to next step
  void _continueToPasswordReset() {
    if (_codeController.text.length >= 6) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập mã xác thực hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Simulate password reset
  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      // Simulate API call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to login page
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Determine if we're on mobile based on screen width
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      color: Colors.grey[100],
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Card(
          margin: EdgeInsets.all(isMobile ? 16.0 : 0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: isMobile ? double.infinity : 500,
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Quên mật khẩu',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 24.0),
                  
                  // Step indicator
                  Row(
                    children: [
                      _buildStepIndicator(0, 'Xác thực'),
                      _buildStepConnector(0),
                      _buildStepIndicator(1, 'Đổi mật khẩu'),
                    ],
                  ),
                  
                  SizedBox(height: 32.0),
                  
                  // Form fields based on current step
                  _currentStep == 0 
                      ? _buildVerificationStep(isMobile)
                      : _buildNewPasswordStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Build a step indicator circle
  Widget _buildStepIndicator(int step, String label) {
    final bool isActive = _currentStep >= step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.red : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build connector line between steps
  Widget _buildStepConnector(int step) {
    final bool isActive = _currentStep > step;
    
    return Container(
      width: 40.0,
      height: 2.0,
      color: isActive ? Colors.red : Colors.grey[300],
    );
  }
  
  // Build verification step
  Widget _buildVerificationStep(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field with verify button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Nhập địa chỉ email của bạn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEmailVerified,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: _isEmailVerified || _isVerifying ? null : _verifyEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 14.0 : 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isVerifying
                  ? SizedBox(
                      width: 20,
                      height: 20, 
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Xác thực',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
        
        SizedBox(height: 20.0),
        
        // Verification code field
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Mã xác thực',
            hintText: 'Nhập mã xác thực gửi đến email của bạn',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.lock),
            filled: true,
            fillColor: Colors.white,
            enabled: _isEmailVerified,
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (_isEmailVerified) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mã xác thực';
              }
              if (value.length < 6) {
                return 'Mã xác thực phải có 6 ký tự';
              }
            }
            return null;
          },
        ),
        
        SizedBox(height: 24.0),
        
        // Continue button
        ElevatedButton(
          onPressed: _isEmailVerified ? _continueToPasswordReset : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Tiếp tục',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
        
        SizedBox(height: 16.0),
        
        // Back to login link
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text(
            'Quay lại trang đăng nhập',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
  
  // Build new password step
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // New password field
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu mới';
            }
            if (value.length < 8) {
              return 'Mật khẩu phải có ít nhất 8 ký tự';
            }
            return null;
          },
        ),
        
        SizedBox(height: 20.0),
        
        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu mới',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != _newPasswordController.text) {
              return 'Mật khẩu không trùng khớp';
            }
            return null;
          },
        ),
        
        SizedBox(height: 24.0),
        
        // Save button
        ElevatedButton(
          onPressed: _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Lưu thay đổi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
        
        SizedBox(height: 16.0),
        
        // Back button
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = 0;
            });
          },
          child: Text(
            'Quay lại',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
