class UserProfile {

  const UserProfile({
    this.name,
    this.email,
    this.photoPath,
    this.photoUpdatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      email: json['email'],
      photoPath: json['photoPath'],
      photoUpdatedAt: json['photoUpdatedAt'],
    );
  }
  final String? name;
  final String? email;
  final String? photoPath;
  final int? photoUpdatedAt;

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoPath,
    int? photoUpdatedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoPath': photoPath,
      'photoUpdatedAt': photoUpdatedAt,
    };
  }

  String get initials {
    if (name == null || name!.isEmpty) return '?';
    
    final words = name!.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  bool get isComplete => name != null && name!.isNotEmpty;

  @override
  String toString() {
    return 'UserProfile(name: $name, email: $email, hasPhoto: $hasPhoto)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserProfile &&
        other.name == name &&
        other.email == email &&
        other.photoPath == photoPath &&
        other.photoUpdatedAt == photoUpdatedAt;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        photoPath.hashCode ^
        photoUpdatedAt.hashCode;
  }
}

