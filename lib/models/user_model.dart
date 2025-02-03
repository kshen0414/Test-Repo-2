class UserModel {
  final String? id;
  final String fullName;
  final String email;

  const UserModel({
    this.id,
    required this.email,
    required this.fullName,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      "FullName": fullName,
      "Email": email,
    };
  }

  // Create from Firestore JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['FullName'] ?? '',
      email: json['Email'] ?? '',

    );
  }
}

