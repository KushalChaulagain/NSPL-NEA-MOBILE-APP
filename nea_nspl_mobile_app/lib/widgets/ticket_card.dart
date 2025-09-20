import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onViewDetails;
  final VoidCallback? onComplete;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onViewDetails,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
    final bool isCompleted = ticket.status.toLowerCase() == 'completed';

    Color statusColor;
    IconData statusIcon;

    switch (ticket.status.toLowerCase()) {
      case 'pending':
        statusColor = AppTheme.pendingColor;
        statusIcon = Icons.pending_actions;
        break;
      case 'in_progress':
        statusColor = AppTheme.inProgressColor;
        statusIcon = Icons.sync;
        break;
      case 'completed':
        statusColor = AppTheme.completedColor;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppTheme.secondaryColor;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            title: Text(
              ticket.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text('Created on: ${dateFormat.format(ticket.createdAt)}'),
            trailing: Icon(statusIcon, color: statusColor),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meter type
                Row(
                  children: [
                    Icon(Icons.electric_meter,
                        size: 16, color: AppTheme.secondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Meter: ${ticket.meter ?? "Not available"}',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Site information
                Row(
                  children: [
                    Icon(Icons.business,
                        size: 16, color: AppTheme.secondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Site: ${ticket.site ?? "Not available"}',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              TextButton(
                onPressed: onViewDetails,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: const Text('VIEW DETAILS'),
              ),
              if (onComplete != null && !isCompleted)
                ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('COMPLETE'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
