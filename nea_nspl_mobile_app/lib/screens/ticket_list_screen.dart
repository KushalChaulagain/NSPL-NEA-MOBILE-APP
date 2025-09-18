import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/ticket_provider.dart';
import 'ticket_completion_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  _TicketListScreenState createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['All', 'Pending', 'Completed'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() async {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      await ticketProvider.fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Tickets'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter section - Modern field service design
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search box
                TextField(
                  controller: _searchController,
                  decoration: AppTheme.getInputDecoration(
                    'Search tickets...',
                    hint: 'Enter ticket ID or meter number',
                  ).copyWith(
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.onSurfaceVariantColor),
                  ),
                  onChanged: (query) {
                    ticketProvider.setSearchQuery(query);
                  },
                ),
                const SizedBox(height: AppTheme.spacing20),

                // Status filter chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final isSelected = _selectedFilter == filter;

                      return Padding(
                        padding:
                            const EdgeInsets.only(right: AppTheme.spacing12),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              ticketProvider.setFilterStatus(filter);
                            });
                          },
                          backgroundColor:
                              AppTheme.outlineColor.withOpacity(0.3),
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceColor,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tickets list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              child: ticketProvider.status == TicketStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ticketProvider.tickets.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          itemCount: ticketProvider.tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = ticketProvider.tickets[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTheme.spacing12),
                              child: _buildTicketCard(ticket),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
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

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                // Ticket details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title.isEmpty
                            ? "Task: ${ticket.id}"
                            : ticket.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Meter: ${ticket.meterNumber.isEmpty ? "N/A" : ticket.meterNumber}',
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariantColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing20,
              0,
              AppTheme.spacing20,
              AppTheme.spacing20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TicketDetailScreen(ticketId: ticket.id),
                        ),
                      );
                    },
                    style: AppTheme.secondaryButtonStyle,
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ticket.status.toLowerCase() == 'completed'
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TicketCompletionScreen(ticket: ticket),
                              ),
                            );
                          },
                    style: AppTheme.primaryButtonStyle,
                    child: Text(ticket.status.toLowerCase() == 'completed'
                        ? 'Completed'
                        : 'Complete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
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
                Icons.assignment_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            const Text(
              'No tickets found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            const Text(
              'Try changing your filters or search criteria',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
