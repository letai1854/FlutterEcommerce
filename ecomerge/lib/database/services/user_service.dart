import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:e_commerce_app/database/services/address_service.dart';
import 'package:e_commerce_app/database/services/cart_service.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/user_model.dart';
import '/database/database_helper.dart';
import '../database_helper.dart' as config;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  final String baseUrl = baseurl;
  String? _authToken;
  late final http.Client httpClient;
  static final Map<String, Uint8List> _imageCache = {};

  // Constants for secure storage
  static const String _CREDENTIALS_KEY = 'encrypted_credentials';
  static const String _ENCRYPTION_KEY =
      'shopii_secret_key_12345678901234567890123456789012'; // 32-char key

  // Constructor - setup SSL-bypassing client for all platforms
  UserService() {
    httpClient = _createSecureClient();
  }

  // Create a client that bypasses SSL certificate verification
  http.Client _createSecureClient() {
    if (kIsWeb) {
      // Web platform doesn't need special handling
      return http.Client();
    } else {
      // For mobile and desktop platforms
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  // Static cache reference
  static Map<String, Uint8List> get avatarCache => UserInfo.avatarCache;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    final userInfo = UserInfo();
    if (includeAuth && userInfo.authToken != null) {
      headers['Authorization'] = 'Bearer ${userInfo.authToken}';
    }

    return headers;
  }

  // Method to register a new user
  Future<bool?> registerUser({
    required String email,
    required String fullName,
    required String password,
    required String address,
  }) async {
    final url = Uri.parse('$baseurl/api/users/register');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'password': password,
          'address': address,
        }),
      );

      if (response.statusCode == 201) {
        User.fromMap(jsonDecode(response.body));
        return true;
      } else {
        print('Failed to register user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during user registration: $e');
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  // Enhanced register guest user to always update local credentials
  Future<bool> registerGuestUser(String email) async {
    try {
      // Generate random username: "user" + 4 random digits
      final random = Random();
      final randomDigits = List.generate(4, (_) => random.nextInt(10)).join();
      final fullName = 'user$randomDigits';

      // Generate random 6-digit password
      final password = List.generate(6, (_) => random.nextInt(10)).join();

      // Register the user with a default address instead of empty string
      final registrationSuccess = await registerUser(
        email: email,
        fullName: fullName,
        password: password,
        address: 'null', // Add a non-empty default address here
      );

      if (registrationSuccess ?? false) {
        // Always save credentials locally, overwriting any existing ones
        if (!kIsWeb) {
          await _saveCredentials(email, password);
          print('Saved guest user credentials in local storage');
        }

        // Log in the user automatically
        final loginSuccess = await loginUser(email, password);

        if (loginSuccess) {
          print('Guest user registered and logged in successfully: $fullName');

          // Now we can delete the "null" address since we have authentication token
          // try {
          //   // Get address service instance
          //   final addressService = AddressService();

          //   // Get all user addresses
          //   final addresses = await addressService.getUserAddresses();

          //   // Find and delete any null addresses
          //   for (final address in addresses) {
          //     if (address.address == "null" && address.id != null) {
          //       print("Deleting auto-generated null address: ${address.id}");
          //       await addressService.deleteAddress(address.id!);
          //     }
          //   }

          //   print("Completed cleanup of null addresses");
          // } catch (e) {
          //   // Just log the error but don't fail the registration
          //   print("Error cleaning up null addresses: $e");
          // }

          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error registering guest user: $e');
      return false;
    }
  }

  // Modified to always save credentials, overwriting any existing ones
  Future<void> _saveCredentials(String email, String password) async {
    try {
      // Skip on web platforms
      if (kIsWeb) {
        print('Credentials saving skipped on web platform');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Create credential map
      final credentials = {
        'email': email,
        'password': password,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Convert to JSON
      final credentialsJson = jsonEncode(credentials);

      // Encrypt the credentials
      final encryptedCredentials = _encryptData(credentialsJson);

      // Save to SharedPreferences - always overwrite any existing credentials
      await prefs.setString(_CREDENTIALS_KEY, encryptedCredentials);

      print('Credentials saved or updated in local storage');
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Encrypt data using AES encryption
  String _encryptData(String data) {
    try {
      // Use key from bytes to ensure exact length
      final key = encrypt.Key.fromUtf8(_ENCRYPTION_KEY);
      final iv = encrypt.IV.fromLength(16); // Generate a random IV
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encrypt(data, iv: iv);
      return '${encrypted.base64}|${iv.base64}'; // Store both encrypted data and IV
    } catch (e) {
      print('Encryption error: $e');
      // Fallback to a simpler storage method if encryption fails
      return base64.encode(utf8.encode(data));
    }
  }

  // Decrypt data using AES encryption
  String? _decryptData(String encryptedData) {
    try {
      if (!encryptedData.contains('|')) {
        // Handle legacy or fallback format
        return utf8.decode(base64.decode(encryptedData));
      }

      final parts = encryptedData.split('|');
      if (parts.length != 2) return null;

      final encryptedText = parts[0];
      final ivText = parts[1];

      final key = encrypt.Key.fromUtf8(_ENCRYPTION_KEY);
      final iv = encrypt.IV.fromBase64(ivText);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedText),
        iv: iv,
      );

      return decrypted;
    } catch (e) {
      print('Error decrypting data: $e');
      return null;
    }
  }

  // Check for stored credentials and auto-login
  Future<bool> attemptAutoLogin() async {
    try {
      // Skip on web platforms
      if (kIsWeb) {
        print('Auto-login skipped on web platform');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final encryptedCredentials = prefs.getString(_CREDENTIALS_KEY);

      if (encryptedCredentials == null) {
        print('No stored credentials found');
        return false;
      }

      // Decrypt the credentials
      final decryptedJson = _decryptData(encryptedCredentials);
      if (decryptedJson == null) {
        print('Failed to decrypt credentials');
        return false;
      }

      // Parse JSON
      final credentials = jsonDecode(decryptedJson);
      final email = credentials['email'];
      final password = credentials['password'];

      // Check if credentials exist
      if (email == null || password == null) {
        print('Invalid credentials format');
        return false;
      }

      print('Attempting auto-login with stored credentials');
      // Attempt login
      return await loginUser(email, password);
    } catch (e) {
      print('Error during auto-login: $e');
      return false;
    }
  }

  // Clear stored credentials (e.g., on manual logout)
  Future<void> clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_CREDENTIALS_KEY);
      print('Stored credentials cleared');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  // Enhanced login method to always update stored credentials
  Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/users/login');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        setAuthToken(responseBody['token']);
        UserInfo().updateUserInfo(responseBody);

        // Call saveCompleteUserToPersistentStorage after updating user info
        // await UserInfo().saveCompleteUserToPersistentStorage();

        print(
            "User logged in successfully--------------------: ${UserInfo().currentUser?.role}");
        String? avatarPath = UserInfo().currentUser?.avatar;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          String fullAvatarUrl = getImageUrl(avatarPath);
          print('Pre-caching avatar from: $fullAvatarUrl');
          await _cacheAvatarImage(fullAvatarUrl, avatarPath);
        } else {
          print('User has no avatar to cache');
        }

        // For Windows and mobile platforms, save credentials for auto-login
        // Always overwrite existing credentials with the new login
        if (!kIsWeb) {
          await UserInfo().saveCompleteUserToPersistentStorage();

          await _saveCredentials(email, password);
          print('Updated stored credentials after successful login');
        }

        print('Login successful: ${UserInfo().authToken}');
        return true;
      } else {
        print('Failed to login user: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Đăng nhập thất bại');
      return false;
    }
  }

  // Enhanced logout method to clear stored credentials and call server endpoint
  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/api/users/logout');
    try {
      // Attempt to call the server's logout endpoint
      // This is often a good practice, even if JWT is stateless on the client,
      // the server might perform some logging or cleanup.
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true), // Send auth token if available
      );

      if (response.statusCode == 200) {
        print('Successfully logged out on server.');
      } else {
        print(
            'Server logout endpoint call failed: ${response.statusCode} ${response.body}');
        // Continue with local logout procedures regardless of server response
      }
    } catch (e) {
      print('Error calling server logout endpoint: $e');
      // Continue with local logout procedures regardless of server error
    }

    // Perform local logout operations
    setAuthToken(null);
    UserInfo().clearUserInfo();
    UserService.clearAvatarCache(); // Clear avatar cache on logout
    
    // Clear cart data
    await CartStorage().clearAllCart();
    
    // Clear order data
    final orderService = OrderService();
    await orderService.clearLocalOrderCache();

    // Clear stored credentials on logout for non-web platforms
    if (!kIsWeb) {
      await clearStoredCredentials();
      print('Cleared stored credentials during logout');
    }
    print('Local logout completed.');
  }

  // Helper method to fetch and cache avatar image
  Future<void> _cacheAvatarImage(String imageUrl, String avatarKey) async {
    try {
      final response = await httpClient.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        UserInfo.avatarCache[avatarKey] = response.bodyBytes;
        print(
            'Avatar cached successfully, size: ${response.bodyBytes.length} bytes');
      } else {
        print('Failed to fetch avatar image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error caching avatar image: $e');
    }
  }

  // Method to get cached avatar or fetch if not available
  Future<Uint8List?> getAvatarBytes(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;

    if (UserInfo.avatarCache.containsKey(avatarPath)) {
      return UserInfo.avatarCache[avatarPath];
    }

    try {
      String fullUrl = getImageUrl(avatarPath);
      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        UserInfo.avatarCache[avatarPath] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching avatar: $e');
    }

    return null;
  }

  // Helper method to clear avatar cache
  static void clearAvatarCache() {
    UserInfo.avatarCache.clear();
  }

  // Method to get current authenticated user's profile
  Future<User?> getCurrentUserProfile() async {
    final url = Uri.parse('$baseUrl/api/users/me');
    try {
      final response = await httpClient.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        print('Failed to get user profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Method to update current authenticated user's profile
  Future<User?> updateCurrentUserProfile(Map<String, dynamic> updates) async {
    final url = Uri.parse('$baseUrl/api/users/me/update');
    try {
      final response = await httpClient.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        print('Failed to update user profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  Future<bool> changeCurrentUserPassword(
      String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/me/change-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(
            {'oldPassword': oldPassword, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        if (!kIsWeb) {
          final userEmail = UserInfo().currentUser?.email;
          if (userEmail != null) {
            // Always update credentials with the new password
            await _saveCredentials(userEmail, newPassword);
            print('Updated stored credentials with new password');
          }
        }
        return true;
      } else {
        print('Failed to change password: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/api/users/forgot-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (kDebugMode) {
        print('Forgot Password request URL: $url');
        print('Forgot Password request Body: ${jsonEncode({'email': email})}');
        print('Forgot Password response status: ${response.statusCode}');
        print('Forgot Password response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return;
      } else {
        // API trả về lỗi (status code != 200)
        String errorMessage = 'Không thể yêu cầu mã xác thực.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {} // Ignore parsing error, use default message

        if (kDebugMode) {
          print(
              'API Error during forgot password request: ${response.statusCode}, Message: $errorMessage');
        }
        throw Exception(
            errorMessage); // Ném Exception với thông báo lỗi từ backend
      }
    } catch (e) {
      // Lỗi mạng
      if (kDebugMode)
        print('SocketException during forgot password request: $e');
      throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.'); // Ném Exception mạng
    }
  }

  // Bước 2: Xác thực mã OTP
  // Ném Exception nếu API trả về lỗi (status code != 200) hoặc lỗi mạng
  Future<void> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/api/users/verify-otp');
    try {
      final response = await httpClient.post(
        // Sửa thành _httpClient
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (kDebugMode) {
        print('Verify OTP request URL: $url');
        print('Verify OTP request Body: ${jsonEncode({
              'email': email,
              'otp': otp
            })}');
        print('Verify OTP response status: ${response.statusCode}');
        print('Verify OTP response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Thành công
        return; // Return void on success
      } else {
        // API trả về lỗi (status code != 200)
        String errorMessage = 'Mã xác thực không hợp lệ hoặc đã hết hạn.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}

        if (kDebugMode) {
          print(
              'API Error during OTP verification: ${response.statusCode}, Message: $errorMessage');
        }
        throw Exception(errorMessage); // Ném Exception
      }
    } catch (e) {
      if (kDebugMode) print('SocketException during OTP verification: $e');
      throw Exception(
          'Mã xác thực không hợp lệ hoặc đã hết hạn.'); // Ném Exception mạng
    }
  }

  // Bước 3: Đặt mật khẩu mới
  // Ném Exception nếu API trả về lỗi (status code != 200) hoặc lỗi mạng
  Future<void> setNewPassword(
      String email, String otp, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/set-new-password');
    try {
      final response = await httpClient.post(
        // Sửa thành _httpClient
        url,
        headers: _getHeaders(),
        body: jsonEncode(
            {'email': email, 'otp': otp, 'newPassword': newPassword}),
      );

      if (kDebugMode) {
        print('Set New Password request URL: $url');
        // Không in mật khẩu mới
        print('Set New Password request Body (partial): ${jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': '...'
            })}');
        print('Set New Password response status: ${response.statusCode}');
        print('Set New Password response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Thành công
        return; // Return void on success
      } else {
        // API trả về lỗi (status code != 200)
        String errorMessage = 'Không thể đặt mật khẩu mới.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          } else if (errorBody is String && errorBody.isNotEmpty) {
            errorMessage = errorBody;
          }
        } catch (_) {}

        if (kDebugMode) {
          print(
              'API Error during set new password: ${response.statusCode}, Message: $errorMessage');
        }
        throw Exception(errorMessage); // Ném Exception
      }
    } catch (e) {
      if (kDebugMode) print('SocketException during set new password: $e');
      throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.'); // Ném Exception mạng
    }
  }

  // Modified to update stored credentials during password reset
  Future<bool> resetPassword(
      String email, String code, String newPassword) async {
    final url = Uri.parse('$baseUrl/api/users/reset-password');
    try {
      final response = await httpClient.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'verificationCode': code,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('Password reset successfully');

        // For non-web platforms, update stored credentials
        if (!kIsWeb) {
          // Always update credentials with the new password
          await _saveCredentials(email, newPassword);
          print('Updated stored credentials after password reset');
        }

        return true;
      } else {
        print('Failed to reset password: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  Future<String?> uploadImage(List<int> imageBytes, String fileName) async {
    final url = Uri.parse('$baseUrl/api/images/upload');
    print(
        "Starting image upload, bytes: ${imageBytes.length}, filename: $fileName");

    try {
      // Create a multipart request
      final request = http.MultipartRequest('POST', url);

      // Add authorization header if user is logged in
      if (UserInfo().authToken != null) {
        request.headers['Authorization'] = 'Bearer ${UserInfo().authToken}';
      }

      // Add file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Important fix: Instead of using request.send(), which uses the default client,
      // we'll manually send the request using our SSL-bypassing client
      final stream = await request.finalize();

      // Create a custom request with the same method, url, headers
      final httpRequest = http.Request(request.method, request.url);
      httpRequest.headers.addAll(request.headers);
      httpRequest.bodyBytes = await stream.toBytes();

      // Send the request using our secure client
      final streamedResponse = await httpClient.send(httpRequest);

      // Convert the response stream to a regular response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Parse the response to get the image path
        final responseData = jsonDecode(response.body);
        final imagePath = responseData['imagePath'];
        print('Image uploaded successfully: $imagePath');
        return imagePath;
      } else {
        print('Failed to upload image: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to upload image from file path (for mobile platforms)
  Future<String?> uploadImageFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      return uploadImage(bytes, fileName);
    } catch (e) {
      print('Error reading image file: $e');
      return null;
    }
  }

  // Helper method to get the complete image URL
  String getImageUrl(String? imagePath) {
    if (imagePath == null) return '';

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$path';
  }

  // Method to update user's avatar
  Future<bool> updateUserAvatar(String filePath) async {
    try {
      final imagePath = await uploadImageFile(filePath);

      if (imagePath != null) {
        final updatedUser =
            await updateCurrentUserProfile({'avatar': imagePath});

        if (updatedUser != null) {
          UserInfo().currentUser?.avatar = imagePath;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating user avatar: $e');
      return false;
    }
  }

  Future<Uint8List?> getImageFromServer(String? imagePath,
      {bool forceReload = false}) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    // Check cache only if not forcing reload
    if (!forceReload) {
      // First check our product-specific image cache
      if (_imageCache.containsKey(imagePath)) {
        if (kDebugMode) print('Using cached image for $imagePath');
        return _imageCache[imagePath];
      }

      // Then check UserInfo avatar cache (existing implementation)
      if (UserInfo.avatarCache.containsKey(imagePath)) {
        return UserInfo.avatarCache[imagePath];
      }
    }

    try {
      String fullUrl = getImageUrl(imagePath);
      // Add cache-busting parameter for forceReload
      if (forceReload) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        fullUrl += '?cacheBust=$cacheBuster';
      }

      final response = await httpClient.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        // Cache the image unless we're forcing reload
        if (!forceReload) {
          // Cache in both places for maximum compatibility
          _imageCache[imagePath] = response.bodyBytes;
          UserInfo.avatarCache[imagePath] = response.bodyBytes;
        }
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error fetching image: $e');
    }

    return null;
  }

  // Method to efficiently get avatar from cache or server for any user object
  Future<Uint8List?> getUserAvatar(String? avatarPath,
      {bool forceReload = false}) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;

    // Check in the class-level cache first if not forcing reload
    if (!forceReload) {
      // First check our image cache
      if (_imageCache.containsKey(avatarPath)) {
        if (kDebugMode) print('Using cached user avatar for $avatarPath');
        return _imageCache[avatarPath];
      }

      // Then check UserInfo avatar cache as fallback
      if (UserInfo.avatarCache.containsKey(avatarPath)) {
        return UserInfo.avatarCache[avatarPath];
      }
    }

    try {
      // If not found in cache or forcing reload, fetch from server
      final imageBytes =
          await getImageFromServer(avatarPath, forceReload: forceReload);

      // Cache the result if successfully fetched and not forcing reload
      if (imageBytes != null && !forceReload) {
        _imageCache[avatarPath] = imageBytes;
        UserInfo.avatarCache[avatarPath] =
            imageBytes; // Keep both caches in sync
      }

      return imageBytes;
    } catch (e) {
      print('Error fetching user avatar: $e');
      return null;
    }
  }

  // Helper method to clear avatar caches when needed
  static void clearUserAvatarCache() {
    _imageCache.clear();
    UserInfo.avatarCache.clear();
  }

  // TODO: Implement methods for admin endpoints if needed
}
