import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/photo_capture_widget.dart';

class TicketCompletionScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketCompletionScreen({
    super.key,
    required this.ticket,
  });

  @override
  _TicketCompletionScreenState createState() => _TicketCompletionScreenState();
}

class _TicketCompletionScreenState extends State<TicketCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _meterReadingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<File> _meterPhotos = [];
  bool _isMeterAccessible = true;
  String? _consumerPresenceStatus;

  final List<String> _consumerPresenceOptions = [
    'Present',
    'Absent',
    'Represented by family member'
  ];

  @override
  void dispose() {
    _meterReadingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitTicketCompletion() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate photos
      if (_meterPhotos.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please capture at least 2 meter photos'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Create form data
      final formData = {
        'meterReading': _meterReadingController.text.trim(),
        'notes': _notesController.text.trim(),
        'isMeterAccessible': _isMeterAccessible,
        'consumerPresence': _consumerPresenceStatus,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Submit completion
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final success = await ticketProvider.completeTicket(
        widget.ticket.id,
        formData,
        _meterPhotos,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket completed successfully'),
            backgroundColor: AppTheme.completedColor,
          ),
        );

        // Return to previous screen with success status
        Navigator.of(context).pop(true);
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (_) => ErrorDialog(
            title: 'Submission Failed',
            message: ticketProvider.errorMessage,
          ),
        );
      }
    }
  }

  void _handlePhotosSelected(List<File> photos) {
    setState(() {
      _meterPhotos.clear();
      _meterPhotos.addAll(photos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final isSubmitting = ticketProvider.status == TicketStatus.submitting;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Complete Ticket'),
      body: isSubmitting
          ? Center(child: _buildSubmittingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ticket Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.ticket.title,
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consumer: ${widget.ticket.consumerName}',
                            style: AppTheme.captionStyle,
                          ),
                          Text(
                            'Meter #: ${widget.ticket.meterNumber}',
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meter reading
                    Text(
                      'Meter Reading',
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _meterReadingController,
                      decoration: InputDecoration(
                        hintText: 'Enter current meter reading',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.electric_meter),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the meter reading';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Meter accessibility
                    Text(
                      'Meter Accessibility',
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Accessible'),
                            value: true,
                            groupValue: _isMeterAccessible,
                            onChanged: (value) {
                              setState(() {
                                _isMeterAccessible = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Inaccessible'),
                            value: false,
                            groupValue: _isMeterAccessible,
                            onChanged: (value) {
                              setState(() {
                                _isMeterAccessible = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Consumer presence
                    Text(
                      'Consumer Presence',
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      hint: const Text('Select consumer presence status'),
                      value: _consumerPresenceStatus,
                      onChanged: (value) {
                        setState(() {
                          _consumerPresenceStatus = value;
                        });
                      },
                      items: _consumerPresenceOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select consumer presence status';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Photo capture widget
                    PhotoCaptureWidget(
                      onPhotosSelected: _handlePhotosSelected,
                      requiredPhotoCount: 2,
                      title: 'Meter Photos',
                      description:
                          'Take clear photos of the meter (2 required)',
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    Text(
                      'Additional Notes',
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Enter any additional information',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            isSubmitting ? null : _submitTicketCompletion,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSubmittingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoadingIndicator(size: 40),
        const SizedBox(height: 16),
        Text(
          'Submitting ticket completion...',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we upload your data',
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }
}
