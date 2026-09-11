/// Defines application roles matching the Supabase `app_role` enum and `user_roles` table.
enum AppRole {
  passenger('passenger'),
  staff('staff'),
  admin('admin'),
  superAdmin('super_admin');

  final String value;
  const AppRole(this.value);

  static AppRole fromString(String role) {
    return switch (role.toLowerCase().trim()) {
      'super_admin' => AppRole.superAdmin,
      'admin' => AppRole.admin,
      'staff' => AppRole.staff,
      _ => AppRole.passenger,
    };
  }

  bool get isPassenger => this == AppRole.passenger;
  bool get isStaff => this == AppRole.staff;
  bool get isAdmin => this == AppRole.admin || this == AppRole.superAdmin;
  bool get isSuperAdmin => this == AppRole.superAdmin;
}
