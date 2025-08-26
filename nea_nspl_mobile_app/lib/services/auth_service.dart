import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  // Login method
  Future<ApiResponse<User>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      print('Login API Response: $responseData'); // Debug print
      print(
          'Login API Status Code: ${response.statusCode}'); // Additional debug info

      if (response.statusCode == 200) {
        // Try to extract token from different possible response formats
        String? token;

        if (responseData['token'] != null) {
          token = responseData['token'];
        } else if (responseData['accessToken'] != null) {
          token = responseData['accessToken'];
        } else if (responseData['access_token'] != null) {
          token = responseData['access_token'];
        } else if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
          token = responseData['data']['token'];
        }

        // Save token and user data
        if (token != null && token.isNotEmpty) {
          await _storageService.saveToken(token);

          // Try to extract user data from different possible locations
          Map<String, dynamic> userData;

          if (responseData['user'] != null) {
            userData = responseData['user'];
            print('User data found in responseData["user"]');
          } else if (responseData['data'] != null &&
              responseData['data']['user'] != null) {
            userData = responseData['data']['user'];
            print('User data found in responseData["data"]["user"]');
          } else if (responseData['userData'] != null) {
            userData = responseData['userData'];
            print('User data found in responseData["userData"]');
          } else {
            // If no user data is found, create minimal user data
            userData = {
              'id':
                  username, // Use username as ID to ensure it matches assignedTo in tasks
              'username': username,
              'name': 'Field Agent',
              'role': 'Field Agent',
              'status': 'Active'
            };
            print(
                'No user data found in response, created minimal data with ID=$username');
          }

          // Print the user ID we're saving to help debug ID mismatches
          print('Saving user with ID: ${userData['id']}');

          final user = User.fromJson(userData);
          await _storageService.saveUserData(jsonEncode(userData));

          return ApiResponse(
            success: true,
            message: 'Login successful',
            data: user,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: 'Invalid token received',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Check if token is valid and not expired
  Future<bool> isTokenValid() async {
    final token = await _storageService.getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      // Check if token is expired
      bool isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      // Invalid token format
      return false;
    }
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    final userData = await _storageService.getUserData();

    if (userData != null && userData.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        print('Current user ID: ${userMap['id']}');
        return User.fromJson(userMap);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }

    return null;
  }

  // Logout
  Future<bool> logout() async {
    try {
      await _storageService.clearAllData();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Save remember me preference
  Future<void> saveRememberMe(bool remember, String username) async {
    await _storageService.saveRememberMe(remember);
    if (remember) {
      await _storageService.saveUsername(username);
    }
  }

  // Get saved username if remember me is enabled
  Future<String?> getSavedUsername() async {
    final rememberMe = await _storageService.getRememberMe();
    if (rememberMe) {
      return _storageService.getSavedUsername();
    }
    return null;
  }
}
