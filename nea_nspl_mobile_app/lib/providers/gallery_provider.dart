import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../models/gallery_image.dart';
import '../services/gallery_service.dart';

enum GalleryStatus { initial, loading, loaded, error, searching }

class GalleryProvider extends ChangeNotifier {
  final GalleryService _galleryService = GalleryService();

  GalleryStatus _status = GalleryStatus.initial;
  List<GalleryImage> _images = [];
  List<GalleryImage> _filteredImages = [];
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedFieldAgent = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSearching = false;
  int _signedUrlProgress = 0;
  int _totalImages = 0;

  // Getters
  GalleryStatus get status => _status;
  List<GalleryImage> get images => _filteredImages;
  List<GalleryImage> get allImages => _images;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFieldAgent => _selectedFieldAgent;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  bool get isSearching => _isSearching;
  int get signedUrlProgress => _signedUrlProgress;
  int get totalImages => _totalImages;
  double get signedUrlProgressPercentage =>
      _totalImages > 0 ? _signedUrlProgress / _totalImages : 0.0;

  // Get unique field agents for filter dropdown
  List<String> get fieldAgents {
    final agents =
        _images.map((image) => image.fieldAgentName).toSet().toList();
    agents.sort();
    return ['All', ...agents];
  }

  // Fetch all images
  Future<void> fetchImages() async {
    _status = GalleryStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final ApiResponse<List<GalleryImage>> response =
          await _galleryService.getAllImages();

      if (response.success && response.data != null) {
        _images = response.data!;

        // Fetch signed URLs for all images
        await _fetchSignedUrlsForImages();

        _applyFilters();
        _status = GalleryStatus.loaded;
      } else {
        _status = GalleryStatus.error;
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to load images';
      }
    } catch (e) {
      _status = GalleryStatus.error;
      _errorMessage = 'Error: ${e.toString()}';
    }

    notifyListeners();
  }

  // Fetch signed URLs for all images using batch API
  Future<void> _fetchSignedUrlsForImages() async {
    print('Starting batch fetch for signed URLs of ${_images.length} images');

    _totalImages = _images.length;
    _signedUrlProgress = 0;
    notifyListeners();

    try {
      // Extract all image IDs for batch request
      final imageIds = _images.map((image) => image.id).toList();

      // Make single batch API call
      final batchResponse = await _galleryService.getBatchSignedUrls(imageIds);

      if (batchResponse.success && batchResponse.data != null) {
        final signedUrls = batchResponse.data!;

        // Update all images with their signed URLs
        for (int i = 0; i < _images.length; i++) {
          final imageId = _images[i].id;
          final signedUrl = signedUrls[imageId];

          if (signedUrl != null) {
            print('Successfully got signed URL for image $imageId');
            _images[i] = GalleryImage(
              id: _images[i].id,
              taskId: _images[i].taskId,
              taskTitle: _images[i].taskTitle,
              meterNumber: _images[i].meterNumber,
              fieldAgentName: _images[i].fieldAgentName,
              fieldAgentId: _images[i].fieldAgentId,
              uploadedAt: _images[i].uploadedAt,
              fileName: _images[i].fileName,
              fileSize: _images[i].fileSize,
              mimeType: _images[i].mimeType,
              signedUrl: signedUrl,
              urlExpiresAt:
                  DateTime.now().add(const Duration(hours: 1)), // 1 hour expiry
            );
          } else {
            print('No signed URL returned for image $imageId');
          }

          // Update progress
          _signedUrlProgress++;
          notifyListeners();
        }

        print(
            'Batch fetch completed: ${signedUrls.length}/${imageIds.length} signed URLs retrieved');
      } else {
        print('Batch API failed: ${batchResponse.message}');
        // Fallback: mark all as failed
        _signedUrlProgress = _totalImages;
        notifyListeners();
      }
    } catch (e) {
      print('Batch fetch exception: $e');
      // Mark all as failed
      _signedUrlProgress = _totalImages;
      notifyListeners();
    }
  }

  // Search images with filters
  Future<void> searchImages({
    String? query,
    String? fieldAgent,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isSearching = true;
    _status = GalleryStatus.searching;
    _errorMessage = '';
    notifyListeners();

    try {
      final ApiResponse<List<GalleryImage>> response =
          await _galleryService.searchImages(
        query: query,
        fieldAgent: fieldAgent != 'All' ? fieldAgent : null,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response.success && response.data != null) {
        _images = response.data!;

        // Fetch signed URLs for search results
        await _fetchSignedUrlsForImages();

        _applyFilters();
        _status = GalleryStatus.loaded;
      } else {
        _status = GalleryStatus.error;
        _errorMessage =
            response.message.isNotEmpty ? response.message : 'Search failed';
      }
    } catch (e) {
      _status = GalleryStatus.error;
      _errorMessage = 'Error: ${e.toString()}';
    }

    _isSearching = false;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set field agent filter
  void setFieldAgentFilter(String fieldAgent) {
    _selectedFieldAgent = fieldAgent;
    _applyFilters();
    notifyListeners();
  }

  // Set date range filters
  void setDateRange(DateTime? fromDate, DateTime? toDate) {
    _fromDate = fromDate;
    _toDate = toDate;
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedFieldAgent = 'All';
    _fromDate = null;
    _toDate = null;
    _applyFilters();
    notifyListeners();
  }

  // Apply current filters to images
  void _applyFilters() {
    _filteredImages = List.from(_images);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredImages = _filteredImages
          .where((image) =>
              image.taskTitle.toLowerCase().contains(query) ||
              image.meterNumber.toLowerCase().contains(query) ||
              image.fieldAgentName.toLowerCase().contains(query) ||
              image.fileName.toLowerCase().contains(query))
          .toList();
    }

    // Apply field agent filter
    if (_selectedFieldAgent != 'All') {
      _filteredImages = _filteredImages
          .where((image) => image.fieldAgentName == _selectedFieldAgent)
          .toList();
    }

    // Apply date range filters
    if (_fromDate != null) {
      _filteredImages = _filteredImages
          .where((image) =>
              image.uploadedAt.isAfter(_fromDate!) ||
              image.uploadedAt.isAtSameMomentAs(_fromDate!))
          .toList();
    }

    if (_toDate != null) {
      _filteredImages = _filteredImages
          .where((image) =>
              image.uploadedAt.isBefore(_toDate!) ||
              image.uploadedAt.isAtSameMomentAs(_toDate!))
          .toList();
    }
  }

  // Get signed URL for an image
  Future<String?> getImageSignedUrl(String imageId) async {
    try {
      final ApiResponse<String> response =
          await _galleryService.getImageSignedUrl(imageId);

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }

  // Reset error state
  void resetError() {
    _errorMessage = '';
    _status = _images.isEmpty ? GalleryStatus.initial : GalleryStatus.loaded;
    notifyListeners();
  }

  // Get image count by field agent
  int getImageCountByFieldAgent(String fieldAgent) {
    if (fieldAgent == 'All') {
      return _images.length;
    }
    return _images.where((image) => image.fieldAgentName == fieldAgent).length;
  }

  // Get total image count
  int get totalImageCount => _images.length;

  // Get filtered image count
  int get filteredImageCount => _filteredImages.length;
}
