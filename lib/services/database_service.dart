import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DatabaseService extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isOffline = false;
  bool _initialized = false;

  final List<Campaign> _campaigns = [];
  final List<Inspection> _inspections = [];
  final List<LabTest> _labTests = [];
  final List<DocumentModel> _documents = [];
  final List<Anomaly> _anomalies = [];
  final List<Approval> _approvals = [];
  final List<Warehouse> _warehouses = [];
  final List<StockMovement> _stockMovements = [];
  final List<AuditLog> _auditLogs = [];

  // Offline Synchronization Queues
  final List<String> _pendingSyncInspections = [];

  bool get isOffline => _isOffline;
  bool get initialized => _initialized;

  List<Campaign> get campaigns => _campaigns;
  List<Inspection> get inspections => _inspections;
  List<LabTest> get labTests => _labTests;
  List<DocumentModel> get documents => _documents;
  List<Anomaly> get anomalies => _anomalies;
  List<Approval> get approvals => _approvals;
  List<Warehouse> get warehouses => _warehouses;
  List<StockMovement> get stockMovements => _stockMovements;
  List<AuditLog> get auditLogs => _auditLogs;
  List<String> get pendingSyncInspections => _pendingSyncInspections;

  DatabaseService() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load existing local data or initialize seed data
    _loadFromLocal();
    if (_campaigns.isEmpty && _warehouses.isEmpty) {
      _seedInitialData();
    }
    
    _initialized = true;
    notifyListeners();
  }

  void toggleOnlineOffline() {
    _isOffline = !_isOffline;
    if (!_isOffline) {
      // Trigger synchronization when going back online
      syncOfflineData();
    }
    notifyListeners();
  }

  // --- Caching and Local Storage Persistence ---
  void _loadFromLocal() {
    try {
      final campaignsJson = _prefs?.getString('campaigns') ?? '[]';
      final inspectionsJson = _prefs?.getString('inspections') ?? '[]';
      final labTestsJson = _prefs?.getString('lab_tests') ?? '[]';
      final documentsJson = _prefs?.getString('documents') ?? '[]';
      final anomaliesJson = _prefs?.getString('anomalies') ?? '[]';
      final approvalsJson = _prefs?.getString('approvals') ?? '[]';
      final warehousesJson = _prefs?.getString('warehouses') ?? '[]';
      final stockJson = _prefs?.getString('stock_movements') ?? '[]';
      final auditJson = _prefs?.getString('audit_logs') ?? '[]';
      final pendingJson = _prefs?.getString('pending_sync_inspections') ?? '[]';

      _campaigns.clear();
      _campaigns.addAll((jsonDecode(campaignsJson) as List).map((x) => Campaign.fromMap(x)));

      _inspections.clear();
      _inspections.addAll((jsonDecode(inspectionsJson) as List).map((x) => Inspection.fromMap(x)));

      _labTests.clear();
      _labTests.addAll((jsonDecode(labTestsJson) as List).map((x) => LabTest.fromMap(x)));

      _documents.clear();
      _documents.addAll((jsonDecode(documentsJson) as List).map((x) => DocumentModel.fromMap(x)));

      _anomalies.clear();
      _anomalies.addAll((jsonDecode(anomaliesJson) as List).map((x) => Anomaly.fromMap(x)));

      _approvals.clear();
      _approvals.addAll((jsonDecode(approvalsJson) as List).map((x) => Approval.fromMap(x)));

      _warehouses.clear();
      _warehouses.addAll((jsonDecode(warehousesJson) as List).map((x) => Warehouse.fromMap(x)));

      _stockMovements.clear();
      _stockMovements.addAll((jsonDecode(stockJson) as List).map((x) => StockMovement.fromMap(x)));

      _auditLogs.clear();
      _auditLogs.addAll((jsonDecode(auditJson) as List).map((x) => AuditLog.fromMap(x)));

      _pendingSyncInspections.clear();
      _pendingSyncInspections.addAll(List<String>.from(jsonDecode(pendingJson)));
    } catch (e) {
      debugPrint("Error loading data from shared preferences: $e");
    }
  }

  Future<void> _saveToLocal() async {
    if (_prefs == null) return;
    await _prefs!.setString('campaigns', jsonEncode(_campaigns.map((e) => e.toMap()).toList()));
    await _prefs!.setString('inspections', jsonEncode(_inspections.map((e) => e.toMap()).toList()));
    await _prefs!.setString('lab_tests', jsonEncode(_labTests.map((e) => e.toMap()).toList()));
    await _prefs!.setString('documents', jsonEncode(_documents.map((e) => e.toMap()).toList()));
    await _prefs!.setString('anomalies', jsonEncode(_anomalies.map((e) => e.toMap()).toList()));
    await _prefs!.setString('approvals', jsonEncode(_approvals.map((e) => e.toMap()).toList()));
    await _prefs!.setString('warehouses', jsonEncode(_warehouses.map((e) => e.toMap()).toList()));
    await _prefs!.setString('stock_movements', jsonEncode(_stockMovements.map((e) => e.toMap()).toList()));
    await _prefs!.setString('audit_logs', jsonEncode(_auditLogs.map((e) => e.toMap()).toList()));
    await _prefs!.setString('pending_sync_inspections', jsonEncode(_pendingSyncInspections));
  }

  // --- Seed Initial Data ---
  void _seedInitialData() {
    final uuid = const Uuid();
    
    // 1. Seed Warehouses
    final w1 = Warehouse(
      warehouseId: 'WH-KANSAS-01',
      name: 'Topeka Central Silo',
      location: 'Topeka, KS',
      capacity: 10000.0,
      availableQuantity: 4200.0,
      allocatedQuantity: 1500.0,
      incomingQuantity: 800.0,
      outgoingQuantity: 300.0,
      status: 'active',
    );
    final w2 = Warehouse(
      warehouseId: 'WH-IOWA-02',
      name: 'Des Moines Grain Terminal',
      location: 'Des Moines, IA',
      capacity: 15000.0,
      availableQuantity: 12500.0, // High capacity alert target
      allocatedQuantity: 2000.0,
      incomingQuantity: 1200.0,
      outgoingQuantity: 600.0,
      status: 'active',
    );
    final w3 = Warehouse(
      warehouseId: 'WH-ILLINOIS-03',
      name: 'Decatur Processing Depot',
      location: 'Decatur, IL',
      capacity: 8000.0,
      availableQuantity: 1500.0,
      allocatedQuantity: 500.0,
      incomingQuantity: 0.0,
      outgoingQuantity: 100.0,
      status: 'active',
    );
    _warehouses.addAll([w1, w2, w3]);

    // 2. Seed Campaigns
    final c1 = Campaign(
      campaignId: 'CAMP-2026-WHEAT',
      cropType: 'Wheat',
      region: 'Midwest',
      state: 'Kansas',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 60)),
      targetQuantity: 5000.0,
      budget: 1200000.0,
      status: 'active',
      assignedTeam: ['procurement_user', 'quality_user'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      timeline: [
        {'status': 'draft', 'changedBy': 'admin_user', 'timestamp': DateTime.now().subtract(const Duration(days: 35)).toIso8601String(), 'remarks': 'Initial draft created'},
        {'status': 'active', 'changedBy': 'admin_user', 'timestamp': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(), 'remarks': 'Campaign approved and launched'},
      ],
    );
    
    final c2 = Campaign(
      campaignId: 'CAMP-2026-SOY',
      cropType: 'Soybeans',
      region: 'Great Plains',
      state: 'Iowa',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 80)),
      targetQuantity: 8000.0,
      budget: 3200000.0,
      status: 'active',
      assignedTeam: ['procurement_user', 'quality_user', 'warehouse_user'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      timeline: [
        {'status': 'active', 'changedBy': 'admin_user', 'timestamp': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(), 'remarks': 'Campaign started'},
      ],
    );

    final c3 = Campaign(
      campaignId: 'CAMP-2026-CORN',
      cropType: 'Corn',
      region: 'Central',
      state: 'Illinois',
      startDate: DateTime.now().add(const Duration(days: 15)),
      endDate: DateTime.now().add(const Duration(days: 120)),
      targetQuantity: 12000.0,
      budget: 4500000.0,
      status: 'draft',
      assignedTeam: ['procurement_user'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      timeline: [
        {'status': 'draft', 'changedBy': 'procurement_user', 'timestamp': DateTime.now().toIso8601String(), 'remarks': 'Planning phase crop procurement'},
      ],
    );
    _campaigns.addAll([c1, c2, c3]);

    // 3. Seed Inspections
    final ins1 = Inspection(
      inspectionId: 'INSP-001',
      campaignId: 'CAMP-2026-WHEAT',
      farmerName: 'John Miller',
      farmerPhone: '555-0199',
      farmerAddress: '742 Evergreen Terrace, Topeka, KS',
      locationName: 'Miller Grain Homestead',
      latitude: 39.0483,
      longitude: -95.6780,
      cropVariety: 'Hard Red Winter Wheat',
      estimatedQuantity: 250.0,
      moistureLevel: 12.8, // Normal
      visualQualityScore: 8,
      notes: 'Excellent yield estimate. Fields look clean, crop is dry.',
      imageUrls: ['https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b'],
      inspectorId: 'procurement_user',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    final ins2 = Inspection(
      inspectionId: 'INSP-002',
      campaignId: 'CAMP-2026-SOY',
      farmerName: 'Sarah Jenkins',
      farmerPhone: '555-0234',
      farmerAddress: 'Route 6, Ames, IA',
      locationName: 'Jenkins Family Farms',
      latitude: 42.0308,
      longitude: -93.6319,
      cropVariety: 'Glycine Max Seedlings',
      estimatedQuantity: 400.0,
      moistureLevel: 17.5, // ANOMALY: Abnormal moisture (standard for soy should be <14%)
      visualQualityScore: 5,
      notes: 'Slightly damp due to recent rains. Will need monitoring.',
      imageUrls: ['https://images.unsplash.com/photo-1530595467537-0b5996c41f2d'],
      inspectorId: 'procurement_user',
      status: 'flagged',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _inspections.addAll([ins1, ins2]);

    // 4. Seed Anomalies
    final anom = Anomaly(
      anomalyId: 'ANOM-101',
      targetType: 'inspection',
      targetId: 'INSP-002',
      riskScore: 0.85,
      explanation: 'Critical moisture levels (17.5%) detected. Standard threshold for Soybeans is 13.0% maximum. Processing this crop immediately may lead to storage decay and silo spoilage.',
      detectedRules: ['moisture_outlier', 'spoilage_risk'],
      status: 'flagged',
      reviewNotes: '',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _anomalies.add(anom);

    // 5. Seed Laboratory Tests
    final lab1 = LabTest(
      sampleId: 'SMPL-001',
      inspectionId: 'INSP-001',
      testType: 'Standard Wheat Quality',
      moisture: 12.5,
      purity: 98.5,
      contamination: 0.8,
      grade: 'A',
      remarks: 'High protein content, excellent purity index. Approved for Grade A storage.',
      certificateUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      ocrMetadata: {
        'certificateNumber': 'CERT-2026-9041',
        'laboratoryName': 'Midwest Agronomy Labs',
        'purityPercent': '98.5%',
        'testDate': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      },
      ocrVerified: true,
      testerId: 'quality_user',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    );
    _labTests.add(lab1);

    // 6. Seed Approvals
    final app1 = Approval(
      approvalId: 'APP-001',
      targetType: 'purchase_contract',
      targetId: 'INSP-001',
      currentStage: 'procurement_approval',
      stages: [
        ApprovalStage(stageName: 'Quality Review', assignedRole: UserRole.quality, status: 'approved', actorId: 'quality_user', timestamp: DateTime.now().subtract(const Duration(days: 3)), notes: 'Sample SMPL-001 looks great. Assigned Grade A.'),
        ApprovalStage(stageName: 'Procurement Approval', assignedRole: UserRole.procurement, status: 'pending', notes: ''),
        ApprovalStage(stageName: 'Management Approval', assignedRole: UserRole.management, status: 'pending', notes: ''),
        ApprovalStage(stageName: 'Warehouse Allocation', assignedRole: UserRole.warehouse, status: 'pending', notes: ''),
      ],
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _approvals.add(app1);

    // 7. Seed Audit Logs
    final alog = AuditLog(
      logId: 'AUD-001',
      userId: 'admin_user',
      userEmail: 'admin@agricore.com',
      action: 'workflow_change',
      targetCollection: 'campaigns',
      targetId: 'CAMP-2026-WHEAT',
      before: {'status': 'draft'},
      after: {'status': 'active'},
      timestamp: DateTime.now().subtract(const Duration(days: 30)),
    );
    _auditLogs.add(alog);

    _saveToLocal();
  }

  // --- Synchronization of Offline Operations ---
  Future<void> syncOfflineData() async {
    if (_isOffline || _pendingSyncInspections.isEmpty) return;

    // Simulate network latency for synchronization
    await Future.delayed(const Duration(seconds: 2));

    for (var inspectionId in List<String>.from(_pendingSyncInspections)) {
      final index = _inspections.indexWhere((i) => i.inspectionId == inspectionId);
      if (index != -1) {
        final inspection = _inspections[index];
        // 1. Mark status as completed
        final updated = Inspection(
          inspectionId: inspection.inspectionId,
          campaignId: inspection.campaignId,
          farmerName: inspection.farmerName,
          farmerPhone: inspection.farmerPhone,
          farmerAddress: inspection.farmerAddress,
          locationName: inspection.locationName,
          latitude: inspection.latitude,
          longitude: inspection.longitude,
          cropVariety: inspection.cropVariety,
          estimatedQuantity: inspection.estimatedQuantity,
          moistureLevel: inspection.moistureLevel,
          visualQualityScore: inspection.visualQualityScore,
          notes: inspection.notes,
          imageUrls: inspection.imageUrls,
          inspectorId: inspection.inspectorId,
          status: 'completed',
          createdAt: inspection.createdAt,
          updatedAt: DateTime.now(),
        );
        _inspections[index] = updated;

        // 2. Automatically check for anomalies
        _evaluateAnomalyForInspection(updated);

        // 3. Create Approval Workflow
        final newApproval = Approval(
          approvalId: 'APP-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          targetType: 'purchase_contract',
          targetId: updated.inspectionId,
          currentStage: 'quality_review',
          stages: [
            ApprovalStage(stageName: 'Quality Review', assignedRole: UserRole.quality, status: 'pending', notes: ''),
            ApprovalStage(stageName: 'Procurement Approval', assignedRole: UserRole.procurement, status: 'pending', notes: ''),
            ApprovalStage(stageName: 'Management Approval', assignedRole: UserRole.management, status: 'pending', notes: ''),
            ApprovalStage(stageName: 'Warehouse Allocation', assignedRole: UserRole.warehouse, status: 'pending', notes: ''),
          ],
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _approvals.add(newApproval);

        // 4. Log sync in audit trail
        _logAuditAction(
          userId: updated.inspectorId,
          userEmail: '${updated.inspectorId}@agricore.com',
          action: 'create',
          targetCollection: 'inspections',
          targetId: updated.inspectionId,
          before: {},
          after: updated.toMap(),
        );
      }
    }

    _pendingSyncInspections.clear();
    await _saveToLocal();
    notifyListeners();
  }

  // --- Campaign Operations ---
  Future<void> addCampaign(Campaign campaign, AppUser user) async {
    _campaigns.add(campaign);
    _logAuditAction(
      userId: user.uid,
      userEmail: user.email,
      action: 'create',
      targetCollection: 'campaigns',
      targetId: campaign.campaignId,
      before: {},
      after: campaign.toMap(),
    );
    await _saveToLocal();
    notifyListeners();
  }

  Future<void> updateCampaign(Campaign campaign, AppUser user) async {
    final index = _campaigns.indexWhere((c) => c.campaignId == campaign.campaignId);
    if (index != -1) {
      final beforeMap = _campaigns[index].toMap();
      _campaigns[index] = campaign;
      _logAuditAction(
        userId: user.uid,
        userEmail: user.email,
        action: 'update',
        targetCollection: 'campaigns',
        targetId: campaign.campaignId,
        before: beforeMap,
        after: campaign.toMap(),
      );
      await _saveToLocal();
      notifyListeners();
    }
  }

  // --- Field Inspection Operations ---
  Future<void> submitInspection(Inspection inspection, AppUser user) async {
    if (_isOffline) {
      // In offline mode, save locally in cached state and queue for synchronization
      final offlineInspection = Inspection(
        inspectionId: inspection.inspectionId,
        campaignId: inspection.campaignId,
        farmerName: inspection.farmerName,
        farmerPhone: inspection.farmerPhone,
        farmerAddress: inspection.farmerAddress,
        locationName: inspection.locationName,
        latitude: inspection.latitude,
        longitude: inspection.longitude,
        cropVariety: inspection.cropVariety,
        estimatedQuantity: inspection.estimatedQuantity,
        moistureLevel: inspection.moistureLevel,
        visualQualityScore: inspection.visualQualityScore,
        notes: inspection.notes,
        imageUrls: inspection.imageUrls,
        inspectorId: inspection.inspectorId,
        status: 'cached_offline',
        createdAt: inspection.createdAt,
        updatedAt: inspection.updatedAt,
      );
      _inspections.add(offlineInspection);
      _pendingSyncInspections.add(offlineInspection.inspectionId);
      await _saveToLocal();
      notifyListeners();
      return;
    }

    // Online flow
    _inspections.add(inspection);

    // 1. Audit
    _logAuditAction(
      userId: user.uid,
      userEmail: user.email,
      action: 'create',
      targetCollection: 'inspections',
      targetId: inspection.inspectionId,
      before: {},
      after: inspection.toMap(),
    );

    // 2. Anomaly evaluation
    _evaluateAnomalyForInspection(inspection);

    // 3. Approval cycle initialization
    final newApproval = Approval(
      approvalId: 'APP-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      targetType: 'purchase_contract',
      targetId: inspection.inspectionId,
      currentStage: 'quality_review',
      stages: [
        ApprovalStage(stageName: 'Quality Review', assignedRole: UserRole.quality, status: 'pending', notes: ''),
        ApprovalStage(stageName: 'Procurement Approval', assignedRole: UserRole.procurement, status: 'pending', notes: ''),
        ApprovalStage(stageName: 'Management Approval', assignedRole: UserRole.management, status: 'pending', notes: ''),
        ApprovalStage(stageName: 'Warehouse Allocation', assignedRole: UserRole.warehouse, status: 'pending', notes: ''),
      ],
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _approvals.add(newApproval);

    await _saveToLocal();
    notifyListeners();
  }

  void _evaluateAnomalyForInspection(Inspection insp) {
    // Anomaly Rule 1: High Moisture Level (e.g. Soybeans > 14.5%, Wheat > 13.5%, other > 14.0%)
    bool isAnomaly = false;
    List<String> rules = [];
    String explanation = '';
    double riskScore = 0.0;

    if (insp.moistureLevel > 14.5) {
      isAnomaly = true;
      rules.add('excessive_moisture');
      explanation += 'Moisture value of ${insp.moistureLevel}% exceeds quality standard limit (14.0%). Crop storage poses high risk of fungal contamination and spoilage. ';
      riskScore += 0.50;
    }

    // Anomaly Rule 2: Low Visual Quality Score with High Quantity
    if (insp.visualQualityScore < 4 && insp.estimatedQuantity > 300) {
      isAnomaly = true;
      rules.add('quality_quantity_discrepancy');
      explanation += 'Large harvest estimate (${insp.estimatedQuantity} MT) with low visual grade (${insp.visualQualityScore}/10). Buying this quantity carries financial risk. ';
      riskScore += 0.40;
    }

    if (isAnomaly) {
      final anomaly = Anomaly(
        anomalyId: 'ANOM-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        targetType: 'inspection',
        targetId: insp.inspectionId,
        riskScore: riskScore.clamp(0.1, 0.95),
        explanation: explanation,
        detectedRules: rules,
        status: 'flagged',
        reviewNotes: '',
        createdAt: DateTime.now(),
      );
      _anomalies.add(anomaly);

      // Update inspection status to flagged
      final idx = _inspections.indexWhere((i) => i.inspectionId == insp.inspectionId);
      if (idx != -1) {
        _inspections[idx] = Inspection(
          inspectionId: insp.inspectionId,
          campaignId: insp.campaignId,
          farmerName: insp.farmerName,
          farmerPhone: insp.farmerPhone,
          farmerAddress: insp.farmerAddress,
          locationName: insp.locationName,
          latitude: insp.latitude,
          longitude: insp.longitude,
          cropVariety: insp.cropVariety,
          estimatedQuantity: insp.estimatedQuantity,
          moistureLevel: insp.moistureLevel,
          visualQualityScore: insp.visualQualityScore,
          notes: insp.notes,
          imageUrls: insp.imageUrls,
          inspectorId: insp.inspectorId,
          status: 'flagged',
          createdAt: insp.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  // --- Laboratory Testing Operations ---
  Future<void> submitLabTest(LabTest labTest, AppUser user) async {
    _labTests.add(labTest);
    
    // Evaluate anomalies in lab records
    _evaluateAnomalyForLab(labTest);

    // Update approval stages linked to this sample
    if (labTest.inspectionId != null) {
      final appIdx = _approvals.indexWhere((a) => a.targetId == labTest.inspectionId);
      if (appIdx != -1) {
        final approval = _approvals[appIdx];
        final updatedStages = approval.stages.map((stage) {
          if (stage.stageName == 'Quality Review') {
            return ApprovalStage(
              stageName: stage.stageName,
              assignedRole: stage.assignedRole,
              status: labTest.grade == 'Fail' ? 'rejected' : 'approved',
              actorId: user.uid,
              timestamp: DateTime.now(),
              notes: 'Lab result submitted. Grade: ${labTest.grade}. Purity: ${labTest.purity}%. Moisture: ${labTest.moisture}%. Contamination: ${labTest.contamination}%. Remarks: ${labTest.remarks}',
            );
          }
          return stage;
        }).toList();

        // If rejected, set main approval status to rejected
        String newStatus = approval.status;
        String nextStage = approval.currentStage;
        if (labTest.grade == 'Fail') {
          newStatus = 'rejected';
        } else {
          nextStage = 'procurement_approval';
        }

        _approvals[appIdx] = Approval(
          approvalId: approval.approvalId,
          targetType: approval.targetType,
          targetId: approval.targetId,
          currentStage: nextStage,
          stages: updatedStages,
          status: newStatus,
          createdAt: approval.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }

    _logAuditAction(
      userId: user.uid,
      userEmail: user.email,
      action: 'create',
      targetCollection: 'lab_tests',
      targetId: labTest.sampleId,
      before: {},
      after: labTest.toMap(),
    );

    await _saveToLocal();
    notifyListeners();
  }

  void _evaluateAnomalyForLab(LabTest test) {
    bool isAnomaly = false;
    List<String> rules = [];
    String explanation = '';
    double riskScore = 0.0;

    if (test.contamination > 3.0) {
      isAnomaly = true;
      rules.add('high_contamination');
      explanation += 'Contamination index of ${test.contamination}% is far above standard margin of 1.5%. Sample contains severe foreign body presence. ';
      riskScore += 0.60;
    }

    if (test.purity < 90.0) {
      isAnomaly = true;
      rules.add('low_purity');
      explanation += 'Purity level of ${test.purity}% is below acceptable minimum (95%). Seed mixture suspected. ';
      riskScore += 0.50;
    }

    if (isAnomaly) {
      final anomaly = Anomaly(
        anomalyId: 'ANOM-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        targetType: 'lab_test',
        targetId: test.sampleId,
        riskScore: riskScore.clamp(0.1, 0.95),
        explanation: explanation,
        detectedRules: rules,
        status: 'flagged',
        reviewNotes: '',
        createdAt: DateTime.now(),
      );
      _anomalies.add(anomaly);
    }
  }

  // --- Anomaly Operations ---
  Future<void> reviewAnomaly(String anomalyId, String status, String reviewNotes, AppUser user) async {
    final index = _anomalies.indexWhere((a) => a.anomalyId == anomalyId);
    if (index != -1) {
      final oldAnomaly = _anomalies[index];
      _anomalies[index] = Anomaly(
        anomalyId: oldAnomaly.anomalyId,
        targetType: oldAnomaly.targetType,
        targetId: oldAnomaly.targetId,
        riskScore: oldAnomaly.riskScore,
        explanation: oldAnomaly.explanation,
        detectedRules: oldAnomaly.detectedRules,
        status: status, // approved (override/resolve) | rejected (confirm anomaly)
        reviewedBy: user.uid,
        reviewNotes: reviewNotes,
        createdAt: oldAnomaly.createdAt,
      );

      // Audit log
      _logAuditAction(
        userId: user.uid,
        userEmail: user.email,
        action: 'review_anomaly',
        targetCollection: 'anomalies',
        targetId: anomalyId,
        before: oldAnomaly.toMap(),
        after: _anomalies[index].toMap(),
      );

      // If resolved (approved), let's clear the flag from the target inspection
      if (status == 'approved' && oldAnomaly.targetType == 'inspection') {
        final inspIdx = _inspections.indexWhere((i) => i.inspectionId == oldAnomaly.targetId);
        if (inspIdx != -1) {
          final inspection = _inspections[inspIdx];
          _inspections[inspIdx] = Inspection(
            inspectionId: inspection.inspectionId,
            campaignId: inspection.campaignId,
            farmerName: inspection.farmerName,
            farmerPhone: inspection.farmerPhone,
            farmerAddress: inspection.farmerAddress,
            locationName: inspection.locationName,
            latitude: inspection.latitude,
            longitude: inspection.longitude,
            cropVariety: inspection.cropVariety,
            estimatedQuantity: inspection.estimatedQuantity,
            moistureLevel: inspection.moistureLevel,
            visualQualityScore: inspection.visualQualityScore,
            notes: inspection.notes,
            imageUrls: inspection.imageUrls,
            inspectorId: inspection.inspectorId,
            status: 'completed', // Reset to normal completed
            createdAt: inspection.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }

      await _saveToLocal();
      notifyListeners();
    }
  }

  // --- Document / File Operations ---
  Future<void> uploadDocument(DocumentModel doc, AppUser user) async {
    _documents.add(doc);
    _logAuditAction(
      userId: user.uid,
      userEmail: user.email,
      action: 'create',
      targetCollection: 'documents',
      targetId: doc.documentId,
      before: {},
      after: doc.toMap(),
    );
    await _saveToLocal();
    notifyListeners();
  }

  Future<void> overrideDocumentCategory(String documentId, String newCategory, AppUser user) async {
    final idx = _documents.indexWhere((d) => d.documentId == documentId);
    if (idx != -1) {
      final doc = _documents[idx];
      final oldMap = doc.toMap();
      _documents[idx] = DocumentModel(
        documentId: doc.documentId,
        fileName: doc.fileName,
        fileUrl: doc.fileUrl,
        fileType: doc.fileType,
        category: newCategory,
        confidenceScore: doc.confidenceScore,
        humanOverride: true,
        uploaderId: doc.uploaderId,
        tags: doc.tags,
        createdAt: doc.createdAt,
      );
      _logAuditAction(
        userId: user.uid,
        userEmail: user.email,
        action: 'override_doc_category',
        targetCollection: 'documents',
        targetId: documentId,
        before: oldMap,
        after: _documents[idx].toMap(),
      );
      await _saveToLocal();
      notifyListeners();
    }
  }

  // --- Multi-Stage Approval Engine ---
  Future<void> submitApprovalDecision(String approvalId, String stageName, String decision, String notes, AppUser user) async {
    final index = _approvals.indexWhere((a) => a.approvalId == approvalId);
    if (index != -1) {
      final approval = _approvals[index];
      final oldMap = approval.toMap();

      // Update stage details
      final updatedStages = approval.stages.map((stage) {
        if (stage.stageName.toLowerCase().trim() == stageName.toLowerCase().trim()) {
          return ApprovalStage(
            stageName: stage.stageName,
            assignedRole: stage.assignedRole,
            status: decision, // approved | rejected
            actorId: user.uid,
            timestamp: DateTime.now(),
            notes: notes,
          );
        }
        return stage;
      }).toList();

      // Determine next workflow stage and general status
      String generalStatus = 'pending';
      String currentStage = approval.currentStage;

      if (decision == 'rejected') {
        generalStatus = 'rejected';
      } else {
        // Proceed to next stage in state machine
        if (stageName == 'Quality Review') {
          currentStage = 'procurement_approval';
        } else if (stageName == 'Procurement Approval') {
          currentStage = 'management_approval';
        } else if (stageName == 'Management Approval') {
          currentStage = 'warehouse_allocation';
        } else if (stageName == 'Warehouse Allocation') {
          generalStatus = 'approved';
          
          // Execute actual stock allocation on warehouse database!
          _executeStockAllocationForApproval(approval.targetId, user);
        }
      }

      _approvals[index] = Approval(
        approvalId: approval.approvalId,
        targetType: approval.targetType,
        targetId: approval.targetId,
        currentStage: currentStage,
        stages: updatedStages,
        status: generalStatus,
        createdAt: approval.createdAt,
        updatedAt: DateTime.now(),
      );

      _logAuditAction(
        userId: user.uid,
        userEmail: user.email,
        action: 'approval_decision',
        targetCollection: 'approvals',
        targetId: approvalId,
        before: oldMap,
        after: _approvals[index].toMap(),
      );

      await _saveToLocal();
      notifyListeners();
    }
  }

  void _executeStockAllocationForApproval(String inspectionId, AppUser user) {
    // Fetch inspection details
    final inspIdx = _inspections.indexWhere((i) => i.inspectionId == inspectionId);
    if (inspIdx == -1) return;
    final inspection = _inspections[inspIdx];

    // Find the campaign and crop type
    final campIdx = _campaigns.indexWhere((c) => c.campaignId == inspection.campaignId);
    if (campIdx == -1) return;
    final campaign = _campaigns[campIdx];

    // Determine target warehouse based on location
    String targetWhId = 'WH-KANSAS-01'; // Default
    if (campaign.state.toLowerCase() == 'kansas') {
      targetWhId = 'WH-KANSAS-01';
    } else if (campaign.state.toLowerCase() == 'iowa') {
      targetWhId = 'WH-IOWA-02';
    } else if (campaign.state.toLowerCase() == 'illinois') {
      targetWhId = 'WH-ILLINOIS-03';
    }

    // Allocate stock
    final whIdx = _warehouses.indexWhere((w) => w.warehouseId == targetWhId);
    if (whIdx != -1) {
      final warehouse = _warehouses[whIdx];
      
      // Update quantities
      _warehouses[whIdx] = Warehouse(
        warehouseId: warehouse.warehouseId,
        name: warehouse.name,
        location: warehouse.location,
        capacity: warehouse.capacity,
        availableQuantity: warehouse.availableQuantity + inspection.estimatedQuantity,
        allocatedQuantity: warehouse.allocatedQuantity + inspection.estimatedQuantity,
        incomingQuantity: (warehouse.incomingQuantity - inspection.estimatedQuantity).clamp(0.0, 99999.0),
        outgoingQuantity: warehouse.outgoingQuantity,
        status: warehouse.status,
      );

      // Create Stock Movement log
      final movement = StockMovement(
        movementId: 'MVT-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        warehouseId: targetWhId,
        type: 'incoming',
        quantity: inspection.estimatedQuantity,
        referenceType: 'inspection',
        referenceId: inspectionId,
        remarks: 'Auto-allocation on approval completion for crop: ${campaign.cropType} (${inspection.cropVariety})',
        recordedBy: user.uid,
        timestamp: DateTime.now(),
      );
      _stockMovements.add(movement);
    }
  }

  // --- Warehouse Master Data Operations ---
  Future<void> recordStockMovement(StockMovement mvt, AppUser user) async {
    _stockMovements.add(mvt);

    // Apply movement changes to Warehouse quantities
    final whIdx = _warehouses.indexWhere((w) => w.warehouseId == mvt.warehouseId);
    if (whIdx != -1) {
      final warehouse = _warehouses[whIdx];
      double available = warehouse.availableQuantity;
      double allocated = warehouse.allocatedQuantity;
      double incoming = warehouse.incomingQuantity;
      double outgoing = warehouse.outgoingQuantity;

      switch (mvt.type) {
        case 'incoming':
          available += mvt.quantity;
          break;
        case 'outgoing':
          available = (available - mvt.quantity).clamp(0.0, 999999.0);
          allocated = (allocated - mvt.quantity).clamp(0.0, 999999.0);
          break;
        case 'allocation_hold':
          allocated += mvt.quantity;
          break;
        case 'allocation_release':
          allocated = (allocated - mvt.quantity).clamp(0.0, 999999.0);
          break;
      }

      _warehouses[whIdx] = Warehouse(
        warehouseId: warehouse.warehouseId,
        name: warehouse.name,
        location: warehouse.location,
        capacity: warehouse.capacity,
        availableQuantity: available,
        allocatedQuantity: allocated,
        incomingQuantity: incoming,
        outgoingQuantity: outgoing,
        status: warehouse.status,
      );
    }

    _logAuditAction(
      userId: user.uid,
      userEmail: user.email,
      action: 'stock_movement',
      targetCollection: 'warehouses',
      targetId: mvt.warehouseId,
      before: {},
      after: mvt.toMap(),
    );

    await _saveToLocal();
    notifyListeners();
  }

  // --- Audit Log Utility ---
  void _logAuditAction({
    required String userId,
    required String userEmail,
    required String action,
    required String targetCollection,
    required String targetId,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) {
    final log = AuditLog(
      logId: 'AUD-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      userId: userId,
      userEmail: userEmail,
      action: action,
      targetCollection: targetCollection,
      targetId: targetId,
      before: before,
      after: after,
      timestamp: DateTime.now(),
    );
    _auditLogs.insert(0, log); // New logs at top
  }
}
