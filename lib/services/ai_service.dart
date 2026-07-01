import 'dart:math';
import 'package:flutter/foundation.dart';

class AICertificateData {
  final String certificateNumber;
  final String laboratoryName;
  final double moisture;
  final double purity;
  final double contamination;
  final String grade;
  final DateTime testDate;

  AICertificateData({
    required this.certificateNumber,
    required this.laboratoryName,
    required this.moisture,
    required this.purity,
    required this.contamination,
    required this.grade,
    required this.testDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'certificateNumber': certificateNumber,
      'laboratoryName': laboratoryName,
      'moisture': moisture,
      'purity': purity,
      'contamination': contamination,
      'grade': grade,
      'testDate': testDate.toIso8601String(),
    };
  }
}

class AIClassificationResult {
  final String category; // inspection_report | lab_certificate | purchase_approval | warehouse_doc | misc
  final double confidenceScore;

  AIClassificationResult({
    required this.category,
    required this.confidenceScore,
  });
}

class AIService {
  // Simulate OCR Processing using Gemini AI models
  static Future<AICertificateData> performOCR(String fileName) async {
    // Artificial latency for API call
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    
    // Generate certificate data based on filenames to make testing predictable
    String certNum = 'CERT-2026-${random.nextInt(8999) + 1000}';
    String labName = 'Midwest Agronomy Labs';
    double moisture = 12.0 + (random.nextDouble() * 4.0); // 12.0 - 16.0%
    double purity = 94.0 + (random.nextDouble() * 5.8);   // 94.0 - 99.8%
    double contamination = random.nextDouble() * 3.5;       // 0.0 - 3.5%
    
    if (fileName.toLowerCase().contains('poor') || fileName.toLowerCase().contains('fail')) {
      moisture = 16.8;
      purity = 89.5;
      contamination = 4.2;
    } else if (fileName.toLowerCase().contains('clean') || fileName.toLowerCase().contains('premium')) {
      moisture = 11.2;
      purity = 99.5;
      contamination = 0.2;
    }

    // Determine grade
    String grade = 'A';
    if (moisture > 14.5 || purity < 95.0 || contamination > 1.5) {
      grade = 'B';
    }
    if (moisture > 15.5 || purity < 92.0 || contamination > 2.5) {
      grade = 'C';
    }
    if (moisture > 16.5 || purity < 90.0 || contamination > 3.5) {
      grade = 'Fail';
    }

    return AICertificateData(
      certificateNumber: certNum,
      laboratoryName: labName,
      moisture: double.parse(moisture.toStringAsFixed(1)),
      purity: double.parse(purity.toStringAsFixed(1)),
      contamination: double.parse(contamination.toStringAsFixed(1)),
      grade: grade,
      testDate: DateTime.now().subtract(Duration(days: random.nextInt(5) + 1)),
    );
  }

  // Simulate AI Document Classification
  static Future<AIClassificationResult> classifyDocument(String fileName) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final lowerName = fileName.toLowerCase();
    String category = 'misc';
    double confidence = 0.65 + (Random().nextDouble() * 0.3); // 65% - 95%

    if (lowerName.contains('inspection') || lowerName.contains('field') || lowerName.contains('insp')) {
      category = 'inspection_report';
      confidence = 0.88 + (Random().nextDouble() * 0.1);
    } else if (lowerName.contains('certificate') || lowerName.contains('lab') || lowerName.contains('test') || lowerName.contains('cert')) {
      category = 'lab_certificate';
      confidence = 0.92 + (Random().nextDouble() * 0.07);
    } else if (lowerName.contains('approval') || lowerName.contains('contract') || lowerName.contains('purchase')) {
      category = 'purchase_approval';
      confidence = 0.85 + (Random().nextDouble() * 0.12);
    } else if (lowerName.contains('warehouse') || lowerName.contains('stock') || lowerName.contains('inventory') || lowerName.contains('silo')) {
      category = 'warehouse_doc';
      confidence = 0.89 + (Random().nextDouble() * 0.09);
    }

    return AIClassificationResult(
      category: category,
      confidenceScore: double.parse(confidence.toStringAsFixed(2)),
    );
  }

  // Anomaly explanation generator
  static Map<String, dynamic> detectAnomaly({
    required double moisture,
    required int visualScore,
    required double quantity,
  }) {
    bool isAnomaly = false;
    List<String> rules = [];
    String reason = '';
    double riskScore = 0.0;

    if (moisture > 14.5) {
      isAnomaly = true;
      rules.add('high_moisture');
      reason += 'Moisture value of $moisture% is outside normal operational boundaries. ';
      riskScore += 0.5;
    }
    
    if (visualScore < 4) {
      isAnomaly = true;
      rules.add('poor_visual_quality');
      reason += 'Visual quality score ($visualScore/10) is extremely low. ';
      riskScore += 0.3;
    }

    if (quantity > 500 && moisture > 13.8) {
      isAnomaly = true;
      rules.add('bulk_storage_hazard');
      reason += 'Bulk storage of $quantity MT with elevated moisture ($moisture%) presents heating and fermentation risks. ';
      riskScore += 0.4;
    }

    return {
      'isAnomaly': isAnomaly,
      'rules': rules,
      'explanation': reason.isEmpty ? 'No anomalies detected.' : reason,
      'riskScore': riskScore.clamp(0.0, 0.95),
    };
  }
}
