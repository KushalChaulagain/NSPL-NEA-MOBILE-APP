import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/ticket_provider.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  _TicketListScreenState createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Completed'
  ];
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
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tickets...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (query) {
                    ticketProvider.setSearchQuery(query);
                  },
                ),
                const SizedBox(height: 16),

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
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              ticketProvider.setFilterStatus(filter);
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.secondaryColor,
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
                          padding: const EdgeInsets.all(16),
                          itemCount: ticketProvider.tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = ticketProvider.tickets[index];
                            return _buildTicketCard(ticket);
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              ticket.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Meter #: ${ticket.meterNumber}'),
            trailing: Icon(statusIcon, color: statusColor),
          ),
          const Divider(height: 0),
         
          ButtonBar(
            alignment: MainAxisAlignment.end,
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              TextButton(
                onPressed: () {
                  // View ticket details
                  // To be implemented
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: const Text('VIEW DETAILS'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Complete ticket
                  // To be implemented
                },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: AppTheme.secondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tickets found',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your filters or search criteria',
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
