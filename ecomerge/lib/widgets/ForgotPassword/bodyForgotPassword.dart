// lib/widgets/ForgotPassword/bodyForgotPassword.dart
import 'package:flutter/material.dart';
// Không cần import Provider hay UserService ở đây nữa


class bodyForgotPassword extends StatefulWidget { // Giữ là StatefulWidget vì có setState cho obscure toggle bên trong _bodyForgotPasswordState
  // --- NHẬN PROPS TỪ WIDGET CHA ---
  final TextEditingController emailController;
  final TextEditingController codeController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final int currentStep;
  final bool isEmailVerified; // true nếu đã xác thực email
  final bool isSendingOtp; // true khi nút "Xác thực" đang loading
  final bool isVerifyingOtp; // true khi nút "Tiếp tục" đang loading
  final bool isResettingPassword; // true khi nút "Lưu thay đổi" đang loading
  final String? errorMessage; // Thông báo lỗi để hiển thị

  // Callbacks từ widget cha
  final VoidCallback onVerifyEmailPressed; // Xử lý khi nhấn nút Xác thực
  final VoidCallback onContinuePressed;    // Xử lý khi nhấn nút Tiếp tục
  final VoidCallback onResetPasswordPressed; // Xử lý khi nhấn nút Lưu thay đổi
  final VoidCallback goBackToVerificationStep; // Xử lý khi nhấn nút Quay lại (ở bước 1)
  final VoidCallback onTextChanged; // Xử lý khi text thay đổi (để xóa lỗi)


  const bodyForgotPassword({
    Key? key,
    required this.emailController,
    required this.codeController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.currentStep,
    required this.isEmailVerified,
    required this.isSendingOtp, // Tên mới cho loading xác thực email
    required this.isVerifyingOtp, // Loading cho bước xác thực OTP
    required this.isResettingPassword, // Loading cho bước đặt mật khẩu mới
    required this.errorMessage, // Thông báo lỗi
    required this.onVerifyEmailPressed,
    required this.onContinuePressed,
    required this.onResetPasswordPressed,
    required this.goBackToVerificationStep,
    required this.onTextChanged, // Callback khi text thay đổi
  }) : super(key: key);


  @override
  State<bodyForgotPassword> createState() => _bodyForgotPasswordState();
}

class _bodyForgotPasswordState extends State<bodyForgotPassword> {
  // --- STATE CỤC BỘ CHO VIỆC ẨN/HIỆN MẬT KHẨU ---
  // Lý do: Việc toggle chỉ ảnh hưởng đến UI của widget này, không cần state ở cha
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Hàm toggle state cục bộ cho obscure
  void _toggleObscurePassword() {
    setState(() { _obscurePassword = !_obscurePassword; });
  }

   void _toggleObscureConfirmPassword() {
    setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; });
  }


  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      // --- GIỮ NGUYÊN UI GỐC ---
      color: Colors.grey[100],
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center, // Căn giữa Card
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30), // Sử dụng const
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 40.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550), // Sử dụng const
            padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
            child: Form(
              // --- SỬ DỤNG FORMKEY TỪ WIDGET CHA ---
              key: widget.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text( 'Quên mật khẩu', style: TextStyle( fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.red, ), textAlign: TextAlign.center, ), // Sử dụng const
                  const SizedBox(height: 24.0), // Sử dụng const
                  Row( // Step Indicator
                    children: [
                      // --- SỬ DỤNG CURRENTSTEP TỪ WIDGET CHA ---
                      _buildStepIndicator(0, 'Xác thực', widget.currentStep),
                      _buildStepConnector(0, widget.currentStep),
                      _buildStepIndicator(1, 'Đổi mật khẩu', widget.currentStep),
                    ],
                  ),
                  const SizedBox(height: 32.0), // Sử dụng const
                  // --- HIỂN THỊ STEP DỰA TRÊN CURRENTSTEP TỪ WIDGET CHA ---
                   // Hiển thị thông báo lỗi chung nếu có
                  if (widget.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0), // Sử dụng const
                        child: Text(
                          widget.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14.0), // Sử dụng const
                          textAlign: TextAlign.center,
                        ),
                      ),
                  widget.currentStep == 0
                      ? _buildVerificationStep(isMobile) // Bước 0: Email + Code
                      : _buildNewPasswordStep(), // Bước 1: New Password
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- GIỮ NGUYÊN CÁC HÀM HELPER UI ---
  Widget _buildStepIndicator(int step, String label, int currentStep) { // Nhận currentStep
    final bool isActive = currentStep >= step;
    return Expanded( child: Column( children: [ Container( width: 32.0, height: 32.0, decoration: BoxDecoration( color: isActive ? Colors.red : Colors.grey[300], shape: BoxShape.circle, ), child: Center( child: Text( '${step + 1}', style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, ), ), ), ), const SizedBox(height: 8.0), Text( label, style: TextStyle( color: isActive ? Colors.red : Colors.grey[600], fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13 ), textAlign: TextAlign.center, ), ], ), ); // Sử dụng const
  }

  Widget _buildStepConnector(int step, int currentStep) { // Nhận currentStep
    final bool isActive = currentStep > step;
     return Expanded(child: Container( height: 2.0, margin: const EdgeInsets.symmetric(horizontal: 4.0), color: isActive ? Colors.red : Colors.grey[300], )); // Sử dụng const
  }

  // Build verification step (Step 0: Email + Code)
  Widget _buildVerificationStep(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField( // Email
            // --- SỬ DỤNG CONTROLLER & STATE TỪ WIDGET CHA ---
            controller: widget.emailController,
            enabled: !widget.isEmailVerified && !widget.isSendingOtp && !widget.isVerifyingOtp, // Disable khi đã xác thực hoặc đang loading bất kỳ nút nào
            // --- Giữ nguyên decoration và validator ---
            decoration: InputDecoration( labelText: 'Email', hintText: 'Nhập địa chỉ email', border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ), prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), ), // Sử dụng const
            keyboardType: TextInputType.emailAddress,
             onChanged: (value) => widget.onTextChanged(), // Gọi callback on text change
            validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập email'; if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email không hợp lệ'; return null; },
          ),
        const SizedBox(height: 12.0), // Sử dụng const
        // Nút "Xác thực" email
        ElevatedButton(
            // --- SỬ DỤNG STATE VÀ HÀM TỪ WIDGET CHA ---
            // Nút enable nếu chưa verified và không đang loading (gửi OTP hoặc verify OTP)
            onPressed: (!widget.isEmailVerified && !widget.isSendingOtp && !widget.isVerifyingOtp)
                ? () {
                     // Validate chỉ trường email ở đây nếu muốn, hoặc validate cả form khi nhấn nút tiếp tục
                     if (widget.formKey.currentState!.validate()) { // Validate toàn bộ form cho chắc
                         widget.onVerifyEmailPressed(); // Gọi hàm xử lý xác thực email
                     }
                  }
                : null, // Disable nút
            // --- Giữ nguyên style ---
            style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), ), // Sử dụng const
            child: widget.isSendingOtp // Sử dụng state loading cho nút này
                ? const SizedBox( width: 20, height: 20, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2, ), ) // Sử dụng const
                : const Text('Xác thực Email'), // Sử dụng const
          ),
        const SizedBox(height: 20.0), // Sử dụng const
        TextFormField( // Mã xác thực (OTP)
          // --- SỬ DỤNG CONTROLLER & STATE TỪ WIDGET CHA ---
          controller: widget.codeController,
          enabled: widget.isEmailVerified && !widget.isSendingOtp && !widget.isVerifyingOtp, // Enable chỉ khi email verified và không loading
           // --- Giữ nguyên decoration và validator ---
          decoration: InputDecoration( labelText: 'Mã xác thực', hintText: 'Nhập mã gồm 6 chữ số', border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ), prefixIcon: const Icon(Icons.password_outlined), filled: true, fillColor: Colors.white, counterText: "", contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), ), // Sử dụng const
          keyboardType: TextInputType.number,
          maxLength: 6,
           onChanged: (value) => widget.onTextChanged(), // Gọi callback on text change
          validator: (value) {
            // Validate mã chỉ khi email đã verified
            if (widget.isEmailVerified) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập mã';
                if (value.length != 6) return 'Mã phải có đúng 6 chữ số';
                 // Thêm regex check nếu mã chỉ gồm số
                if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Mã phải là 6 chữ số';
             }
             return null;
            },
        ),
        const SizedBox(height: 24.0), // Sử dụng const
        // Nút Tiếp tục (Xác thực OTP)
        ElevatedButton(
            // --- SỬ DỤNG STATE VÀ HÀM TỪ WIDGET CHA ---
            // Nút enable khi email verified và không đang loading bất kỳ nút nào
            onPressed: (widget.isEmailVerified && !widget.isSendingOtp && !widget.isVerifyingOtp && !widget.isResettingPassword)
                ? () {
                     // Validate cả form (email và code) trước khi gọi API verify OTP
                     if (widget.formKey.currentState!.validate()) {
                        widget.onContinuePressed(); // Gọi hàm xử lý tiếp tục (verify OTP)
                     }
                  }
                : null, // Disable nút
           // --- Giữ nguyên style ---
          style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), ), // Sử dụng const
          child: widget.isVerifyingOtp // Sử dụng state loading cho nút này
              ? const SizedBox( width: 20, height: 20, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2, ), ) // Sử dụng const
              : const Text( 'Tiếp tục', style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16.0, ), ), // Sử dụng const
        ),
        const SizedBox(height: 16.0), // Sử dụng const
        // Link Quay lại đăng nhập
        TextButton(
          onPressed: !widget.isSendingOtp && !widget.isVerifyingOtp && !widget.isResettingPassword // Enable khi không loading
              ? () => Navigator.pushReplacementNamed(context, '/login')
              : null,
          child: const Text( 'Quay lại đăng nhập', style: TextStyle( color: Colors.blue, ), ), // Sử dụng const
        ),
      ],
    );
  }

  // Build new password step (Step 1: New Password)
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
         const Text( 'Đặt lại mật khẩu', style: TextStyle( fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87, ), textAlign: TextAlign.center, ), // Sử dụng const
         const SizedBox(height: 20.0), // Sử dụng const
        TextFormField( // Mật khẩu mới
          // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ---
          controller: widget.newPasswordController,
          // --- SỬ DỤNG STATE CỤC BỘ ---
          obscureText: _obscurePassword,
           onChanged: (value) => widget.onTextChanged(), // Gọi callback on text change
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới (ít nhất 8 ký tự)',
            border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ),
            prefixIcon: const Icon(Icons.lock_outline), // Sử dụng const
            // --- SỬ DỤNG STATE CỤC BỘ VÀ HÀM SETSTATE CỤC BỘ ---
            suffixIcon: IconButton(
              icon: Icon( _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, ),
              onPressed: _toggleObscurePassword, // Gọi hàm toggle cục bộ
            ),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), // Sử dụng const
          ),
           // --- Giữ nguyên validator ---
          validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu'; if (value.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự'; return null; },
        ),
        const SizedBox(height: 20.0), // Sử dụng const
        TextFormField( // Xác nhận mật khẩu
           // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ---
          controller: widget.confirmPasswordController,
          // --- SỬ DỤNG STATE CỤC BỘ ---
          obscureText: _obscureConfirmPassword,
           onChanged: (value) => widget.onTextChanged(), // Gọi callback on text change
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            hintText: 'Nhập lại mật khẩu mới',
            border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ),
            prefixIcon: const Icon(Icons.lock_outline), // Sử dụng const
             // --- SỬ DỤNG STATE CỤC BỘ VÀ HÀM SETSTATE CỤC BỘ ---
            suffixIcon: IconButton(
              icon: Icon( _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, ),
              onPressed: _toggleObscureConfirmPassword, // Gọi hàm toggle cục bộ
            ),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), // Sử dụng const
          ),
           // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ĐỂ SO SÁNH ---
          validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu'; if (value != widget.newPasswordController.text) return 'Mật khẩu không khớp'; return null; },
        ),
        const SizedBox(height: 24.0), // Sử dụng const
        // Nút Lưu thay đổi (Reset Password)
        ElevatedButton(
          // --- SỬ DỤNG STATE VÀ HÀM TỪ WIDGET CHA ---
           // Nút enable khi không đang loading bất kỳ nút nào
          onPressed: (!widget.isSendingOtp && !widget.isVerifyingOtp && !widget.isResettingPassword)
              ? () {
                  // Validate cả form (mật khẩu mới và xác nhận)
                  if (widget.formKey.currentState!.validate()) {
                     widget.onResetPasswordPressed(); // Gọi hàm xử lý reset password
                  }
                }
              : null, // Disable nút
          // --- Giữ nguyên style ---
          style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), ), // Sử dụng const
          child: widget.isResettingPassword // Sử dụng state loading cho nút này
               ? const SizedBox( width: 20, height: 20, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2, ), ) // Sử dụng const
               : const Text( 'Lưu thay đổi', style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16.0, ), ), // Sử dụng const
        ),
        const SizedBox(height: 16.0), // Sử dụng const
        // Nút Quay lại (về bước 0)
        TextButton(
          // --- SỬ DỤNG HÀM TỪ WIDGET CHA ---
           // Enable khi không loading
          onPressed: !widget.isSendingOtp && !widget.isVerifyingOtp && !widget.isResettingPassword
              ? widget.goBackToVerificationStep
              : null,
          child: const Text( 'Quay lại', style: TextStyle( color: Colors.blue, ), ), // Sử dụng const
        ),
      ],
    );
  }
}
