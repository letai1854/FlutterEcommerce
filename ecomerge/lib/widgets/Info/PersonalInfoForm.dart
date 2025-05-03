import 'package:e_commerce_app/widgets/Field/CustomFormField.dart';
import 'package:e_commerce_app/widgets/Field/DateField.dart';
import 'package:e_commerce_app/widgets/Field/GenderSelect.dart';
import 'package:flutter/material.dart';

class PersonalInfoForm extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String birthDate;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Function(String) onNameChanged;
  final Function(String) onEmailChanged;
  final Function(String) onPhoneChanged;
  final Function(String) onGenderChanged;
  final Function(String) onBirthDateChanged;

  const PersonalInfoForm({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthDate,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onGenderChanged,
    required this.onBirthDateChanged,
  }) : super(key: key);

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Hồ sơ của tôi",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Quản lý thông tin hồ sơ để bảo mật",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Đổi ảnh đại diện"),
              ],
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Personal info form
        Container(
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      label: "Họ và tên",
                      controller: widget.nameController,
                      onChanged: widget.onNameChanged,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildCustomTextField(
                      label: "Email",
                      controller: widget.emailController,
                      onChanged: widget.onEmailChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      label: "Số điện thoại",
                      controller: widget.phoneController,
                      onChanged: widget.onPhoneChanged,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: GenderSelect(
                      initialValue: widget.gender,
                      onChanged: widget.onGenderChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DateField(
                label: "Ngày sinh",
                initialValue: widget.birthDate,
                onChanged: widget.onBirthDateChanged,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Save changes logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Thông tin đã được lưu"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text("Lưu thay đổi"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Custom text field with controller
  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }
}
