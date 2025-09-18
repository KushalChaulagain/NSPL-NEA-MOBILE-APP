import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/loading_indicator.dart';
import 'ticket_completion_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    await ticketProvider.fetchTicketById(widget.ticketId);
  }

  Future<void> _navigateToCompletionScreen(Ticket ticket) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketCompletionScreen(ticket: ticket),
      ),
    );

    if (result == true) {
      // Ticket was completed, refresh the details
      _loadTicketDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
    final ticketProvider = Provider.of<TicketProvider>(context);

    if (ticketProvider.status == TicketStatus.loading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Ticket Details'),
        body: Center(child: LoadingIndicator(size: 40)),
      );
    }

    if (ticketProvider.status == TicketStatus.error) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Ticket Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load ticket details',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                ticketProvider.errorMessage,
                style: AppTheme.captionStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTicketDetails,
                style: AppTheme.primaryButtonStyle,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    final ticket = ticketProvider.selectedTicket;
    if (ticket == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Ticket Details'),
        body: Center(child: Text('No ticket found')),
      );
    }

    final bool isCompleted = ticket.status.toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Ticket Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket header section - Modern field service design
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: AppTheme.elevatedCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title.isEmpty
                              ? "Task #${ticket.id}"
                              : ticket.title,
                          style: AppTheme.headingStyle,
                        ),
                      ),
                      _buildStatusChip(ticket.status),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.onSurfaceVariantColor,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Created: ${dateFormat.format(ticket.createdAt)}',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  const Text(
                    'Description',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineColor),
                    ),
                    child: Text(
                      ticket.description.isEmpty
                          ? "No description provided"
                          : ticket.description,
                      style: AppTheme.bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Consumer details section
            const Text(
              'Consumer Details',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  _buildDetailRow(
                      'Meter Number', ticket.meterNumber, Icons.electric_meter),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Attachments section (if any)
            if (ticket.attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachments',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: ticket.attachments.map((url) {
                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: AppTheme.spacing8),
                          padding: const EdgeInsets.all(AppTheme.spacing12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacing8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              const Expanded(
                                child: Text(
                                  'Photo Attachment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceColor,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.visibility,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                ],
              ),

            // Action button for non-completed tickets
            if (!isCompleted)
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(top: AppTheme.spacing16),
                child: ElevatedButton(
                  onPressed: () => _navigateToCompletionScreen(ticket),
                  style: AppTheme.floatingButtonStyle,
                  child: const Text(
                    'Complete Ticket',
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
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariantColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value.isEmpty ? "Not available" : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = AppTheme.pendingColor;
        break;
      case 'in_progress':
        chipColor = AppTheme.inProgressColor;
        break;
      case 'completed':
        chipColor = AppTheme.completedColor;
        break;
      default:
        chipColor = AppTheme.secondaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing6,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.isEmpty ? "Unknown" : status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
