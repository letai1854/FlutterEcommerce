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

          // Store the bytes for later caching after successful upload
          _webImageBytes = bytes;

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
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      setState(() => _isUploading = true);

                      try {
                        String? avatarPath;
                        Uint8List?
                            uploadedImageBytes; // Track the bytes for caching

                        // Check if we need to attempt image upload
                        bool imageUploadAttempted = _webImageBytes != null ||
                            _selectedImageFile != null;
                        bool imageUploadSucceeded = false;

                        if (imageUploadAttempted) {
                          // Determine which bytes to use
                          if (_webImageBytes != null) {
                            uploadedImageBytes = _webImageBytes;
                          } else if (_selectedImageFile != null) {
                            uploadedImageBytes =
                                await _selectedImageFile!.readAsBytes();
                          }

                          // Upload the image
                          avatarPath = await _uploadSelectedImage();
                          imageUploadSucceeded =
                              avatarPath != null && avatarPath.isNotEmpty;
                          print("Avatar path after upload: $avatarPath");

                          // Show specific error for failed image upload but continue with profile update
                          if (!imageUploadSucceeded && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Ảnh không hợp lệ"),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }

                        final updates = {'fullName': _nameController.text};

                        if (avatarPath != null && avatarPath.isNotEmpty) {
                          updates['avatar'] = avatarPath;
                          print("Adding avatar to updates: $avatarPath");
                        }

                        print("Sending profile update with: $updates");
                        final updatedUser = await _userService
                            .updateCurrentUserProfile(updates);

                        if (updatedUser != null) {
                          print("Profile updated successfully");

                          // Update UserInfo with fullName first
                          UserInfo().updateUserProperty(
                              'fullName', _nameController.text);

                          // Then handle avatar update with proper caching
                          if (avatarPath != null && avatarPath.isNotEmpty) {
                            print(
                                "Updating UserInfo avatar property: $avatarPath");
                            UserInfo().updateUserProperty('avatar', avatarPath);

                            // Critical step: Cache the uploaded image bytes with the new avatarPath
                            if (uploadedImageBytes != null) {
                              UserInfo.avatarCache[avatarPath] =
                                  uploadedImageBytes;
                              print(
                                  'Manually cached new avatar bytes for $avatarPath in UserInfo.avatarCache');
                            }
                          }

                          // Save complete user to persistent storage
                          await UserInfo()
                              .saveCompleteUserToPersistentStorage();
                          print(
                              "Saved complete user data to persistent storage");

                          widget.onSave(
                              _nameController.text,
                              _emailController.text,
                              _phoneController.text,
                              _gender,
                              _birthDate);

                          // Determine success message based on whether image upload was attempted and successful
                          String successMessage = imageUploadAttempted
                              ? (imageUploadSucceeded
                                  ? "Thông tin và ảnh đại diện đã được cập nhật"
                                  : "Thông tin đã được lưu, nhưng ảnh đại diện không hợp lệ")
                              : "Thông tin đã được lưu";

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(successMessage),
                                  )
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Delay navigation to ensure user sees the success message
                          await Future.delayed(Duration(milliseconds: 800));
                          if (mounted) {
                            Navigator.pop(context);
                          }
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
                            duration: Duration(seconds: 3),
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
