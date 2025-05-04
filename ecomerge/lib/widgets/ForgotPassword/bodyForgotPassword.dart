import 'package:flutter/material.dart';

class bodyForgotPassword extends StatefulWidget { // Giữ là StatefulWidget vì có setState cho obscure toggle bên trong _buildNewPasswordStep
  // --- NHẬN PROPS TỪ WIDGET CHA ---
  final TextEditingController emailController;
  final TextEditingController codeController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final int currentStep;
  final bool isEmailVerified;
  final bool isVerifying;
  // final bool obscurePassword; // State này cần cục bộ trong _bodyForgotPasswordState để setState
  // final bool obscureConfirmPassword; // State này cần cục bộ trong _bodyForgotPasswordState để setState
  final VoidCallback verifyEmail;
  final VoidCallback continueToPasswordReset;
  final VoidCallback resetPassword;
  // final VoidCallback toggleObscurePassword; // Sẽ xử lý bằng state cục bộ
  // final VoidCallback toggleObscureConfirmPassword; // Sẽ xử lý bằng state cục bộ
  final VoidCallback goBackToVerificationStep; // Callback để quay lại bước 0

  const bodyForgotPassword({
    Key? key,
    required this.emailController,
    required this.codeController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.currentStep,
    required this.isEmailVerified,
    required this.isVerifying,
    // required this.obscurePassword, // Không nhận state này nữa
    // required this.obscureConfirmPassword, // Không nhận state này nữa
    required this.verifyEmail,
    required this.continueToPasswordReset,
    required this.resetPassword,
    // required this.toggleObscurePassword, // Không nhận hàm này nữa
    // required this.toggleObscureConfirmPassword, // Không nhận hàm này nữa
    required this.goBackToVerificationStep,
  }) : super(key: key);


  @override
  State<bodyForgotPassword> createState() => _bodyForgotPasswordState();
}

class _bodyForgotPasswordState extends State<bodyForgotPassword> {
  // --- STATE CỤC BỘ CHO VIỆC ẨN/HIỆN MẬT KHẨU ---
  // Lý do: Việc toggle chỉ ảnh hưởng đến UI của widget này, không cần state ở cha
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- GIỮ NGUYÊN HÀM BUILD VÀ CÁC HÀM HELPER ---
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
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 40.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 550),
            padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
            child: Form(
              // --- SỬ DỤNG FORMKEY TỪ WIDGET CHA ---
              key: widget.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text( 'Quên mật khẩu', style: TextStyle( fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.red, ), textAlign: TextAlign.center, ),
                  SizedBox(height: 24.0),
                  Row( // Step Indicator
                    children: [
                      // --- SỬ DỤNG CURRENTSTEP TỪ WIDGET CHA ---
                      _buildStepIndicator(0, 'Xác thực', widget.currentStep),
                      _buildStepConnector(0, widget.currentStep),
                      _buildStepIndicator(1, 'Đổi mật khẩu', widget.currentStep),
                    ],
                  ),
                  SizedBox(height: 32.0),
                  // --- HIỂN THỊ STEP DỰA TRÊN CURRENTSTEP TỪ WIDGET CHA ---
                  widget.currentStep == 0
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

  // --- GIỮ NGUYÊN CÁC HÀM HELPER UI ---
  Widget _buildStepIndicator(int step, String label, int currentStep) { // Nhận currentStep
    final bool isActive = currentStep >= step;
    return Expanded( child: Column( children: [ Container( width: 32.0, height: 32.0, decoration: BoxDecoration( color: isActive ? Colors.red : Colors.grey[300], shape: BoxShape.circle, ), child: Center( child: Text( '${step + 1}', style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, ), ), ), ), SizedBox(height: 8.0), Text( label, style: TextStyle( color: isActive ? Colors.red : Colors.grey[600], fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13 ), textAlign: TextAlign.center, ), ], ), );
  }

  Widget _buildStepConnector(int step, int currentStep) { // Nhận currentStep
    final bool isActive = currentStep > step;
     return Expanded(child: Container( height: 2.0, margin: EdgeInsets.symmetric(horizontal: 4.0), color: isActive ? Colors.red : Colors.grey[300], ));
  }

  // Build verification step
  Widget _buildVerificationStep(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row( // Email và nút Xác thực
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                // --- SỬ DỤNG CONTROLLER & STATE TỪ WIDGET CHA ---
                controller: widget.emailController,
                enabled: !widget.isEmailVerified,
                // --- Giữ nguyên decoration và validator ---
                decoration: InputDecoration( labelText: 'Email', hintText: 'Nhập địa chỉ email', border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ), prefixIcon: Icon(Icons.email_outlined), filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12), ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập email'; if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email không hợp lệ'; return null; },
              ),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              // --- SỬ DỤNG STATE VÀ HÀM TỪ WIDGET CHA ---
              onPressed: widget.isEmailVerified || widget.isVerifying ? null : widget.verifyEmail,
              // --- Giữ nguyên style ---
              style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: isMobile ? 14.0 : 15.0, horizontal: 16), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), minimumSize: Size(isMobile ? 90 : 110, 50), ),
              child: widget.isVerifying ? SizedBox( width: 20, height: 20, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2, ), ) : Text('Xác thực'),
            ),
          ],
        ),
        SizedBox(height: 20.0),
        TextFormField( // Mã xác thực
          // --- SỬ DỤNG CONTROLLER & STATE TỪ WIDGET CHA ---
          controller: widget.codeController,
          enabled: widget.isEmailVerified,
           // --- Giữ nguyên decoration và validator ---
          decoration: InputDecoration( labelText: 'Mã xác thực', hintText: 'Nhập mã gồm 6 chữ số', border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ), prefixIcon: Icon(Icons.password_outlined), filled: true, fillColor: Colors.white, counterText: "", contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12), ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) { if (widget.isEmailVerified) { if (value == null || value.isEmpty) return 'Vui lòng nhập mã'; if (value.length != 6) return 'Mã phải có đúng 6 chữ số'; } return null; },
        ),
        SizedBox(height: 24.0),
        ElevatedButton( // Nút Tiếp tục
          // --- SỬ DỤNG STATE VÀ HÀM TỪ WIDGET CHA ---
          onPressed: widget.isEmailVerified ? widget.continueToPasswordReset : null,
           // --- Giữ nguyên style ---
          style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), ),
          child: Text( 'Tiếp tục', style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16.0, ), ),
        ),
        SizedBox(height: 16.0),
        TextButton( // Link Quay lại đăng nhập
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text( 'Quay lại đăng nhập', style: TextStyle( color: Colors.blue, ), ),
        ),
      ],
    );
  }

  // Build new password step
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField( // Mật khẩu mới
          // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ---
          controller: widget.newPasswordController,
          // --- SỬ DỤNG STATE CỤC BỘ ---
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới (ít nhất 8 ký tự)',
            border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ),
            prefixIcon: Icon(Icons.lock_outline),
            // --- SỬ DỤNG STATE CỤC BỘ VÀ SETSTATE CỤC BỘ ---
            suffixIcon: IconButton(
              icon: Icon( _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, ),
              onPressed: () {
                setState(() { _obscurePassword = !_obscurePassword; }); // Toggle state cục bộ
              },
            ),
            filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
           // --- Giữ nguyên validator ---
          validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu'; if (value.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự'; return null; },
        ),
        SizedBox(height: 20.0),
        TextFormField( // Xác nhận mật khẩu
           // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ---
          controller: widget.confirmPasswordController,
          // --- SỬ DỤNG STATE CỤC BỘ ---
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            hintText: 'Nhập lại mật khẩu mới',
            border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), ),
            prefixIcon: Icon(Icons.lock_outline),
             // --- SỬ DỤNG STATE CỤC BỘ VÀ SETSTATE CỤC BỘ ---
            suffixIcon: IconButton(
              icon: Icon( _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, ),
              onPressed: () {
                 setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; }); // Toggle state cục bộ
              },
            ),
            filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
           // --- SỬ DỤNG CONTROLLER TỪ WIDGET CHA ĐỂ SO SÁNH ---
          validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu'; if (value != widget.newPasswordController.text) return 'Mật khẩu không khớp'; return null; },
        ),
        SizedBox(height: 24.0),
        ElevatedButton( // Nút Lưu thay đổi
          // --- SỬ DỤNG HÀM TỪ WIDGET CHA ---
          onPressed: widget.resetPassword,
          // --- Giữ nguyên style ---
          style: ElevatedButton.styleFrom( backgroundColor: Colors.red, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0), ), ),
          child: Text( 'Lưu thay đổi', style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16.0, ), ),
        ),
        SizedBox(height: 16.0),
        TextButton( // Nút Quay lại
          // --- SỬ DỤNG HÀM TỪ WIDGET CHA ---
          onPressed: widget.goBackToVerificationStep,
          child: Text( 'Quay lại', style: TextStyle( color: Colors.blue, ), ),
        ),
      ],
    );
  }
}
