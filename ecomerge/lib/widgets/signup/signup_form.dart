import 'package:flutter/material.dart';
import 'package:e_commerce_app/State/core/state_widget.dart';
import 'package:e_commerce_app/State/signup/signup_state_provider.dart';
import 'package:e_commerce_app/widgets/location/location_selection_widget.dart';

class PersistentSignupForm extends StatelessWidget {
  const PersistentSignupForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final state = context.watchState<SignupStateProvider>();

        return Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: state.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => state.clearError(),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: state.nameController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => state.clearError(),
                decoration: InputDecoration(
                  labelText: 'Tên người dùng',
                  prefixIcon: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              LocationSelectionWidget(
                onLocationSelected: state.handleLocationSelected,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: state.addressController,
                textInputAction: TextInputAction.next,
                onChanged: (_) => state.clearError(),
                decoration: InputDecoration(
                  labelText: 'Địa chỉ chi tiết',
                  prefixIcon: Icon(
                    Icons.location_city,
                    color: Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: state.passwordController,
                obscureText: !state.isPasswordVisible,
                textInputAction: TextInputAction.next,
                onChanged: (_) => state.clearError(),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    onPressed: state.togglePasswordVisibility,
                    icon: Icon(
                      state.isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: state.rePasswordController,
                obscureText: !state.isRePasswordVisible,
                textInputAction: TextInputAction.done,
                onChanged: (_) => state.clearError(),
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    onPressed: state.toggleRePasswordVisibility,
                    icon: Icon(
                      state.isRePasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 234, 29, 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await state.handleSignup(context);
                        },
                  child: state.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
