import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  Approval? _selectedApproval;
  
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitDecision(String decision) {
    if (_selectedApproval == null) return;
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    // Get current stage name
    final currentStageName = _selectedApproval!.stages
        .firstWhere((s) => s.status == 'pending')
        .stageName;

    db.submitApprovalDecision(
      _selectedApproval!.approvalId,
      currentStageName,
      decision,
      _notesController.text.isNotEmpty ? _notesController.text : 'Decision made by ${auth.currentUser?.fullName}',
      auth.currentUser!,
    );

    _notesController.clear();
    
    // Refresh selected item details from DB
    final updatedIndex = db.approvals.indexWhere((a) => a.approvalId == _selectedApproval!.approvalId);
    setState(() {
      _selectedApproval = updatedIndex != -1 ? db.approvals[updatedIndex] : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: decision == 'approved' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        content: Text('Workflow stage "$currentStageName" marked as $decision.', style: GoogleFonts.outfit()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Filter approvals
    final filteredApprovals = db.approvals.where((a) {
      final matchesSearch = a.approvalId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          a.targetId.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatusFilter == 'all' || a.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Workflow List
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-Stage Approval Board',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Execute procurement gatekeeping stages across quality testing, budget constraints, and warehouse allocations.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search approvals by ID or associated target ID...',
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
                            value: _selectedStatusFilter,
                            dropdownColor: const Color(0xFF1E293B),
                            style: GoogleFonts.outfit(color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Workflows')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending Gate')),
                              DropdownMenuItem(value: 'approved', child: Text('Fully Approved')),
                              DropdownMenuItem(value: 'rejected', child: Text('Rejected/Archived')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStatusFilter = val;
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
                      child: filteredApprovals.isEmpty
                          ? Center(
                              child: Text(
                                'No approval workflows found.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredApprovals.length,
                              separatorBuilder: (c, idx) => const Divider(color: Color(0xFF334155)),
                              itemBuilder: (context, idx) {
                                final app = filteredApprovals[idx];
                                final isSelected = _selectedApproval?.approvalId == app.approvalId;
                                
                                Color statusColor = const Color(0xFFF59E0B); // Pending
                                if (app.status == 'approved') {
                                  statusColor = const Color(0xFF10B981);
                                } else if (app.status == 'rejected') {
                                  statusColor = const Color(0xFFEF4444);
                                }

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF10B981).withOpacity(0.08),
                                  title: Text(
                                    'Contract approval: ${app.approvalId}',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'Target ID: ${app.targetId} (${app.targetType.replaceAll('_', ' ').toUpperCase()})\nCurrent Gate: ${app.currentStage.replaceAll('_', ' ').toUpperCase()}',
                                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                  trailing: Icon(Icons.circle_rounded, color: statusColor, size: 12),
                                  onTap: () {
                                    setState(() {
                                      _selectedApproval = app;
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
          
          // Right Pane: Selected Approval Workflow Timeline & Actions
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(left: BorderSide(color: Color(0xFF334155))),
              ),
              padding: const EdgeInsets.all(24),
              child: _selectedApproval == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rule_folder_rounded, size: 48, color: Color(0xFF475569)),
                          const SizedBox(height: 12),
                          Text(
                            'Select a workflow contract from the list to evaluate approval gates.',
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
                            'Workflow Audit Log: ${_selectedApproval!.approvalId}',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Target ID: ${_selectedApproval!.targetId} • Status: ${_selectedApproval!.status.toUpperCase()}',
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 24),

                          // Visual Checklists for Stages
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedApproval!.stages.length,
                            itemBuilder: (context, idx) {
                              final stage = _selectedApproval!.stages[idx];
                              
                              Color stageColor = const Color(0xFF64748B); // Untouched
                              IconData stageIcon = Icons.radio_button_unchecked_rounded;

                              if (stage.status == 'approved') {
                                stageColor = const Color(0xFF10B981);
                                stageIcon = Icons.check_circle_rounded;
                              } else if (stage.status == 'rejected') {
                                stageColor = const Color(0xFFEF4444);
                                stageIcon = Icons.cancel_rounded;
                              } else if (_selectedApproval!.status == 'pending' && 
                                         _selectedApproval!.currentStage.toLowerCase().trim() == stage.stageName.toLowerCase().trim().replaceAll(' ', '_')) {
                                stageColor = const Color(0xFF3B82F6); // Active Pending Gate
                                stageIcon = Icons.hourglass_empty_rounded;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(stageIcon, color: stageColor, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stage.stageName,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white, 
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Assigned Role: ${stage.assignedRole.name.toUpperCase()}',
                                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                                          ),
                                          if (stage.status != 'pending') ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Actor: ${stage.actorId} • ${stage.timestamp != null ? DateFormat('yy-MM-dd HH:mm').format(stage.timestamp!) : ""}\nRemarks: ${stage.notes}',
                                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const Divider(color: Color(0xFF334155), height: 32),

                          // Interaction Action Box if current role matches required role
                          _buildInteractiveActionBox(auth),
                        ],
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractiveActionBox(AuthService auth) {
    if (_selectedApproval!.status != 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Center(
          child: Text(
            'This workflow is archived and finalized as ${_selectedApproval!.status.toUpperCase()}.',
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Find the pending stage
    final pendingStage = _selectedApproval!.stages.firstWhere((s) => s.status == 'pending');
    
    // Check if active user has permission to approve this stage
    final userHasRole = auth.currentUser?.role == pendingStage.assignedRole || auth.currentUser?.role == UserRole.administrator;

    if (!userHasRole) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 24),
            const SizedBox(height: 8),
            Text(
              'Awaiting decision from role: ${pendingStage.assignedRole.name.toUpperCase()}.\nYour active account role is: ${auth.currentUser?.role.name.toUpperCase()}.',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                'Execute Approval: ${pendingStage.stageName}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Review linked data and submit your final verdict below. Remarks will be recorded in the audit trail.',
            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Decision Notes / Remarks',
              hintText: 'Enter approval or rejection explanation...',
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submitDecision('rejected'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Reject Contract', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitDecision('approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Approve & Forward'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
