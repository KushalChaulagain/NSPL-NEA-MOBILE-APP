import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/error_view.dart';
import 'admin_gallery_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'ticket_detail_screen.dart';
import 'ticket_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Use Future.delayed to avoid setState during build
    Future.microtask(() async {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      await ticketProvider.fetchTickets();
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('NEA NSPL'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            tooltip: 'Notifications',
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
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      user != null && user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Field Agent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.role ?? 'Agent',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: true,
              selectedColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('My Tickets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TicketListScreen()),
                );
              },
            ),
            // Admin-only gallery access
            if (user?.role.toLowerCase() == 'admin')
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Image Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AdminGalleryScreen()),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner - Modern field service design
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                padding: const EdgeInsets.all(AppTheme.spacing24),
                decoration: AppTheme.elevatedCardDecoration,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
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
                            'Welcome back,',
                            style: AppTheme.captionStyle,
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            user?.name ?? 'Field Agent',
                            style: const TextStyle(
                              fontSize: 24,
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
                            child: Text(
                              user?.role ?? 'Field Agent',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Ticket stats section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks Overview',
                      style: AppTheme.subheadingStyle,
                    ),
                    SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Your current task statistics',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),

              // Task stats cards in grid - Modern field service design
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        ticketProvider
                            .getTicketCountByStatus('pending')
                            .toString(),
                        AppTheme.pendingColor,
                        Icons.pending_actions,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        ticketProvider
                            .getTicketCountByStatus('completed')
                            .toString(),
                        AppTheme.completedColor,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        ticketProvider.tickets.length.toString(),
                        AppTheme.primaryColor,
                        Icons.assignment,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Recent tickets header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Tasks',
                          style: AppTheme.subheadingStyle,
                        ),
                        SizedBox(height: AppTheme.spacing4),
                        Text(
                          'Your latest assigned tasks',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TicketListScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),

              // Recent tickets list with modern cards
              ticketProvider.status == TicketStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ticketProvider.status == TicketStatus.error
                      ? ErrorView(
                          message: ticketProvider.errorMessage,
                          onRetry: _loadData,
                          showSupportOption: ticketProvider.errorMessage
                              .contains('Server error'),
                        )
                      : ticketProvider.tickets.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildEmptyState(),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing16),
                              itemCount: ticketProvider.tickets.length > 3
                                  ? 3
                                  : ticketProvider.tickets.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacing12),
                                child: _buildTicketCard(
                                    ticketProvider.tickets[index]),
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariantColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticketId: ticket.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: AppTheme.cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - status icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(ticket.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(ticket.status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(ticket.status),
                  color: _getStatusColor(ticket.status),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            // Center - details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title.isEmpty ? "Task: ${ticket.id}" : ticket.title,
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
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    DateFormat('MMM d, yyyy').format(ticket.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
            ),
            // Right side - status badge
            _buildStatusChip(ticket.status),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_progress':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.pendingColor;
      case 'in_progress':
        return AppTheme.inProgressColor;
      case 'completed':
        return AppTheme.completedColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = AppTheme.pendingColor;
        textColor = Colors.white;
        displayStatus = 'Pending';
        break;
      case 'completed':
        chipColor = AppTheme.completedColor;
        textColor = Colors.white;
        displayStatus = 'Completed';
        break;
      default:
        chipColor = AppTheme.secondaryColor;
        textColor = Colors.white;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
            'No Tasks Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          const Text(
            'You currently have no tasks assigned to you',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariantColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: _loadData,
            style: AppTheme.primaryButtonStyle,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
