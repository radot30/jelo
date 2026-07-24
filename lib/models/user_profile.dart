class UserProfile {
  final String id;
  final String uniqueId;
  final String name;
  final String avatar;
  final String bio;
  final String? email;
  final bool isPrivate;
  final double lat;
  final double lon;

  UserProfile({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.avatar,
    required this.bio,
    this.email,
    this.isPrivate = false,
    this.lat = -6.200000,
    this.lon = 106.816666,
  });

  UserProfile copyWith({
    String? name,
    String? avatar,
    String? bio,
    String? email,
    bool? isPrivate,
    double? lat,
    double? lon,
  }) {
    return UserProfile(
      id: id,
      uniqueId: uniqueId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      isPrivate: isPrivate ?? this.isPrivate,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'email': email,
      'is_private': isPrivate ? 1 : 0,
      'lat': lat,
      'lon': lon,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? 'user_default',
      uniqueId: map['unique_id'] ?? 'USR-8392',
      name: map['name'] ?? 'Pengguna',
      avatar: map['avatar'] ?? 'assets/avatars/avatar1.png',
      bio: map['bio'] ?? '',
      email: map['email'],
      isPrivate: (map['is_private'] ?? 0) == 1,
      lat: (map['lat'] as num?)?.toDouble() ?? -6.200000,
      lon: (map['lon'] as num?)?.toDouble() ?? 106.816666,
    );
  }
}
