import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/ticket.dart';
import 'storage_service.dart';

class TicketService {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();

  // Get authorization header
  Future<Map<String, String>> _getAuthHeader() async {
    final token = await _storageService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Get all tickets with improved error handling
  Future<ApiResponse<List<Ticket>>> getTickets() async {
    try {
      final headers = await _getAuthHeader();
      final token = await _storageService.getToken();
      final userData = await _storageService.getUserData();

      // Print debug info
      print('Using token: $token');
      String? userId;
      if (userData != null) {
        final user = jsonDecode(userData);
        userId = user['id'];
        print('Fetching tickets for user ID: $userId');
      }

      // Add query parameter for user ID to help debug
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tasks}')
          .replace(queryParameters: userId != null ? {'userId': userId} : null);

      print('Task API Request URL: $uri');
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Task API Response status: ${response.statusCode}');

      // Check for empty response
      if (response.body.isEmpty) {
        print('Task API returned empty response body');
        return ApiResponse(
          success: false,
          message: 'Server returned empty response',
          statusCode: response.statusCode,
        );
      }

      // Try to parse the response, with error handling
      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
        print('Task API Raw response: $responseData');
      } catch (e) {
        print('Failed to parse response JSON: $e');
        print('Raw response body: ${response.body}');
        return ApiResponse(
          success: false,
          message: 'Invalid server response format',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 200) {
        List<dynamic> ticketsJson = [];

        // Handle different possible response formats
        if (responseData['data'] != null && responseData['data'] is List) {
          ticketsJson = responseData['data'];
          print(
              'Found tickets in responseData["data"], count: ${ticketsJson.length}');
        } else if (responseData['tasks'] != null &&
            responseData['tasks'] is List) {
          ticketsJson = responseData['tasks'];
          print(
              'Found tickets in responseData["tasks"], count: ${ticketsJson.length}');
        } else if (responseData is List) {
          ticketsJson = responseData;
          print(
              'Found tickets in direct response list, count: ${ticketsJson.length}');
        } else if (responseData['data'] != null &&
            responseData['data']['tasks'] != null &&
            responseData['data']['tasks'] is List) {
          // Additional format check
          ticketsJson = responseData['data']['tasks'];
          print(
              'Found tickets in responseData["data"]["tasks"], count: ${ticketsJson.length}');
        } else if (responseData['data'] != null &&
            responseData['data']['items'] != null &&
            responseData['data']['items'] is List) {
          // Additional format check
          ticketsJson = responseData['data']['items'];
          print(
              'Found tickets in responseData["data"]["items"], count: ${ticketsJson.length}');
        } else {
          print('Could not find tickets in any expected response format');
        }

        print('Processing ${ticketsJson.length} tickets...');
        final List<Ticket> tickets = [];

        for (var json in ticketsJson) {
          try {
            // Print assignedTo field for comparison with user ID
            print('Ticket assigned to: ${json['assignedTo']}');
            tickets.add(Ticket.fromJson(json));
          } catch (e) {
            print('Error parsing ticket: $e');
            print('Problematic ticket JSON: $json');
          }
        }

        return ApiResponse(
          success: true,
          message: 'Tickets retrieved successfully',
          data: tickets,
          statusCode: response.statusCode,
        );
      } else {
        // For debugging - capture API error details
        String errorDetails = '';
        try {
          if (responseData['error'] != null) {
            errorDetails = responseData['error'].toString();
          } else if (responseData['message'] != null) {
            errorDetails = responseData['message'].toString();
          }
        } catch (e) {
          errorDetails = 'Could not parse error details';
        }

        print('Task API Error Details: $errorDetails');

        return ApiResponse(
          success: false,
          message: responseData['message'] ??
              'Failed to retrieve tickets: $errorDetails',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Task API Exception: ${e.toString()}');
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get ticket by ID
  Future<ApiResponse<Ticket>> getTicketById(String ticketId) async {
    try {
      final headers = await _getAuthHeader();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.taskDetail}$ticketId'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Handle different possible response formats
        Map<String, dynamic> ticketJson;
        if (responseData['data'] != null && responseData['data'] is Map) {
          ticketJson = responseData['data'];
        } else if (responseData['task'] != null &&
            responseData['task'] is Map) {
          ticketJson = responseData['task'];
        } else if (responseData is Map && responseData.containsKey('id')) {
          ticketJson = Map<String, dynamic>.from(responseData);
        } else {
          return ApiResponse(
            success: false,
            message: 'Invalid ticket data format in response',
            statusCode: response.statusCode,
          );
        }

        final ticket = Ticket.fromJson(ticketJson);

        return ApiResponse(
          success: true,
          message: 'Ticket retrieved successfully',
          data: ticket,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to retrieve ticket',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Task API Exception: ${e.toString()}');
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Complete a ticket with form data and photos
  Future<ApiResponse<bool>> completeTicket(
      String ticketId, Map<String, dynamic> formData, List<File> photos) async {
    try {
      final token = await _storageService.getToken();

      // Create FormData object for multipart request
      var dioFormData = FormData();

      // Add all form fields
      formData.forEach((key, value) {
        dioFormData.fields.add(MapEntry(key, value.toString()));
      });

      // Add photos
      for (var i = 0; i < photos.length; i++) {
        final file = photos[i];
        final fileName = 'photo_${i + 1}.jpg';

        dioFormData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      // Configure Dio with token
      _dio.options.headers = {
        'Authorization': 'Bearer $token',
      };

      // Make the request
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.completeTask}$ticketId/complete',
        data: dioFormData,
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Ticket completed successfully',
          data: true,
          statusCode: response.statusCode ?? 200,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to complete ticket',
          statusCode: response.statusCode ?? 400,
        );
      }
    } catch (e) {
      print('Task API Exception: ${e.toString()}');
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
