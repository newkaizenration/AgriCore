import 'package:uuid/uuid.dart';

enum UserRole {
  administrator,
  procurement,
  quality,
  warehouse,
  management,
}

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final List<String> permissions;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'permissions': permissions,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.procurement,
      ),
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }
}

class Campaign {
  final String campaignId;
  final String cropType;
  final String region;
  final String state;
  final DateTime startDate;
  final DateTime endDate;
  final double targetQuantity;
  final double budget;
  final String status; // draft | active | completed | cancelled
  final List<String> assignedTeam;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> timeline;

  Campaign({
    required this.campaignId,
    required this.cropType,
    required this.region,
    required this.state,
    required this.startDate,
    required this.endDate,
    required this.targetQuantity,
    required this.budget,
    required this.status,
    required this.assignedTeam,
    required this.createdAt,
    required this.updatedAt,
    required this.timeline,
  });

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'cropType': cropType,
      'region': region,
      'state': state,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetQuantity': targetQuantity,
      'budget': budget,
      'status': status,
      'assignedTeam': assignedTeam,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timeline': timeline,
    };
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      campaignId: map['campaignId'] ?? '',
      cropType: map['cropType'] ?? '',
      region: map['region'] ?? '',
      state: map['state'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      targetQuantity: (map['targetQuantity'] ?? 0).toDouble(),
      budget: (map['budget'] ?? 0).toDouble(),
      status: map['status'] ?? 'draft',
      assignedTeam: List<String>.from(map['assignedTeam'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      timeline: List<Map<String, dynamic>>.from(
        (map['timeline'] as List?)?.map((item) => Map<String, dynamic>.from(item)) ?? [],
      ),
    );
  }
}

class Inspection {
  final String inspectionId;
  final String campaignId;
  final String farmerName;
  final String farmerPhone;
  final String farmerAddress;
  final String locationName;
  final double latitude;
  final double longitude;
  final String cropVariety;
  final double estimatedQuantity;
  final double moistureLevel;
  final int visualQualityScore;
  final String notes;
  final List<String> imageUrls;
  final String inspectorId;
  final String status; // assigned | inProgress | completed | flagged
  final DateTime createdAt;
  final DateTime updatedAt;

  Inspection({
    required this.inspectionId,
    required this.campaignId,
    required this.farmerName,
    required this.farmerPhone,
    required this.farmerAddress,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.cropVariety,
    required this.estimatedQuantity,
    required this.moistureLevel,
    required this.visualQualityScore,
    required this.notes,
    required this.imageUrls,
    required this.inspectorId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'inspectionId': inspectionId,
      'campaignId': campaignId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'farmerAddress': farmerAddress,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'cropVariety': cropVariety,
      'estimatedQuantity': estimatedQuantity,
      'moistureLevel': moistureLevel,
      'visualQualityScore': visualQualityScore,
      'notes': notes,
      'imageUrls': imageUrls,
      'inspectorId': inspectorId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      inspectionId: map['inspectionId'] ?? '',
      campaignId: map['campaignId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      farmerAddress: map['farmerAddress'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      cropVariety: map['cropVariety'] ?? '',
      estimatedQuantity: (map['estimatedQuantity'] ?? 0).toDouble(),
      moistureLevel: (map['moistureLevel'] ?? 0).toDouble(),
      visualQualityScore: map['visualQualityScore'] ?? 5,
      notes: map['notes'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      inspectorId: map['inspectorId'] ?? '',
      status: map['status'] ?? 'assigned',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class LabTest {
  final String sampleId;
  final String? inspectionId;
  final String testType;
  final double moisture;
  final double purity;
  final double contamination;
  final String grade; // A | B | C | D | Fail
  final String remarks;
  final String certificateUrl;
  final Map<String, dynamic>? ocrMetadata;
  final bool ocrVerified;
  final String testerId;
  final DateTime createdAt;

  LabTest({
    required this.sampleId,
    this.inspectionId,
    required this.testType,
    required this.moisture,
    required this.purity,
    required this.contamination,
    required this.grade,
    required this.remarks,
    required this.certificateUrl,
    this.ocrMetadata,
    required this.ocrVerified,
    required this.testerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleId': sampleId,
      'inspectionId': inspectionId,
      'testType': testType,
      'moisture': moisture,
      'purity': purity,
      'contamination': contamination,
      'grade': grade,
      'remarks': remarks,
      'certificateUrl': certificateUrl,
      'ocrMetadata': ocrMetadata,
      'ocrVerified': ocrVerified,
      'testerId': testerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LabTest.fromMap(Map<String, dynamic> map) {
    return LabTest(
      sampleId: map['sampleId'] ?? '',
      inspectionId: map['inspectionId'],
      testType: map['testType'] ?? '',
      moisture: (map['moisture'] ?? 0).toDouble(),
      purity: (map['purity'] ?? 0).toDouble(),
      contamination: (map['contamination'] ?? 0).toDouble(),
      grade: map['grade'] ?? 'Fail',
      remarks: map['remarks'] ?? '',
      certificateUrl: map['certificateUrl'] ?? '',
      ocrMetadata: map['ocrMetadata'] != null ? Map<String, dynamic>.from(map['ocrMetadata']) : null,
      ocrVerified: map['ocrVerified'] ?? false,
      testerId: map['testerId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class DocumentModel {
  final String documentId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String category; // inspection_report | lab_certificate | purchase_approval | warehouse_doc | misc
  final double confidenceScore;
  final bool humanOverride;
  final String uploaderId;
  final List<String> tags;
  final DateTime createdAt;

  DocumentModel({
    required this.documentId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.category,
    required this.confidenceScore,
    required this.humanOverride,
    required this.uploaderId,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'category': category,
      'confidenceScore': confidenceScore,
      'humanOverride': humanOverride,
      'uploaderId': uploaderId,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      documentId: map['documentId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      category: map['category'] ?? 'misc',
      confidenceScore: (map['confidenceScore'] ?? 0).toDouble(),
      humanOverride: map['humanOverride'] ?? false,
      uploaderId: map['uploaderId'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Anomaly {
  final String anomalyId;
  final String targetType; // inspection | lab_test | campaign
  final String targetId;
  final double riskScore;
  final String explanation;
  final List<String> detectedRules;
  final String status; // flagged | approved | rejected
  final String? reviewedBy;
  final String reviewNotes;
  final DateTime createdAt;

  Anomaly({
    required this.anomalyId,
    required this.targetType,
    required this.targetId,
    required this.riskScore,
    required this.explanation,
    required this.detectedRules,
    required this.status,
    this.reviewedBy,
    required this.reviewNotes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'anomalyId': anomalyId,
      'targetType': targetType,
      'targetId': targetId,
      'riskScore': riskScore,
      'explanation': explanation,
      'detectedRules': detectedRules,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Anomaly.fromMap(Map<String, dynamic> map) {
    return Anomaly(
      anomalyId: map['anomalyId'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      riskScore: (map['riskScore'] ?? 0).toDouble(),
      explanation: map['explanation'] ?? '',
      detectedRules: List<String>.from(map['detectedRules'] ?? []),
      status: map['status'] ?? 'flagged',
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ApprovalStage {
  final String stageName; // e.g. quality_review, procurement_approval, etc.
  final UserRole assignedRole;
  final String status; // pending | approved | rejected
  final String? actorId;
  final DateTime? timestamp;
  final String notes;

  ApprovalStage({
    required this.stageName,
    required this.assignedRole,
    required this.status,
    this.actorId,
    this.timestamp,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'stageName': stageName,
      'assignedRole': assignedRole.name,
      'status': status,
      'actorId': actorId,
      'timestamp': timestamp?.toIso8601String(),
      'notes': notes,
    };
  }

  factory ApprovalStage.fromMap(Map<String, dynamic> map) {
    return ApprovalStage(
      stageName: map['stageName'] ?? '',
      assignedRole: UserRole.values.firstWhere(
        (e) => e.name == map['assignedRole'],
        orElse: () => UserRole.procurement,
      ),
      status: map['status'] ?? 'pending',
      actorId: map['actorId'],
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
      notes: map['notes'] ?? '',
    );
  }
}

class Approval {
  final String approvalId;
  final String targetType; // campaign | purchase_contract | allocation
  final String targetId;
  final String currentStage;
  final List<ApprovalStage> stages;
  final String status; // pending | approved | rejected
  final DateTime createdAt;
  final DateTime updatedAt;

  Approval({
    required this.approvalId,
    required this.targetType,
    required this.targetId,
    required this.currentStage,
    required this.stages,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'approvalId': approvalId,
      'targetType': targetType,
      'targetId': targetId,
      'currentStage': currentStage,
      'stages': stages.map((s) => s.toMap()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Approval.fromMap(Map<String, dynamic> map) {
    return Approval(
      approvalId: map['approvalId'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      currentStage: map['currentStage'] ?? '',
      stages: List<ApprovalStage>.from(
        (map['stages'] as List?)?.map((item) => ApprovalStage.fromMap(Map<String, dynamic>.from(item))) ?? [],
      ),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Warehouse {
  final String warehouseId;
  final String name;
  final String location;
  final double capacity;
  final double availableQuantity;
  final double allocatedQuantity;
  final double incomingQuantity;
  final double outgoingQuantity;
  final String status; // active | full | maintenance

  Warehouse({
    required this.warehouseId,
    required this.name,
    required this.location,
    required this.capacity,
    required this.availableQuantity,
    required this.allocatedQuantity,
    required this.incomingQuantity,
    required this.outgoingQuantity,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'warehouseId': warehouseId,
      'name': name,
      'location': location,
      'capacity': capacity,
      'availableQuantity': availableQuantity,
      'allocatedQuantity': allocatedQuantity,
      'incomingQuantity': incomingQuantity,
      'outgoingQuantity': outgoingQuantity,
      'status': status,
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      warehouseId: map['warehouseId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      capacity: (map['capacity'] ?? 0).toDouble(),
      availableQuantity: (map['availableQuantity'] ?? 0).toDouble(),
      allocatedQuantity: (map['allocatedQuantity'] ?? 0).toDouble(),
      incomingQuantity: (map['incomingQuantity'] ?? 0).toDouble(),
      outgoingQuantity: (map['outgoingQuantity'] ?? 0).toDouble(),
      status: map['status'] ?? 'active',
    );
  }
}

class StockMovement {
  final String movementId;
  final String warehouseId;
  final String type; // incoming | outgoing | allocation_hold | allocation_release
  final double quantity;
  final String referenceType; // inspection | campaign | approval
  final String referenceId;
  final String remarks;
  final String recordedBy;
  final DateTime timestamp;

  StockMovement({
    required this.movementId,
    required this.warehouseId,
    required this.type,
    required this.quantity,
    required this.referenceType,
    required this.referenceId,
    required this.remarks,
    required this.recordedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'movementId': movementId,
      'warehouseId': warehouseId,
      'type': type,
      'quantity': quantity,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'remarks': remarks,
      'recordedBy': recordedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      movementId: map['movementId'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      type: map['type'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      referenceType: map['referenceType'] ?? '',
      referenceId: map['referenceId'] ?? '',
      remarks: map['remarks'] ?? '',
      recordedBy: map['recordedBy'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class AuditLog {
  final String logId;
  final String userId;
  final String userEmail;
  final String action; // create | update | delete | login | workflow_change
  final String targetCollection;
  final String targetId;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime timestamp;

  AuditLog({
    required this.logId,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    required this.before,
    required this.after,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'before': before,
      'after': after,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      logId: map['logId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      action: map['action'] ?? '',
      targetCollection: map['targetCollection'] ?? '',
      targetId: map['targetId'] ?? '',
      before: Map<String, dynamic>.from(map['before'] ?? {}),
      after: Map<String, dynamic>.from(map['after'] ?? {}),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
