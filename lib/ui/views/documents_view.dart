import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'all';
  bool _isUploading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Simulate file picker selection and AI classification triggers
  void _simulateFileUpload(BuildContext context, String mockFileName, String fileType) async {
    setState(() {
      _isUploading = true;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      // 1. Run AI Document Classifier simulation
      final classification = await AIService.classifyDocument(mockFileName);

      // 2. Formulate document model
      final newDoc = DocumentModel(
        documentId: 'DOC-${const Uuid().v4().substring(0, 6).toUpperCase()}',
        fileName: mockFileName,
        fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileType: fileType,
        category: classification.category,
        confidenceScore: classification.confidenceScore,
        humanOverride: false,
        uploaderId: auth.currentUser?.uid ?? 'unknown',
        tags: [mockFileName.split('_').first, fileType.toUpperCase()],
        createdAt: DateTime.now(),
      );

      // 3. Save to database
      db.uploadDocument(newDoc, auth.currentUser!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            'File uploaded! AI Classified as "${newDoc.category.toUpperCase()}" with ${(newDoc.confidenceScore * 100).toInt()}% confidence.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    } catch (e) {
      debugPrint("File upload mock failed: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showOverrideCategoryDialog(DocumentModel doc) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    String selectedCat = doc.category;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Override AI Classification Category',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI assigned category: "${doc.category.toUpperCase()}" (${(doc.confidenceScore * 100).toInt()}% confidence).',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCat,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Correct Category'),
                items: const [
                  DropdownMenuItem(value: 'inspection_report', child: Text('Field Inspection Report')),
                  DropdownMenuItem(value: 'lab_certificate', child: Text('Laboratory Certificate')),
                  DropdownMenuItem(value: 'purchase_approval', child: Text('Purchase Contract / Approval')),
                  DropdownMenuItem(value: 'warehouse_doc', child: Text('Warehouse Allocations & Stock')),
                  DropdownMenuItem(value: 'misc', child: Text('Miscellaneous Documentation')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    selectedCat = val;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                db.overrideDocumentCategory(doc.documentId, selectedCat, auth.currentUser!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF3B82F6),
                    content: Text('AI feedback loop triggered. Category overridden to ${selectedCat.toUpperCase()}', style: GoogleFonts.outfit()),
                  ),
                );
              },
              child: const Text('Confirm Override'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Apply Filter & Search
    final filteredDocs = db.documents.where((d) {
      final matchesSearch = d.fileName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          d.tags.any((t) => t.toLowerCase().contains(_searchController.text.toLowerCase()));
      
      final matchesCat = _selectedCategoryFilter == 'all' || d.category == _selectedCategoryFilter;

      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Section: Documents Explorer
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Management Center',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse uploaded inspection sheets, laboratory certifications, and audit certificates.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search documents by filename or metadata tags...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategoryFilter,
                            dropdownColor: const Color(0xFF1E293B),
                            style: GoogleFonts.outfit(color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Categories')),
                              DropdownMenuItem(value: 'inspection_report', child: Text('Inspection Reports')),
                              DropdownMenuItem(value: 'lab_certificate', child: Text('Lab Certificates')),
                              DropdownMenuItem(value: 'purchase_approval', child: Text('Purchase Approvals')),
                              DropdownMenuItem(value: 'warehouse_doc', child: Text('Warehouse Docs')),
                              DropdownMenuItem(value: 'misc', child: Text('Miscellaneous')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategoryFilter = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                      child: filteredDocs.isEmpty
                          ? Center(
                              child: Text(
                                'No documents found matching the filter criteria.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredDocs.length,
                              separatorBuilder: (c, idx) => const Divider(color: Color(0xFF334155)),
                              itemBuilder: (context, idx) {
                                final doc = filteredDocs[idx];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      doc.fileType == 'pdf' 
                                          ? Icons.picture_as_pdf_rounded 
                                          : doc.fileType == 'xlsx' 
                                              ? Icons.table_chart_rounded 
                                              : Icons.insert_drive_file_rounded,
                                      color: doc.fileType == 'pdf' 
                                          ? const Color(0xFFEF4444) 
                                          : const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    doc.fileName,
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'AI Classification: ${doc.category.toUpperCase().replaceAll('_', ' ')} • Conf.: ${(doc.confidenceScore * 100).toInt()}% • Override: ${doc.humanOverride ? "YES" : "NO"}',
                                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.settings_backup_restore_rounded, size: 20, color: Color(0xFF64748B)),
                                        tooltip: 'Human Override/Feedback',
                                        onPressed: () => _showOverrideCategoryDialog(doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF10B981)),
                                        tooltip: 'Download File',
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Downloading file: ${doc.fileName}...', style: GoogleFonts.outfit()),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Sidebar Panel: File Simulator
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(left: BorderSide(color: Color(0xFF334155))),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AI Classifier Sandbox',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a mock operations document. The AI model will classify the content category and record confidence ratings.',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  if (_isUploading) ...[
                    const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                    const SizedBox(height: 12),
                    Text(
                      'AI Classification engine processing file features...',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      'SIMULATE FILE SELECTIONS',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _simulateFileUpload(context, 'field_inspection_plot4_miller.pdf', 'pdf'),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Field Inspection PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _simulateFileUpload(context, 'wheat_procurement_contract_june2026.pdf', 'pdf'),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Purchase Approval Contract'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _simulateFileUpload(context, 'topeka_silo_inventory_audit.xlsx', 'xlsx'),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Warehouse Inventory Spreadsheet'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _simulateFileUpload(context, 'fertilizer_guidelines_manual.docx', 'docx'),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Miscellaneous DOCX File'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
