class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j["id"] ?? j["_id"], name: j["name"], email: j["email"]);
}
