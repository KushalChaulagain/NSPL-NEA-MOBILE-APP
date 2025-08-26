class User {
  final String id;
  final String username;
  final String name;
  final String role;
  final String status;

  User({
    required this.id,
    required this.username,
    required this.name, 
    required this.role,
    required this.status,
  });
        
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      role: json['role'],
      status: json['status'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'status': status,
    };
  }
}
