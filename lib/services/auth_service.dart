import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // List of pre-configured demo users for all primary enterprise roles
  static final List<AppUser> demoUsers = [
    AppUser(
      uid: 'admin_user',
      email: 'admin@agricore.com',
      fullName: 'Alice Vance (Admin)',
      role: UserRole.administrator,
      permissions: [
        'users.manage',
        'workflows.configure',
        'audit.view',
        'campaigns.create',
        'campaigns.view',
        'inspections.assign',
        'inspections.execute',
        'inspections.review',
        'labs.review',
        'labs.grade',
        'warehouse.manage',
        'warehouse.allocate',
        'reports.view',
        'anomalies.review',
      ],
    ),
    AppUser(
      uid: 'procurement_user',
      email: 'procurement@agricore.com',
      fullName: 'Peter Parker (Procurement)',
      role: UserRole.procurement,
      permissions: [
        'campaigns.create',
        'campaigns.view',
        'inspections.assign',
        'inspections.review',
        'approvals.initiate',
        'reports.view',
      ],
    ),
    AppUser(
      uid: 'quality_user',
      email: 'quality@agricore.com',
      fullName: 'Quinn Snyder (Quality)',
      role: UserRole.quality,
      permissions: [
        'campaigns.view',
        'inspections.view',
        'labs.review',
        'labs.grade',
        'documents.upload',
        'reports.view',
      ],
    ),
    AppUser(
      uid: 'warehouse_user',
      email: 'warehouse@agricore.com',
      fullName: 'Wendy Adams (Warehouse)',
      role: UserRole.warehouse,
      permissions: [
        'warehouse.manage',
        'stock.update',
        'documents.upload',
      ],
    ),
    AppUser(
      uid: 'management_user',
      email: 'management@agricore.com',
      fullName: 'Marcus Aurelius (Management)',
      role: UserRole.management,
      permissions: [
        'campaigns.view',
        'inspections.view',
        'labs.review',
        'reports.view',
        'dashboards.view',
        'approvals.approve',
      ],
    ),
  ];

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Simple email lookup for demo users
    final index = demoUsers.indexWhere((u) => u.email.toLowerCase() == email.trim().toLowerCase());
    
    if (index != -1) {
      _currentUser = demoUsers[index];
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Default password-based login for any other email (for test flexibility)
    if (email.contains('@') && password.length >= 6) {
      _currentUser = AppUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: email.split('@')[0].toUpperCase(),
        role: UserRole.procurement,
        permissions: [
          'campaigns.view',
          'inspections.view',
          'reports.view',
        ],
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    // Admins have all permissions implicitly
    if (_currentUser!.role == UserRole.administrator) return true;
    return _currentUser!.permissions.contains(permission);
  }
}
