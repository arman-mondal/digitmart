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
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.profileImage,
    this.verificationStatus = true,
    this.rating = 4.8,
    this.completedTransactions = 12,
    this.bidReliability = 98,
    this.locationName = 'New Town, Kolkata',
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Anonymous',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
      verificationStatus: json['verification_status'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      completedTransactions: json['completed_transactions'] as int? ?? 12,
      bidReliability: json['bid_reliability'] as int? ?? 98,
      locationName: json['location_name'] as String? ?? 'New Town, Kolkata',
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
    };
  }
}
