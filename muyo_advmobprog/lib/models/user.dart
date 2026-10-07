enum LoginType { dummyJson, firebase }

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String contactNo;
  final String gender;
  final String image;
  final String accessToken;
  final LoginType loginType;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age = 0,
    this.contactNo = '',
    required this.gender,
    required this.image,
    required this.accessToken,
    this.loginType = LoginType.dummyJson,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    final ageValue = json['age'];
    final loginTypeValue = json['loginType'];

    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      age: ageValue is num
          ? ageValue.toInt()
          : int.tryParse(ageValue?.toString() ?? '') ?? 0,
      contactNo: (json['contactNo'] ?? json['phone'] ?? '').toString(),
      gender: json['gender'] as String? ?? '',
      image: json['image'] as String? ?? '',
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      loginType: LoginType.values.firstWhere(
        (type) => type.name == loginTypeValue,
        orElse: () => LoginType.dummyJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'age': age,
    'contactNo': contactNo,
    'gender': gender,
    'image': image,
    'accessToken': accessToken,
    'loginType': loginType.name,
  };

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
    String? gender,
    String? image,
    String? accessToken,
    LoginType? loginType,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      contactNo: contactNo ?? this.contactNo,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      accessToken: accessToken ?? this.accessToken,
      loginType: loginType ?? this.loginType,
    );
  }
}
