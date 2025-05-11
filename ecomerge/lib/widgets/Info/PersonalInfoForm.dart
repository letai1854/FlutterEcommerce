import 'package:e_commerce_app/widgets/Field/CustomFormField.dart';
import 'package:e_commerce_app/widgets/Field/DateField.dart';
import 'package:e_commerce_app/widgets/Field/GenderSelect.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:path/path.dart' as path;

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
  final VoidCallback onSave;

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
    required this.onSave,
  }) : super(key: key);

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  final UserService _userService = UserService();
  String? _selectedImagePath;
  File? _selectedImageFile;
  Uint8List? _webImageBytes;
  bool _isUploading = false;
  String? avatarUrl;
  Future<Uint8List?>? _serverAvatarFuture;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current user data
    if (UserInfo().currentUser != null) {
      widget.nameController.text = UserInfo().currentUser!.fullName;
      widget.emailController.text = UserInfo().currentUser!.email;
      avatarUrl = UserInfo().currentUser!.avatar;
      _updateServerAvatarFuture();
    }
    UserInfo().addListener(_onUserInfoChanged);
  }

  @override
  void dispose() {
    UserInfo().removeListener(_onUserInfoChanged);
    super.dispose();
  }

  void _onUserInfoChanged() {
    if (mounted) {
      final newAvatarUrlFromInfo = UserInfo().currentUser?.avatar;
      widget.nameController.text =
          UserInfo().currentUser?.fullName ?? widget.nameController.text;
      widget.emailController.text =
          UserInfo().currentUser?.email ?? widget.emailController.text;

      if (newAvatarUrlFromInfo != avatarUrl) {
        avatarUrl = newAvatarUrlFromInfo;
        _updateServerAvatarFuture();
      }
      setState(() {});
    }
  }

  void _updateServerAvatarFuture() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      _serverAvatarFuture = UserService().getAvatarBytes(avatarUrl!);
    } else {
      _serverAvatarFuture = Future.value(null);
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _webImageBytes = result.files.first.bytes;
            _selectedImagePath = result.files.first.name;
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            if (result.files.first.bytes != null) {
              _webImageBytes = result.files.first.bytes;
              _selectedImagePath = result.files.first.name;
            } else if (result.files.first.path != null) {
              _selectedImagePath = result.files.first.path;
              _selectedImageFile = File(_selectedImagePath!);
            }
          });
        }
      }
    } catch (e) {
      print("Image picking error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi chọn ảnh: $e")),
        );
      }
    }
  }

  Future<String?> _uploadSelectedImage() async {
    try {
      if (kIsWeb && _webImageBytes != null) {
        return await _userService.uploadImage(
          _webImageBytes!,
          _selectedImagePath ?? 'web_image.png',
        );
      } else if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final fileName = _selectedImagePath!.split('/').last.split('\\').last;
        return await _userService.uploadImage(bytes, fileName);
      }
      return null;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

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
                    Builder(builder: (context) {
                      if (_webImageBytes != null) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: MemoryImage(_webImageBytes!),
                        );
                      } else if (_selectedImageFile != null) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: FileImage(_selectedImageFile!),
                        );
                      } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
                        return FutureBuilder<Uint8List?>(
                          future: _serverAvatarFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _serverAvatarFuture != null) {
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data != null) {
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: MemoryImage(snapshot.data!),
                              );
                            } else {
                              if (avatarUrl != null && avatarUrl!.isNotEmpty) {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: NetworkImage(avatarUrl!),
                                  onBackgroundImageError: (e, stack) {
                                    print(
                                        "Error loading avatar via NetworkImage: $e");
                                  },
                                );
                              }
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.person,
                                    size: 60, color: Colors.grey),
                              );
                            }
                          },
                        );
                      } else {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person,
                              size: 60, color: Colors.grey),
                        );
                      }
                    }),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: const Text(
                    "Đổi ảnh đại diện",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
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
                    child: TextField(
                      controller: widget.emailController,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Email (không thể thay đổi)",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey[100],
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: UserInfo().currentUser == null
                    ? null
                    : () async {
                        if (UserInfo().currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Bạn cần đăng nhập để thực hiện thao tác này"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => _isUploading = true);

                        try {
                          String? avatarPath;
                          if (_webImageBytes != null ||
                              _selectedImageFile != null) {
                            avatarPath = await _uploadSelectedImage();
                          }

                          final updates = {
                            'fullName': widget.nameController.text,
                          };

                          if (avatarPath != null) {
                            updates['avatar'] = avatarPath;
                          }

                          final updatedUser = await _userService
                              .updateCurrentUserProfile(updates);

                          if (updatedUser != null) {
                            if (avatarPath != null) {
                              UserInfo()
                                  .updateUserProperty('avatar', avatarPath);
                            }
                            UserInfo().updateUserProperty(
                                'fullName', widget.nameController.text);

                            widget.onSave();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Thông tin đã được lưu"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lỗi khi cập nhật thông tin"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print("Error saving profile: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Lỗi: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isUploading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: UserInfo().currentUser == null
                    ? const Text("Đăng nhập để lưu")
                    : const Text("Lưu thay đổi"),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
