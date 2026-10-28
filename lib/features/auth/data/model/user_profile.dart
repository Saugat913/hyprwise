enum AuthProvider { google, apple, guest }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.provider,
    this.isPro = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final bool isPro;

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    bool? isPro,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      isPro: isPro ?? this.isPro,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider.name,
        'isPro': isPro,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        provider: AuthProvider.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => AuthProvider.guest,
        ),
        isPro: (json['isPro'] as bool?) ?? false,
      );
}
