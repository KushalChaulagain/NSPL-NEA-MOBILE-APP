class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String assignedTo;
  final String meterNumber;
  final DateTime createdAt;
  final List<String> attachments;
  // Additional fields from API
  final String? site;
  final String? meter;
  final String? region;
  final String? month;
  final String? userId;
  final String? meterReading;

  Ticket({
    required this.id,
    this.title = '',
    this.description = '',
    required this.status,
    required this.assignedTo,
    this.meterNumber = '',
    required this.createdAt,
    this.attachments = const [],
    this.site,
    this.meter,
    this.region,
    this.month,
    this.userId,
    this.meterReading,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      assignedTo: json['assignedTo'] ?? '',
      meterNumber: json['meterNumber'] ??
          json['meterSerialNumber'] ??
          json['details']?['meterSerialNumber'] ??
          '',
      createdAt: DateTime.parse(json['createdAt']),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
      // Map additional fields from API
      site: json['site'],
      meter: json['meter'],
      region: json['region'],
      month: json['month'],
      userId: json['userId'],
      meterReading: json['meterReading']?.toString() ??
          json['details']?['meterReading']?.toString() ??
          json['details']?['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'assignedTo': assignedTo,
      'meterNumber': meterNumber,
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
    };

    // Add optional fields if they exist
    if (site != null) data['site'] = site;
    if (meter != null) data['meter'] = meter;
    if (region != null) data['region'] = region;
    if (month != null) data['month'] = month;
    if (userId != null) data['userId'] = userId;
    if (meterReading != null) data['meterReading'] = meterReading;

    return data;
  }
}
