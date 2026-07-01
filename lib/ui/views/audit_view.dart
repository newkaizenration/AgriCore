import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AuditView extends StatefulWidget {
  const AuditView({super.key});

  @override
  State<AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<AuditView> {
  final _searchController = TextEditingController();
  AuditLog? _selectedLog;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Apply Filter & Search
    final filteredLogs = db.auditLogs.where((log) {
      return log.userEmail.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          log.action.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          log.targetCollection.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          log.targetId.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    final isAdmin = auth.currentUser?.role == UserRole.administrator;

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_rounded, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                'Security Violation: Access Denied',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Only system administrators have permission to browse audit logs.',
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Audit Trails List
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Audit Trails',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Immutable operational history record tracking logins, data modifications, and workflow decisions.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search audit logs by operator email, action, collection, or ID...',
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
                      child: filteredLogs.isEmpty
                          ? Center(
                              child: Text(
                                'No audit logs found.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredLogs.length,
                              separatorBuilder: (c, idx) => const Divider(color: Color(0xFF334155)),
                              itemBuilder: (context, idx) {
                                final log = filteredLogs[idx];
                                final isSelected = _selectedLog?.logId == log.logId;
                                
                                Color actionColor = const Color(0xFF3B82F6); // Blue update
                                if (log.action == 'create') {
                                  actionColor = const Color(0xFF10B981); // Green create
                                } else if (log.action == 'delete') {
                                  actionColor = const Color(0xFFEF4444); // Red delete
                                } else if (log.action.contains('anomaly')) {
                                  actionColor = const Color(0xFFF59E0B); // Yellow warning
                                }

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF10B981).withOpacity(0.08),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: actionColor.withOpacity(0.1),
                                      border: Border.all(color: actionColor.withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      log.action.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold, 
                                        color: actionColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Collection: ${log.targetCollection.toUpperCase()} • ID: ${log.targetId}',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Operator: ${log.userEmail}',
                                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                  trailing: Text(
                                    DateFormat('HH:mm:ss').format(log.timestamp),
                                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedLog = log;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Pane: Log Value Comparison (Before/After JSON details)
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(left: BorderSide(color: Color(0xFF334155))),
              ),
              padding: const EdgeInsets.all(24),
              child: _selectedLog == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fact_check_rounded, size: 48, color: Color(0xFF475569)),
                          const SizedBox(height: 12),
                          Text(
                            'Select an audit entry from the list to display state comparison.',
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'State Change Log Detail',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Log ID: ${_selectedLog!.logId} • Action: ${_selectedLog!.action.toUpperCase()}',
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'USER / OPERATOR CONTEXT',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 1),
                          ),
                          const SizedBox(height: 6),
                          _buildContextRow('User ID', _selectedLog!.userId),
                          _buildContextRow('User Email', _selectedLog!.userEmail),
                          _buildContextRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedLog!.timestamp)),
                          
                          const SizedBox(height: 24),
                          
                          // Before Snapshot
                          Text(
                            'PREVIOUS STATE (BEFORE)',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444), letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              _selectedLog!.before.isEmpty 
                                  ? '{} // (Empty record created)' 
                                  : const JsonEncoder.withIndent('  ').convert(_selectedLog!.before),
                              style: GoogleFonts.shareTechMono(fontSize: 12, color: const Color(0xFFEF4444)),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // After Snapshot
                          Text(
                            'MODIFIED STATE (AFTER)',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981), letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              _selectedLog!.after.isEmpty 
                                  ? '{} // (Record deleted)' 
                                  : const JsonEncoder.withIndent('  ').convert(_selectedLog!.after),
                              style: GoogleFonts.shareTechMono(fontSize: 12, color: const Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContextRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
          Text(val, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }
}
