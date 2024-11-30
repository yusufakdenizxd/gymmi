class UserModel {
  String userId;
  String username;
  String email;
  String password;
  String? pfpUrl;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    this.pfpUrl,
  });

  Map<String, dynamic> toFirebase() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'password': password,
      'pfpUrl': pfpUrl,
    };
  }

  factory UserModel.fromFirebase(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'],
      username: data['username'],
      email: data['email'],
      password: data['password'],
      pfpUrl: data['pfpUrl'],
    );
  }
}
