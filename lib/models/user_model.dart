// lib/models/user_model.dart
class UserModel {
  final String id; // Random ID
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    phone: map['phone'] as String,
    photoUrl: map['photoUrl'] as String?,
  );
}
