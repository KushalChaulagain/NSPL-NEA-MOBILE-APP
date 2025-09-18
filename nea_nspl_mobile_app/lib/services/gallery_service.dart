import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/gallery_image.dart';
import 'storage_service.dart';

class GalleryService {
  final StorageService _storageService = StorageService();

  // Get authorization header
  Future<Map<String, String>> _getAuthHeader() async {
    final token = await _storageService.getToken();
    final userData = await _storageService.getUserData();

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Add user role header if available
    if (userData != null && userData.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        if (userMap['role'] != null) {
          headers['x-user-role'] = userMap['role'];
        }
      } catch (e) {
        print('Error parsing user data for role: $e');
      }
    }

    return headers;
  }

  // Get all images from admin gallery API
  Future<ApiResponse<List<GalleryImage>>> getAllImages({
    int page = 1,
    int limit = 50,
    String? search,
    String? fieldAgent,
    String? region,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final headers = await _getAuthHeader();

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (fieldAgent != null && fieldAgent.isNotEmpty) {
        queryParams['fieldAgent'] = fieldAgent;
      }
      if (region != null && region.isNotEmpty) {
        queryParams['region'] = region;
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.galleryImages}')
          .replace(queryParameters: queryParams);

      print('Gallery API Request URL: $uri');
      final response = await http.get(uri, headers: headers);

      print('Gallery API Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return ApiResponse(
          success: false,
          message: 'Failed to fetch images from gallery',
          statusCode: response.statusCode,
        );
      }

      final responseData = jsonDecode(response.body);

      if (!responseData['success']) {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch images',
          statusCode: response.statusCode,
        );
      }

      List<dynamic> imagesJson = [];
      if (responseData['data'] != null &&
          responseData['data']['items'] != null) {
        imagesJson = responseData['data']['items'];
      }

      List<GalleryImage> allImages = [];

      for (var imageJson in imagesJson) {
        try {
          // Transform API response to GalleryImage format
          final galleryImage = GalleryImage(
            id: imageJson['id'] ?? '',
            taskId: imageJson['task']?['taskId'] ?? '',
            taskTitle: imageJson['task']?['site'] ?? 'Unknown Site',
            meterNumber: imageJson['task']?['region'] ?? 'Unknown Region',
            fieldAgentName: imageJson['fieldAgent']?['name'] ?? 'Unknown Agent',
            fieldAgentId: imageJson['fieldAgent']?['username'] ?? '',
            uploadedAt: DateTime.parse(imageJson['uploadedAt']),
            fileName: imageJson['name'] ?? 'image.jpg',
            fileSize: imageJson['size']?.toString() ?? '0',
            mimeType: imageJson['type'] ?? 'image/jpeg',
          );

          allImages.add(galleryImage);
        } catch (e) {
          print('Error parsing image: $e');
          continue;
        }
      }

      return ApiResponse(
        success: true,
        message: 'Images retrieved successfully',
        data: allImages,
        statusCode: 200,
      );
    } catch (e) {
      print('Gallery Service Exception: ${e.toString()}');
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get signed URL for an image (legacy single request method)
  Future<ApiResponse<String>> getImageSignedUrl(String imageId) async {
    try {
      final headers = await _getAuthHeader();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attachmentUrl}$imageId/url'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Try multiple possible response structures
        String? signedUrl;

        // Check for nested data structure: {"success": true, "data": {"url": "..."}}
        if (responseData['data'] != null &&
            responseData['data']['url'] != null) {
          signedUrl = responseData['data']['url'];
        }
        // Check for direct structure: {"url": "..."}
        else if (responseData['url'] != null) {
          signedUrl = responseData['url'];
        }
        // Check for signedUrl field: {"signedUrl": "..."}
        else if (responseData['signedUrl'] != null) {
          signedUrl = responseData['signedUrl'];
        }
        // Check for nested signedUrl: {"data": {"signedUrl": "..."}}
        else if (responseData['data'] != null &&
            responseData['data']['signedUrl'] != null) {
          signedUrl = responseData['data']['signedUrl'];
        }

        if (signedUrl != null) {
          return ApiResponse(
            success: true,
            message: 'Signed URL retrieved successfully',
            data: signedUrl,
            statusCode: 200,
          );
        } else {
          return ApiResponse(
            success: false,
            message: 'No signed URL in response',
            statusCode: 200,
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to retrieve signed URL',
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

  // Get signed URLs for multiple images in a single batch request
  Future<ApiResponse<Map<String, String>>> getBatchSignedUrls(
      List<String> imageIds) async {
    try {
      final headers = await _getAuthHeader();

      // Prepare request body with array of attachment IDs
      final requestBody = jsonEncode({
        'attachmentIds': imageIds,
      });

      print('Batch API Request - Image IDs: $imageIds');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/mobile/admin/gallery/images/signed-urls'),
        headers: headers,
        body: requestBody,
      );

      print('Batch API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Debug: Print the entire response structure
        print('Batch API Response structure:');
        print('Response keys: ${responseData.keys.toList()}');
        if (responseData['data'] != null) {
          print('Data keys: ${responseData['data'].keys.toList()}');
          if (responseData['data']['successful'] != null) {
            print(
                'Successful data type: ${responseData['data']['successful'].runtimeType}');
            print('Successful data: ${responseData['data']['successful']}');
          }
          if (responseData['data']['failed'] != null) {
            print(
                'Failed data type: ${responseData['data']['failed'].runtimeType}');
            print('Failed data: ${responseData['data']['failed']}');
          }
        }

        if (responseData['success'] == true) {
          // Process batch response with successful and failed results
          Map<String, String> signedUrls = {};

          // Handle successful results - check if it's a List or Map
          if (responseData['data'] != null &&
              responseData['data']['successful'] != null) {
            final successfulData = responseData['data']['successful'];

            if (successfulData is List) {
              // Handle List format: [{"id": "imageId", "signedUrl": "url"}, ...]
              for (var item in successfulData) {
                if (item is Map<String, dynamic>) {
                  final imageId = item['id']?.toString();
                  final url = item['signedUrl']?.toString();
                  if (imageId != null && url != null) {
                    signedUrls[imageId] = url;
                    print(
                        'Found signed URL for $imageId: ${url.substring(0, 50)}...');
                  }
                }
              }
            } else if (successfulData is Map<String, dynamic>) {
              // Handle Map format: {"imageId": "signedUrl", ...}
              successfulData.forEach((imageId, urlData) {
                if (urlData is String) {
                  signedUrls[imageId] = urlData;
                } else if (urlData is Map<String, dynamic> &&
                    urlData['url'] != null) {
                  signedUrls[imageId] = urlData['url'] as String;
                }
              });
            }
          }

          // Log failed results for debugging
          if (responseData['data'] != null &&
              responseData['data']['failed'] != null) {
            final failedData = responseData['data']['failed'];
            List<String> failedIds = [];

            if (failedData is List) {
              // Handle List format: ["imageId1", "imageId2", ...]
              for (var item in failedData) {
                if (item is String) {
                  failedIds.add(item);
                } else if (item is Map<String, dynamic> && item['id'] != null) {
                  failedIds.add(item['id'].toString());
                }
              }
            } else if (failedData is Map<String, dynamic>) {
              // Handle Map format: {"imageId": "error", ...}
              failedIds = failedData.keys.toList();
            }

            if (failedIds.isNotEmpty) {
              print('Failed to get signed URLs for images: $failedIds');
            }
          }

          print(
              'Successfully retrieved ${signedUrls.length}/${imageIds.length} signed URLs');

          // If no signed URLs were found, try alternative response structures
          if (signedUrls.isEmpty) {
            print(
                'No signed URLs found in expected structure, trying alternative parsing...');

            // Try direct data structure: {"data": [{"id": "...", "url": "..."}]}
            if (responseData['data'] is List) {
              final dataList = responseData['data'] as List;
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final imageId = item['id']?.toString();
                  final url = item['url']?.toString();
                  if (imageId != null && url != null) {
                    signedUrls[imageId] = url;
                  }
                }
              }
            }

            // Try flat structure: {"data": {"imageId": "url", ...}}
            else if (responseData['data'] is Map<String, dynamic>) {
              final dataMap = responseData['data'] as Map<String, dynamic>;
              dataMap.forEach((key, value) {
                if (value is String && key != 'successful' && key != 'failed') {
                  signedUrls[key] = value;
                }
              });
            }

            print('Alternative parsing found ${signedUrls.length} signed URLs');
          }

          // If still no signed URLs found, fall back to individual requests
          if (signedUrls.isEmpty) {
            print(
                'Batch API returned no signed URLs, falling back to individual requests');
            return await _fallbackToIndividualRequests(imageIds);
          }

          return ApiResponse(
            success: true,
            message: 'Batch signed URLs retrieved successfully',
            data: signedUrls,
            statusCode: 200,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseData['message'] ??
                'Failed to retrieve batch signed URLs',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 307 || response.statusCode == 404) {
        // Batch API not implemented yet - fallback to individual requests
        print(
            'Batch API not available (${response.statusCode}), falling back to individual requests');
        return await _fallbackToIndividualRequests(imageIds);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to retrieve batch signed URLs',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Batch API Exception: ${e.toString()}');
      // Fallback to individual requests if batch API fails
      print('Falling back to individual requests due to exception');
      return await _fallbackToIndividualRequests(imageIds);
    }
  }

  // Search images with filters using API parameters
  Future<ApiResponse<List<GalleryImage>>> searchImages({
    String? query,
    String? fieldAgent,
    String? region,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Use the API's built-in filtering instead of client-side filtering
      return await getAllImages(
        search: query,
        fieldAgent: fieldAgent,
        region: region,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Mock data for testing when API endpoint is not available
  Future<ApiResponse<List<GalleryImage>>> _getMockImages() async {
    final mockImages = [
      GalleryImage(
        id: '1',
        taskId: 'TASK-001',
        taskTitle: 'Meter Reading - Site A',
        meterNumber: 'MTR-12345',
        fieldAgentName: 'John Doe',
        fieldAgentId: 'agent-001',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        fileName: 'meter_reading_001.jpg',
        fileSize: '245760', // 240KB
        mimeType: 'image/jpeg',
      ),
      GalleryImage(
        id: '2',
        taskId: 'TASK-002',
        taskTitle: 'Equipment Inspection',
        meterNumber: 'MTR-67890',
        fieldAgentName: 'Jane Smith',
        fieldAgentId: 'agent-002',
        uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
        fileName: 'equipment_inspection_002.jpg',
        fileSize: '512000', // 500KB
        mimeType: 'image/jpeg',
      ),
      GalleryImage(
        id: '3',
        taskId: 'TASK-003',
        taskTitle: 'Maintenance Check',
        meterNumber: 'MTR-11111',
        fieldAgentName: 'Mike Johnson',
        fieldAgentId: 'agent-003',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 6)),
        fileName: 'maintenance_check_003.jpg',
        fileSize: '128000', // 125KB
        mimeType: 'image/jpeg',
      ),
      GalleryImage(
        id: '4',
        taskId: 'TASK-004',
        taskTitle: 'Safety Inspection',
        meterNumber: 'MTR-22222',
        fieldAgentName: 'Sarah Wilson',
        fieldAgentId: 'agent-004',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
        fileName: 'safety_inspection_004.jpg',
        fileSize: '384000', // 375KB
        mimeType: 'image/jpeg',
      ),
    ];

    return ApiResponse(
      success: true,
      message: 'Mock images loaded successfully',
      data: mockImages,
      statusCode: 200,
    );
  }

  // Fallback method: get signed URLs individually when batch API is not available
  Future<ApiResponse<Map<String, String>>> _fallbackToIndividualRequests(
      List<String> imageIds) async {
    print(
        'Starting fallback individual requests for ${imageIds.length} images');
    Map<String, String> signedUrls = {};

    // Process in smaller batches to avoid overwhelming the server
    const int batchSize = 5;
    for (int i = 0; i < imageIds.length; i += batchSize) {
      final batchEnd = (i + batchSize).clamp(0, imageIds.length);
      final batchFutures = <Future<void>>[];

      for (int j = i; j < batchEnd; j++) {
        batchFutures
            .add(_fetchSingleSignedUrlForBatch(imageIds[j], signedUrls));
      }

      await Future.wait(batchFutures);
      print(
          'Completed individual batch ${(i ~/ batchSize) + 1}/${(imageIds.length / batchSize).ceil()}');
    }

    print(
        'Fallback completed: ${signedUrls.length}/${imageIds.length} signed URLs retrieved');
    return ApiResponse(
      success: true,
      message: 'Signed URLs retrieved via fallback method',
      data: signedUrls,
      statusCode: 200,
    );
  }

  // Helper method for individual signed URL requests in fallback mode
  Future<void> _fetchSingleSignedUrlForBatch(
      String imageId, Map<String, String> signedUrls) async {
    try {
      final response = await getImageSignedUrl(imageId);
      if (response.success && response.data != null) {
        signedUrls[imageId] = response.data!;
        print('Successfully got signed URL for image $imageId');
      } else {
        print(
            'Failed to get signed URL for image $imageId: ${response.message}');
      }
    } catch (e) {
      print('Exception getting signed URL for image $imageId: $e');
    }
  }
}
