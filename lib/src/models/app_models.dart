class DonorProfile {
  const DonorProfile({
    required this.id,
    required this.fullName,
    required this.bloodGroup,
    required this.phone,
    required this.area,
    required this.available,
    required this.age,
    required this.gender,
  });

  final String id;
  final String fullName;
  final String bloodGroup;
  final String phone;
  final String area;
  final bool available;
  final int? age;
  final String gender;

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? 'Unknown').toString(),
      bloodGroup: (json['blood_group'] ?? 'Unknown').toString(),
      phone: (json['phone'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      available: json['available'] == true,
      age: (json['age'] as num?)?.toInt(),
      gender: (json['gender'] ?? '').toString(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String subtitle;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class NearbyHospital {
  const NearbyHospital({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String address;
}
