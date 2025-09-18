import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/gallery_provider.dart';

class ImageSearchWidget extends StatefulWidget {
  const ImageSearchWidget({super.key});

  @override
  _ImageSearchWidgetState createState() => _ImageSearchWidgetState();
}

class _ImageSearchWidgetState extends State<ImageSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFieldAgent = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final galleryProvider =
        Provider.of<GalleryProvider>(context, listen: false);
    _selectedFieldAgent = galleryProvider.selectedFieldAgent;
    _fromDate = galleryProvider.fromDate;
    _toDate = galleryProvider.toDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final galleryProvider =
        Provider.of<GalleryProvider>(context, listen: false);
    galleryProvider.setSearchQuery(_searchController.text);
    galleryProvider.setFieldAgentFilter(_selectedFieldAgent);
    galleryProvider.setDateRange(_fromDate, _toDate);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedFieldAgent = 'All';
      _fromDate = null;
      _toDate = null;
    });

    final galleryProvider =
        Provider.of<GalleryProvider>(context, listen: false);
    galleryProvider.clearFilters();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryProvider = Provider.of<GalleryProvider>(context);

    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {});
            _performSearch();
          },
        ),

        const SizedBox(height: 16),

        // Filter row - Stack vertically on small screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Stack vertically on small screens
              return Column(
                children: [
                  // Field agent filter
                  DropdownButtonFormField<String>(
                    value: _selectedFieldAgent,
                    decoration: InputDecoration(
                      labelText: 'Field Agent',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: galleryProvider.fieldAgents.map((agent) {
                      return DropdownMenuItem(
                        value: agent,
                        child: Text(agent),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFieldAgent = value ?? 'All';
                      });
                      _performSearch();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Date filters in a row
                  Row(
                    children: [
                      // From date
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _fromDate != null
                                        ? DateFormat('MMM d, yyyy')
                                            .format(_fromDate!)
                                        : 'From Date',
                                    style: TextStyle(
                                      color: _fromDate != null
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // To date
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _toDate != null
                                        ? DateFormat('MMM d, yyyy')
                                            .format(_toDate!)
                                        : 'To Date',
                                    style: TextStyle(
                                      color: _toDate != null
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Horizontal layout on larger screens
              return Row(
                children: [
                  // Field agent filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedFieldAgent,
                      decoration: InputDecoration(
                        labelText: 'Field Agent',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: galleryProvider.fieldAgents.map((agent) {
                        return DropdownMenuItem(
                          value: agent,
                          child: Text(agent, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFieldAgent = value ?? 'All';
                        });
                        _performSearch();
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // From date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fromDate != null
                                    ? DateFormat('MMM d, yyyy')
                                        .format(_fromDate!)
                                    : 'From Date',
                                style: TextStyle(
                                  color: _fromDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // To date
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _toDate != null
                                    ? DateFormat('MMM d, yyyy').format(_toDate!)
                                    : 'To Date',
                                style: TextStyle(
                                  color: _toDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
