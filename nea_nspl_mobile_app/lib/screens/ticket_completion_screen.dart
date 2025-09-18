import 'dart:io';

import 'package:flutter/material.dart';
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
  final TextEditingController _meterSerialNumberController =
      TextEditingController();
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
    _meterSerialNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitTicketCompletion() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate photos
      if (_meterPhotos.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture at least 2 meter photos'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Create form data
      final formData = {
        'meterReading': _meterReadingController.text.trim(),
        'meterSerialNumber': _meterSerialNumberController.text.trim(),
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
          const SnackBar(
            content: Text('Ticket completed successfully'),
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
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket summary - Modern field service design
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      decoration: AppTheme.elevatedCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacing8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              const Text(
                                'Ticket Summary',
                                style: AppTheme.subheadingStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            widget.ticket.title.isEmpty
                                ? "Task #${widget.ticket.id}"
                                : widget.ticket.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.outlineColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.electric_meter,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(
                                  'Meter: ${widget.ticket.meterNumber.isEmpty ? "N/A" : widget.ticket.meterNumber}',
                                  style: AppTheme.captionStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),

                    // Meter Serial Number
                    const Text(
                      'Meter Serial Number',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextFormField(
                      controller: _meterSerialNumberController,
                      decoration: AppTheme.getInputDecoration(
                        'Meter Serial Number',
                        hint: 'Enter meter serial number',
                      ).copyWith(
                        suffixIcon:
                            const Icon(Icons.pin, color: AppTheme.primaryColor),
                      ),
                      // No validator since this field is optional
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Meter reading
                    const Text(
                      'Meter Reading',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextFormField(
                      controller: _meterReadingController,
                      decoration: AppTheme.getInputDecoration(
                        'Meter Reading',
                        hint: 'Enter current meter reading',
                      ).copyWith(
                        suffixIcon: const Icon(Icons.electric_meter,
                            color: AppTheme.primaryColor),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the meter reading';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Meter accessibility
                    const Text(
                      'Meter Accessibility',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: AppTheme.cardDecoration,
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Accessible'),
                              value: true,
                              groupValue: _isMeterAccessible,
                              activeColor: AppTheme.primaryColor,
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
                              activeColor: AppTheme.primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _isMeterAccessible = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Consumer presence
                    const Text(
                      'Consumer Presence',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    DropdownButtonFormField<String>(
                      decoration: AppTheme.getInputDecoration(
                        'Consumer Presence',
                        hint: 'Select consumer presence status',
                      ),
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
                    const SizedBox(height: AppTheme.spacing24),

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
                    const Text(
                      'Additional Notes',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    TextFormField(
                      controller: _notesController,
                      decoration: AppTheme.getInputDecoration(
                        'Additional Notes',
                        hint: 'Enter any additional information',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            isSubmitting ? null : _submitTicketCompletion,
                        style: AppTheme.floatingButtonStyle,
                        child: const Text(
                          'Submit Completion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingIndicator(size: 40),
        SizedBox(height: 16),
        Text(
          'Submitting ticket completion...',
          style: AppTheme.subheadingStyle,
        ),
        SizedBox(height: 8),
        Text(
          'Please wait while we upload your data',
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }
}
