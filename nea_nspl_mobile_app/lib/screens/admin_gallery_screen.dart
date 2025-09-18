import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/gallery_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/gallery_grid_widget.dart';
import '../widgets/image_search_widget.dart';
import '../widgets/loading_indicator.dart';
import 'profile_screen.dart';

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  _AdminGalleryScreenState createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSearchFilters = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _loadImages());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final galleryProvider =
        Provider.of<GalleryProvider>(context, listen: false);
    await galleryProvider.fetchImages();
  }

  Future<void> _handleRefresh() async {
    await _loadImages();
  }

  void _toggleSearchFilters() {
    setState(() {
      _showSearchFilters = !_showSearchFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final galleryProvider = Provider.of<GalleryProvider>(context);

    // Check if user is admin
    if (authProvider.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Gallery'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is only available to administrators.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Image Gallery'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_showSearchFilters ? Icons.search_off : Icons.search),
            color: Colors.white,
            onPressed: _toggleSearchFilters,
            tooltip: _showSearchFilters ? 'Hide Filters' : 'Show Filters',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Text(
                    authProvider.user != null &&
                            authProvider.user!.name.isNotEmpty
                        ? authProvider.user!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Admin welcome section - Modern field service design
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppTheme.spacing16),
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: AppTheme.elevatedCardDecoration,
            child: Row(
              children: [
                // Admin avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      authProvider.user?.name.isNotEmpty == true
                          ? authProvider.user!.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome, Admin',
                        style: AppTheme.captionStyle,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        authProvider.user?.name ?? 'Administrator',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: AppTheme.getStatusBadgeDecoration(
                            AppTheme.primaryColor),
                        child: const Text(
                          'Image Gallery Management',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Search and filters section
          if (_showSearchFilters)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              decoration: AppTheme.cardDecoration,
              child: const Padding(
                padding: EdgeInsets.all(AppTheme.spacing20),
                child: ImageSearchWidget(),
              ),
            ),

          // Gallery content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _buildGalleryContent(galleryProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent(GalleryProvider galleryProvider) {
    switch (galleryProvider.status) {
      case GalleryStatus.initial:
      case GalleryStatus.loading:
        return const Center(child: LoadingIndicator());

      case GalleryStatus.error:
        return ErrorView(
          message: galleryProvider.errorMessage,
          onRetry: _loadImages,
        );

      case GalleryStatus.loaded:
      case GalleryStatus.searching:
        if (galleryProvider.images.isEmpty) {
          return _buildEmptyState();
        }

        return GalleryGridWidget(
          images: galleryProvider.images,
          scrollController: _scrollController,
        );
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              200, // Account for app bar and other UI elements
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Images Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No images have been uploaded by field agents yet.',
                  style: AppTheme.captionStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: AppTheme.primaryButtonStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
