import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/error_dialog.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket header section
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title.isEmpty
                              ? ticket.id
                              : ticket.title,
                          style: AppTheme.headingStyle,
                        ),
                      ),
                      _buildStatusChip(ticket.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created on: ${dateFormat.format(ticket.createdAt)}',
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.description.isEmpty
                        ? "No description provided"
                        : ticket.description,
                    style: AppTheme.bodyStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Consumer details section
            const Text(
              'Consumer Details',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 8),
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
                children: [
                  _buildDetailRow(
                      'Meter Number', ticket.meterNumber, Icons.electric_meter),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Attachments section (if any)
            if (ticket.attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachments',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 8),
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
                      children: ticket.attachments.map((url) {
                        return ListTile(
                          leading: const Icon(Icons.image,
                              color: AppTheme.primaryColor),
                          title: const Text('Photo'),
                          trailing: const Icon(Icons.visibility),
                          onTap: () {
                            // View attachment (not implemented in this MVP)
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Action button for non-completed tickets
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _navigateToCompletionScreen(ticket),
                  style: AppTheme.primaryButtonStyle,
                  child: const Text(
                    'COMPLETE TICKET',
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
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? "Not available" : value,
                style: AppTheme.bodyStyle,
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

    return Chip(
      label: Text(
        status.isEmpty ? "Unknown" : status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
