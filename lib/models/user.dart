class User {
  final String id;
  String name;
  String email;
  String role;
  String? phone;
  String? address;
  bool active;

  User({required this.id, required this.name, required this.email, this.role = 'customer', this.phone, this.address, this.active = true});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      address: json['address'],
      active: json['active'] == null ? true : (json['active'] as bool),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'address': address,
    'active': active,
  };
}
