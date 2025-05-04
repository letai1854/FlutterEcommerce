import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/providers/login_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/Controllers/User_controller.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Initialize focus nodes
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
    // Mark that we're in the form, no need to reset when building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LoginFormProvider>(context, listen: false);
      provider.setScreenResize(true);
    });
  }

  @override
  void dispose() {
    // Only dispose focus nodes here - controllers are managed by the provider
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    // Mark form as not in resize mode when leaving
    final provider = Provider.of<LoginFormProvider>(context, listen: false);
    provider.setScreenResize(false);

    super.dispose();
  }

  @override
  void deactivate() {
    // Reset the form when navigating away (unless it's just a resize)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<LoginFormProvider>(context, listen: false);
        provider.resetForm();
      }
    });
    super.deactivate();
  }

  Future<void> _handleLogin(LoginFormProvider provider) async {
    // Get controllers from provider
    final emailController = provider.emailController;
    final passwordController = provider.passwordController;

    // Validate fields
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      provider.setErrorMessage('Vui lòng điền đầy đủ thông tin');
      return;
    }

    provider.setLoading(true);
    provider.setErrorMessage(null);

    try {
      final user = await _userController.login(
        emailController.text,
        passwordController.text,
      );

      if (mounted) {
        // Store user in provider
        UserProvider().setUser(user);

        // Set flag to false before navigating away
        provider.setScreenResize(false);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        provider.setErrorMessage(errorMsg);

        // Focus email field if credentials are invalid
        if (errorMsg.contains('Email hoặc mật khẩu không đúng')) {
          _emailFocusNode.requestFocus();
        }
      }
    } finally {
      if (mounted) {
        provider.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the provider
    return Consumer<LoginFormProvider>(
      builder: (context, loginProvider, child) {
        return Container(
          width: 400,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                focusNode: _emailFocusNode,
                controller: loginProvider.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
                onChanged: (value) {
                  // Clear error message when user starts typing
                  if (loginProvider.errorMessage != null) {
                    loginProvider.setErrorMessage(null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 255, 85, 0)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                focusNode: _passwordFocusNode,
                controller: loginProvider.passwordController,
                obscureText: !loginProvider.isPasswordVisible,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  // Clear error message when user starts typing
                  if (loginProvider.errorMessage != null) {
                    loginProvider.setErrorMessage(null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      loginProvider.isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      loginProvider.togglePasswordVisibility();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 255, 85, 0)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
              SizedBox(height: 16),
              if (loginProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    loginProvider.errorMessage!,
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
                  onPressed: loginProvider.isLoading
                      ? null
                      : () => _handleLogin(loginProvider),
                  child: loginProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: Text(
                    'Quên mật khẩu',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bạn mới biết đến Shopi? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 234, 29, 7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
