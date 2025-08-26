import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';

class PhotoCaptureWidget extends StatefulWidget {
  final Function(List<File>) onPhotosSelected;
  final int requiredPhotoCount;
  final String title;
  final String description;

  const PhotoCaptureWidget({
    super.key,
    required this.onPhotosSelected,
    this.requiredPhotoCount = 2,
    this.title = 'Meter Photos',
    this.description = 'Take clear photos of the meter',
  });

  @override
  _PhotoCaptureWidgetState createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final List<File> _selectedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _takePicture(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        // If replacing an existing image
        if (index < _selectedPhotos.length) {
          _selectedPhotos[index] = File(image.path);
        } else {
          _selectedPhotos.add(File(image.path));
        }

        // Notify parent about the selected photos
        widget.onPhotosSelected(_selectedPhotos);
      });
    }
  }

  Future<void> _pickFromGallery(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        // If replacing an existing image
        if (index < _selectedPhotos.length) {
          _selectedPhotos[index] = File(image.path);
        } else {
          _selectedPhotos.add(File(image.path));
        }

        // Notify parent about the selected photos
        widget.onPhotosSelected(_selectedPhotos);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      widget.onPhotosSelected(_selectedPhotos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 16),

        // Photo grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widget.requiredPhotoCount,
          itemBuilder: (context, index) {
            final bool hasPhoto = index < _selectedPhotos.length;

            return GestureDetector(
              onTap: () => _showPhotoOptionsDialog(context, index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        hasPhoto ? AppTheme.primaryColor : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: hasPhoto
                    ? _buildPhotoPreview(index)
                    : _buildAddPhotoPlaceholder(index),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        Text(
          '${_selectedPhotos.length}/${widget.requiredPhotoCount} photos selected',
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _selectedPhotos[index],
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoPlaceholder(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.camera_alt,
          size: 40,
          color: Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          'Photo ${index + 1}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _showPhotoOptionsDialog(BuildContext context, int index) async {
    final bool hasPhoto = index < _selectedPhotos.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(hasPhoto ? 'Replace Photo' : 'Add Photo'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePicture(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromGallery(index);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _removePhoto(index);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
