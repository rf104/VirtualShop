class Seller {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String dob;
  final String profileImage;

  Seller({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.profileImage,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      userId: json["user_id"],
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      dob: json["dob"] ?? "",
      profileImage: json["profile_image"] ?? "",
    );
  }
}
