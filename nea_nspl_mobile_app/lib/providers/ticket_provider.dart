import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

enum TicketStatus { initial, loading, loaded, error, submitting, submitted }

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();

  TicketStatus _status = TicketStatus.initial;
  List<Ticket> _tickets = [];
  Ticket? _selectedTicket;
  String _errorMessage = '';

  // Filter options
  String _filterStatus = 'All';
  String _searchQuery = '';

  // Getters
  TicketStatus get status => _status;
  List<Ticket> get tickets => _getFilteredTickets();
  Ticket? get selectedTicket => _selectedTicket;
  String get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  // Get tickets with retry logic
  Future<void> fetchTickets({int retryCount = 0}) async {
    _status = TicketStatus.loading;
    notifyListeners();

    try {
      final ApiResponse<List<Ticket>> response =
          await _ticketService.getTickets();

      if (response.success && response.data != null) {
        _tickets = response.data!;
        _status = TicketStatus.loaded;
      } else {
        // Handle server errors with more specific messaging
        if (response.statusCode == 500 && retryCount < 2) {
          // Server error - retry up to 2 times with a delay
          _errorMessage = "Server error occurred. Retrying...";
          notifyListeners();

          await Future.delayed(const Duration(seconds: 2));
          return fetchTickets(retryCount: retryCount + 1);
        }

        _status = TicketStatus.error;

        // Provide a more helpful error message
        if (response.statusCode == 500) {
          _errorMessage =
              "Server error occurred. Please try again later or contact support.";
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          _errorMessage = "Authentication error. Please log in again.";
        } else {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : "Failed to retrieve tickets. Please try again.";
        }
      }
    } catch (e) {
      _status = TicketStatus.error;
      _errorMessage = "Connection error: ${e.toString()}";
    }

    notifyListeners();
  }

  // Get ticket by ID
  Future<void> fetchTicketById(String ticketId) async {
    _status = TicketStatus.loading;
    notifyListeners();

    final ApiResponse<Ticket> response =
        await _ticketService.getTicketById(ticketId);

    if (response.success && response.data != null) {
      _selectedTicket = response.data;
      _status = TicketStatus.loaded;
    } else {
      _status = TicketStatus.error;
      _errorMessage = response.message;
    }

    notifyListeners();
  }

  // Complete ticket
  Future<bool> completeTicket(
      String ticketId, Map<String, dynamic> formData, List<File> photos) async {
    _status = TicketStatus.submitting;
    notifyListeners();

    final ApiResponse<bool> response =
        await _ticketService.completeTicket(ticketId, formData, photos);

    if (response.success) {
      _status = TicketStatus.submitted;

      // Refresh tickets list
      await fetchTickets();

      notifyListeners();
      return true;
    } else {
      _status = TicketStatus.error;
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  // Set filter status
  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Reset error state
  void resetError() {
    _errorMessage = '';
    _status = _tickets.isEmpty ? TicketStatus.initial : TicketStatus.loaded;
    notifyListeners();
  }

  // Helper method to apply filters
  List<Ticket> _getFilteredTickets() {
    // Start with all tickets
    List<Ticket> filteredList = List.from(_tickets);

    // Apply status filter if not 'All'
    if (_filterStatus != 'All') {
      filteredList = filteredList
          .where((ticket) =>
              ticket.status.toLowerCase() == _filterStatus.toLowerCase())
          .toList();
    }

    // Apply search query if not empty
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredList = filteredList
          .where((ticket) =>
              ticket.title.toLowerCase().contains(query) ||
              ticket.description.toLowerCase().contains(query) ||
              ticket.consumerName.toLowerCase().contains(query) ||
              ticket.consumerAddress.toLowerCase().contains(query) ||
              ticket.meterNumber.toLowerCase().contains(query))
          .toList();
    }

    return filteredList;
  }

  // Get count of tickets by status
  int getTicketCountByStatus(String status) {
    if (status == 'All') {
      return _tickets.length;
    }
    return _tickets
        .where((ticket) => ticket.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  // Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    notifyListeners();
  }
}
