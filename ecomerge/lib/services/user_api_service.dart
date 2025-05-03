import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/services/api_service.dart';

class UserApiService {
  final ApiService _apiService = ApiService();
  final String _endpoint = '/users'; // User specific endpoint base

  Future<User> registerUser(Map<String, dynamic> userData) async {
    try {
      final responseData = await _apiService.post('$_endpoint/register', userData);
      return User.fromJson(responseData);
    } on ApiException catch (e) {
       // Rethrow specific exceptions based on status code or message if needed
       // Or just rethrow the original exception
       rethrow;
    } catch (e) {
      // Handle unexpected errors during the API call itself (e.g., network issues)
      print('Unexpected registration error: $e');
      throw Exception('Đăng ký thất bại do lỗi không xác định.');
    }
  }

  Future<User> loginUser(String email, String password) async {
     try {
        final responseData = await _apiService.post('$_endpoint/login', {
          'email': email,
          'password': password,
        });
        return User.fromJson(responseData);
     } on ApiException catch (e) {
        rethrow; // Let the controller handle specific API errors
     } catch (e) {
        print('Unexpected login error: $e');
        throw Exception('Đăng nhập thất bại do lỗi không xác định.');
     }
  }

  Future<User> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      final responseData = await _apiService.put('$_endpoint/$userId', updateData);
       // Assuming the API returns the updated user object on PUT success
       // If it returns just status 200/204, you might need to adjust this
       if (responseData.isEmpty) {
         // Handle cases where PUT might return 204 No Content
         // You might need to fetch the user again or return a modified local object
         // For now, let's assume it returns the updated user
         throw Exception('Cập nhật thành công nhưng không nhận được dữ liệu người dùng trả về.');
       }
      return User.fromJson(responseData);
    } on ApiException catch (e) {
       rethrow;
    } catch (e) {
       print('Unexpected update error: $e');
       throw Exception('Cập nhật thất bại do lỗi không xác định.');
    }
  }

  // Add other user-related API calls here (e.g., getUser, deleteUser)
}
