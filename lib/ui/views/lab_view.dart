import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';

class LabView extends StatefulWidget {
  const LabView({super.key});

  @override
  State<LabView> createState() => _LabViewState();
}

class _LabViewState extends State<LabView> {
  final _searchController = TextEditingController();
  bool _isAnalyzing = false;
  
  // OCR Verification Buffer
  AICertificateData? _extractedData;
  String? _scannedFileName;
  String? _linkedInspectionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Simulate file uploading and trigger the OCR service
  void _triggerAIOCRUpload(BuildContext context, String sampleName) async {
    setState(() {
      _isAnalyzing = true;
      _extractedData = null;
      _scannedFileName = sampleName;
    });

    try {
      // Run mock OCR extractor
      final result = await AICerterviceHelper.runMockOCR(sampleName);
      
      setState(() {
        _extractedData = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _saveVerifiedLabTest() {
    if (_extractedData == null) return;
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final labTest = LabTest(
      sampleId: 'SMPL-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      inspectionId: _linkedInspectionId,
      testType: 'AI OCR Extraction (${_extractedData!.laboratoryName})',
      moisture: _extractedData!.moisture,
      purity: _extractedData!.purity,
      contamination: _extractedData!.contamination,
      grade: _extractedData!.grade,
      remarks: 'Automated OCR extraction from file: $_scannedFileName. Value verification approved by ${auth.currentUser?.fullName}.',
      certificateUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      ocrMetadata: _extractedData!.toMap(),
      ocrVerified: true,
      testerId: auth.currentUser?.uid ?? 'unknown',
      createdAt: DateTime.now(),
    );

    db.submitLabTest(labTest, auth.currentUser!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: labTest.grade == 'Fail' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        content: Text('Sample saved. Quality Grade: ${labTest.grade}.', style: GoogleFonts.outfit()),
      ),
    );

    setState(() {
      _extractedData = null;
      _scannedFileName = null;
      _linkedInspectionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    final filteredTests = db.labTests.where((t) {
      return t.sampleId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          t.grade.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (t.inspectionId ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    final activeInspectionsToTest = db.inspections.where((i) => i.status == 'completed' || i.status == 'flagged').toList();
    final canGrade = auth.hasPermission('labs.grade');

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Section: Samples Tracker
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laboratory Analysis & Quality Grading',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review crop moisture limits, purity indexes, foreign contamination margins, and record grades.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search lab results by sample ID, grade, or inspection link...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                      child: filteredTests.isEmpty
                          ? Center(
                              child: Text(
                                'No laboratory records found.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredTests.length,
                              separatorBuilder: (c, idx) => const Divider(color: Color(0xFF334155)),
                              itemBuilder: (context, idx) {
                                final test = filteredTests[idx];
                                Color gradeColor;
                                switch (test.grade) {
                                  case 'A':
                                    gradeColor = const Color(0xFF10B981);
                                    break;
                                  case 'B':
                                    gradeColor = const Color(0xFF3B82F6);
                                    break;
                                  case 'C':
                                    gradeColor = const Color(0xFFF59E0B);
                                    break;
                                  default:
                                    gradeColor = const Color(0xFFEF4444);
                                    break;
                                }

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: gradeColor.withOpacity(0.1),
                                    foregroundColor: gradeColor,
                                    child: Text(test.grade, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(
                                    'Sample: ${test.sampleId} • Type: ${test.testType}',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'Purity: ${test.purity}% • Moisture: ${test.moisture}% • Contamination: ${test.contamination}%\nRemarks: ${test.remarks}',
                                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (test.inspectionId != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF334155),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            test.inspectionId!,
                                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(test.createdAt),
                                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side Section: AI OCR Certificate Parser
          if (canGrade)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(left: BorderSide(color: Color(0xFF334155))),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'AI Certificate Upload',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a PDF lab certificate. The OCR engine will automatically classify contents, extract parameters, and prompt verification.',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      
                      // Linked Inspection Selector
                      DropdownButtonFormField<String>(
                        value: _linkedInspectionId,
                        decoration: const InputDecoration(labelText: 'Associate Field Inspection'),
                        dropdownColor: const Color(0xFF1E293B),
                        style: GoogleFonts.outfit(color: Colors.white),
                        items: activeInspectionsToTest.map((i) {
                          return DropdownMenuItem(value: i.inspectionId, child: Text('${i.inspectionId} (${i.farmerName})'));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _linkedInspectionId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Upload simulator buttons
                      Text(
                        'SIMULATE LAB CERTIFICATE PDF UPLOAD',
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _linkedInspectionId == null ? null : () => _triggerAIOCRUpload(context, 'wheat_premium_report.pdf'),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload Premium Wheat Lab Cert'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _linkedInspectionId == null ? null : () => _triggerAIOCRUpload(context, 'soybeans_damp_fail.pdf'),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload Damp Soy Lab Cert'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444).withOpacity(0.7)),
                      ),
                      const SizedBox(height: 24),

                      // Loading OCR spinner
                      if (_isAnalyzing)
                        Column(
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF10B981)),
                            const SizedBox(height: 12),
                            Text(
                              'AI Document OCR Engine analyzing certificate layout...',
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                      // Verification dialog panel
                      if (_extractedData != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.08),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'OCR Verification Panel',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Validate the OCR-extracted values below against your physical certificate copy. Edit fields if any translation error occurred.',
                                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              
                              _buildVerifyField('Cert #', _extractedData!.certificateNumber),
                              _buildVerifyField('Lab Name', _extractedData!.laboratoryName),
                              _buildVerifyField('Moisture', '${_extractedData!.moisture}%'),
                              _buildVerifyField('Purity', '${_extractedData!.purity}%'),
                              _buildVerifyField('Contam.', '${_extractedData!.contamination}%'),
                              _buildVerifyField('Grade', _extractedData!.grade, highlight: true),
                              
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _saveVerifiedLabTest,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                child: const Text('Approve & Save to Database'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildVerifyField(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: highlight ? const Color(0xFF1E293B) : Colors.transparent,
              border: Border.all(color: highlight ? const Color(0xFF10B981) : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13, 
                fontWeight: FontWeight.bold, 
                color: highlight ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Internal static helper since AICertificateData helper methods are mocked
class AICerterviceHelper {
  static Future<AICertificateData> runMockOCR(String fileName) async {
    return AIService.performOCR(fileName);
  }
}

// Fix font naming syntax mismatch
extension TextColor on Color {
  static const Color whitee8 = Color(0xFFE2E8F0);
}
