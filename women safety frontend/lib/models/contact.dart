class Contact {
  final String id;
  final String name;
  final String phone;
  final String? relation;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      phone: json['phone'],
      relation: json['relation'],
    );
  }
}
