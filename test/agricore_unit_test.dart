import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agricore/models/models.dart';
import 'package:agricore/services/auth_service.dart';
import 'package:agricore/services/database_service.dart';
import 'package:agricore/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth & Role-Based Permissions Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('Default user accounts populate correctly', () {
      expect(AuthService.demoUsers.length, equals(5));
      expect(AuthService.demoUsers[0].role, equals(UserRole.administrator));
      expect(AuthService.demoUsers[1].role, equals(UserRole.procurement));
    });

    test('Login with valid demo user email succeeds', () async {
      final success = await authService.login('admin@agricore.com', 'password123');
      expect(success, isTrue);
      expect(authService.currentUser?.role, equals(UserRole.administrator));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Login with invalid email fails', () async {
      final success = await authService.login('nonexistent@agricore.com', 'short');
      expect(success, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('Permission inheritance checks work correctly', () async {
      await authService.login('procurement@agricore.com', 'password123');
      expect(authService.hasPermission('campaigns.create'), isTrue);
      expect(authService.hasPermission('users.manage'), isFalse); // Procurement cannot manage users
    });
  });

  group('AI & Anomaly Detection Engine Tests', () {
    test('Normal moisture and quality does not trigger anomalies', () {
      final anomalyResult = AIService.detectAnomaly(
        moisture: 12.5,
        visualScore: 8,
        quantity: 100,
      );
      expect(anomalyResult['isAnomaly'], isFalse);
      expect(anomalyResult['riskScore'], equals(0.0));
    });

    test('High moisture level triggers moisture anomaly warning', () {
      final anomalyResult = AIService.detectAnomaly(
        moisture: 15.2,
        visualScore: 7,
        quantity: 150,
      );
      expect(anomalyResult['isAnomaly'], isTrue);
      expect(anomalyResult['rules'], contains('high_moisture'));
      expect(anomalyResult['riskScore'], greaterThan(0.4));
    });

    test('Poor visual quality triggers quality anomaly warning', () {
      final anomalyResult = AIService.detectAnomaly(
        moisture: 13.0,
        visualScore: 3,
        quantity: 200,
      );
      expect(anomalyResult['isAnomaly'], isTrue);
      expect(anomalyResult['rules'], contains('poor_visual_quality'));
    });
  });

  group('Database & State Machine Approval Tests', () {
    late DatabaseService db;
    late AppUser adminUser;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = DatabaseService();
      // Wait for async shared preferences loading to finish
      while (!db.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      adminUser = AppUser(
        uid: 'test_admin',
        email: 'test_admin@agricore.com',
        fullName: 'Test Admin',
        role: UserRole.administrator,
        permissions: ['campaigns.create', 'warehouse.manage'],
      );
    });

    test('Seed data is loaded and initialized properly', () {
      // SharedPreferences initialization is simulated/mocked in DatabaseService constructor,
      // which defaults to fallback arrays if shared_prefs returns empty.
      expect(db.warehouses.length, greaterThanOrEqualTo(3));
      expect(db.campaigns.length, greaterThanOrEqualTo(3));
    });

    test('Submitting inspection auto-generates approval stages', () async {
      final inspection = Inspection(
        inspectionId: 'TEST-INSP-001',
        campaignId: 'CAMP-2026-WHEAT',
        farmerName: 'Test Farmer',
        farmerPhone: '555-9000',
        farmerAddress: 'Test Farm',
        locationName: 'Plot 1',
        latitude: 39.0,
        longitude: -95.0,
        cropVariety: 'Winter Wheat',
        estimatedQuantity: 100.0,
        moistureLevel: 12.0,
        visualQualityScore: 8,
        notes: 'Good crop',
        imageUrls: [],
        inspectorId: 'test_inspector',
        status: 'completed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.submitInspection(inspection, adminUser);

      // Verify inspection added
      expect(db.inspections.any((i) => i.inspectionId == 'TEST-INSP-001'), isTrue);

      // Verify approval workflow initialized
      final matchingApproval = db.approvals.firstWhere((a) => a.targetId == 'TEST-INSP-001');
      expect(matchingApproval, isNotNull);
      expect(matchingApproval.stages.length, equals(4)); // Quality, Procurement, Management, Warehouse
      expect(matchingApproval.status, equals('pending'));
    });
  });
}
