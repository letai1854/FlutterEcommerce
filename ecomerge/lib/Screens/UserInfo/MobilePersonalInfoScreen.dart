import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MobilePersonalInfoScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialGender;
  final String initialBirthDate;
  final Function(String, String, String, String, String) onSave;

  const MobilePersonalInfoScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialGender,
    required this.initialBirthDate,
    required this.onSave,
  }) : super(key: key);

  @override
  State<MobilePersonalInfoScreen> createState() =>
      _MobilePersonalInfoScreenState();
}

class _MobilePersonalInfoScreenState extends State<MobilePersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _gender;
  late String _birthDate;
  final _formKey = GlobalKey<FormState>();

  final UserService _userService = UserService();
  String? _selectedImagePath;
  File? _selectedImageFile;
  Uint8List? _webImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _gender = widget.initialGender;
    _birthDate = widget.initialBirthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
            print(
                "Web image selected: ${result.files.first.name}, size: ${_webImageBytes?.length} bytes");
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
              print("Got bytes directly from FilePicker");
              _webImageBytes = result.files.first.bytes;
              _selectedImagePath = result.files.first.name;
              _selectedImageFile = null;
            } else if (result.files.first.path != null) {
              print(
                  "Got file path from FilePicker: ${result.files.first.path}");
              _selectedImagePath = result.files.first.path;
              _selectedImageFile = File(_selectedImagePath!);
              _webImageBytes = null;
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
      print(
          "Web bytes: ${_webImageBytes != null ? 'Present (${_webImageBytes!.length} bytes)' : 'Null'}");
      print(
          "Selected file: ${_selectedImageFile != null ? 'Present (${_selectedImageFile!.path})' : 'Null'}");
      print("Selected path: $_selectedImagePath");

      if (kIsWeb && _webImageBytes != null) {
        print("Uploading as web image...");
        return await _userService.uploadImage(
          _webImageBytes!,
          _selectedImagePath ?? 'web_image.png',
        );
      } else if (_selectedImageFile != null) {
        print("Uploading as mobile/desktop file...");
        try {
          final bytes = await _selectedImageFile!.readAsBytes();
          print("File read successfully, size: ${bytes.length} bytes");

          String fileName = "mobile_image.jpg";
          if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
            try {
              fileName = _selectedImagePath!.split('/').last.split('\\').last;
            } catch (e) {
              print("Error extracting filename: $e, using default");
            }
          }

          print("Uploading with filename: $fileName");

          return await _userService
              .uploadImage(bytes, fileName)
              .timeout(Duration(seconds: 20), onTimeout: () {
            print("Image upload timed out");
            return null;
          });
        } catch (e) {
          print("Error preparing file for upload: $e");
          return null;
        }
      } else if (_webImageBytes != null) {
        print("Non-web platform but have web bytes, uploading...");
        return await _userService.uploadImage(
          _webImageBytes!,
          _selectedImagePath ?? 'mobile_image.jpg',
        );
      }

      print("No image data available to upload");
      return null;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = UserInfo().currentUser?.avatar;

    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin cá nhân", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Builder(builder: (context) {
                      if (_webImageBytes != null) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundImage: MemoryImage(_webImageBytes!),
                        );
                      } else if (_selectedImageFile != null) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(_selectedImageFile!),
                        );
                      } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        return FutureBuilder<Uint8List?>(
                          future: UserService().getAvatarBytes(avatarUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                backgroundImage: MemoryImage(snapshot.data!),
                              );
                            } else {
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: NetworkImage(avatarUrl),
                                onBackgroundImageError: (_, __) {},
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
                const SizedBox(height: 32),
                _buildFormField(
                  label: "Họ và tên",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                _buildFormField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    } else if (!value.contains('@') || !value.contains('.')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isUploading = true);

                      try {
                        String? avatarPath;
                        if (_webImageBytes != null ||
                            _selectedImageFile != null) {
                          avatarPath = await _uploadSelectedImage();
                          print("Avatar path after upload: $avatarPath");
                        }

                        final updates = {'fullName': _nameController.text};

                        if (avatarPath != null && avatarPath.isNotEmpty) {
                          updates['avatar'] = avatarPath;
                          print("Adding avatar to updates: $avatarPath");
                        } else {
                          print(
                              "Not updating avatar: avatarPath is null or empty");
                        }

                        print("Sending profile update with: $updates");
                        final updatedUser = await _userService
                            .updateCurrentUserProfile(updates);

                        if (updatedUser != null) {
                          print("Profile updated successfully");

                          if (avatarPath != null && avatarPath.isNotEmpty) {
                            print("Updating UserInfo avatar property");
                            UserInfo().updateUserProperty('avatar', avatarPath);
                          } else {
                            print(
                                "Not updating UserInfo avatar: null or empty path");
                          }

                          print("Updating UserInfo fullName property");
                          UserInfo().updateUserProperty(
                              'fullName', _nameController.text);

                          widget.onSave(
                              _nameController.text,
                              _emailController.text,
                              _phoneController.text,
                              _gender,
                              _birthDate);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Thông tin đã được lưu"),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lỗi khi cập nhật thông tin"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        print("Error saving profile: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Lỗi: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isUploading = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Lưu thay đổi",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            enabled: enabled,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              filled: readOnly ? true : false,
              fillColor: readOnly ? Colors.grey[100] : null,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
