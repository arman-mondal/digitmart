class ProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? profileImage;
  final bool verificationStatus;
  final double rating;
  final int completedTransactions;
  final int bidReliability;
  final String locationName;
  final bool isAdmin;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.profileImage,
    this.verificationStatus = true,
    this.rating = 5.0,
    this.completedTransactions = 0,
    this.bidReliability = 100,
    this.locationName = 'Kolkata, West Bengal',
    this.isAdmin = false,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Anonymous',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
      verificationStatus: json['verification_status'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedTransactions: json['completed_transactions'] as int? ?? 0,
      bidReliability: json['bid_reliability'] as int? ?? 100,
      locationName: json['location_name'] as String? ?? 'Kolkata, West Bengal',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profile_image': profileImage,
      'verification_status': verificationStatus,
      'rating': rating,
      'completed_transactions': completedTransactions,
      'bid_reliability': bidReliability,
      'location_name': locationName,
      'is_admin': isAdmin,
    };
  }
}
