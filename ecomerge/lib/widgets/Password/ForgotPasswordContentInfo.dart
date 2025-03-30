import 'package:e_commerce_app/Screens/UserInfo/UserInfoDesktop.dart';
import 'package:e_commerce_app/widgets/Field/CustomFormField.dart';
import 'package:e_commerce_app/widgets/Password/PasswordField.dart';
import 'package:flutter/material.dart';

class ForgotPasswordContentInfo extends StatefulWidget {
  const ForgotPasswordContentInfo({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordContentInfo> createState() =>
      _ForgotPasswordContentInfoState();
}

class _ForgotPasswordContentInfoState extends State<ForgotPasswordContentInfo> {
  int currentStep = 1;
  String email = "example@gmail.com";
  String verificationCode = "";
  String newPassword = "";
  String confirmPassword = "";

  void moveToNextStep() {
    setState(() {
      if (currentStep < 3) {
        currentStep++;
      }
    });
  }

  void moveToPreviousStep() {
    setState(() {
      if (currentStep > 1) {
        currentStep--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quên mật khẩu",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepIndicator(1,
                isActive: currentStep == 1, isComplete: currentStep > 1),
            _buildStepConnector(isActive: currentStep > 1),
            _buildStepIndicator(2,
                isActive: currentStep == 2, isComplete: currentStep > 2),
            _buildStepConnector(isActive: currentStep > 2),
            _buildStepIndicator(3,
                isActive: currentStep == 3, isComplete: false),
          ],
        ),

        const SizedBox(height: 40),

        // Current Step Content
        if (currentStep == 1) _buildStep1Content(),
        if (currentStep == 2) _buildStep2Content(),
        if (currentStep == 3) _buildStep3Content(),
      ],
    );
  }

  // Step 1 - Email entry
  Widget _buildStep1Content() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nhập email của bạn để nhận mã xác nhận",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          CustomFormField(
            label: "Email",
            initialValue: email,
            onChanged: (value) {
              setState(() {
                email = value;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Logic to send verification code would go here
              moveToNextStep();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: Colors.blue,
            ),
            child: const Text("Gửi mã xác nhận"),
          ),
        ],
      ),
    );
  }

  // Step 2 - Verification code
  Widget _buildStep2Content() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nhập mã xác nhận đã được gửi đến email của bạn",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Mã xác nhận đã được gửi đến: $email",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CustomFormField(
            label: "Mã xác nhận",
            initialValue: verificationCode,
            onChanged: (value) {
              setState(() {
                verificationCode = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: moveToPreviousStep,
                child: const Text("Quay lại"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // Verification logic would go here
                  moveToNextStep();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Xác nhận"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3 - New password
  Widget _buildStep3Content() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tạo mật khẩu mới",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          PasswordField(
            label: "Mật khẩu mới",
            initialValue: newPassword,
            onChanged: (value) {
              setState(() {
                newPassword = value;
              });
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: "Xác nhận mật khẩu mới",
            initialValue: confirmPassword,
            onChanged: (value) {
              setState(() {
                confirmPassword = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: moveToPreviousStep,
                child: const Text("Quay lại"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // Password change logic would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mật khẩu đã được thay đổi thành công"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Hoàn thành"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step indicator widget
  Widget _buildStepIndicator(int step,
      {required bool isActive, required bool isComplete}) {
    return StepIndicator(
      step: step,
      isActive: isActive,
      isComplete: isComplete,
    );
  }

  // Step connector widget
  Widget _buildStepConnector({required bool isActive}) {
    return StepConnector(
      isActive: isActive,
    );
  }
}

class StepIndicator extends StatelessWidget {
  final int step;
  final bool isActive;
  final bool isComplete;

  const StepIndicator({
    Key? key,
    required this.step,
    required this.isActive,
    required this.isComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Colors.blue
            : (isComplete ? Colors.green : Colors.grey.shade300),
        border: Border.all(
          color: isActive
              ? Colors.blue
              : (isComplete ? Colors.green : Colors.grey.shade400),
          width: 2,
        ),
      ),
      child: Center(
        child: isComplete
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class StepConnector extends StatelessWidget {
  final bool isActive;

  const StepConnector({
    Key? key,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 2,
      color: isActive ? Colors.blue : Colors.grey.shade300,
    );
  }
}
