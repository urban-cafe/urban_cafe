enum UserRole {
  admin,
  staff,
  client;

  String get toStringValue => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.client,
    );
  }
}
