class UserProfile {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String fullName;
  final String? email;
  final String cellphone;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.cellphone,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      lastName: json['last_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      cellphone: json['cellphone']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}
