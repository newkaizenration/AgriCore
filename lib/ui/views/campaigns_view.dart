import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class CampaignsView extends StatefulWidget {
  const CampaignsView({super.key});

  @override
  State<CampaignsView> createState() => _CampaignsViewState();
}

class _CampaignsViewState extends State<CampaignsView> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCampaignDialog(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final formKey = GlobalKey<FormState>();
    final cropController = TextEditingController();
    final regionController = TextEditingController();
    final stateController = TextEditingController();
    final quantityController = TextEditingController();
    final budgetController = TextEditingController();
    
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    List<String> assignedMembers = ['procurement_user'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(
                'Launch Procurement Campaign',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: cropController,
                          decoration: const InputDecoration(labelText: 'Crop Type (e.g., Wheat, Soybeans)'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: regionController,
                          decoration: const InputDecoration(labelText: 'Operating Region (e.g., Midwest)'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: stateController,
                          decoration: const InputDecoration(labelText: 'State Jurisdiction (e.g., Kansas)'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Target Volume (Metric Tons)'),
                          validator: (value) => double.tryParse(value ?? '') == null ? 'Enter valid number' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Budget Allocations (USD)'),
                          validator: (value) => double.tryParse(value ?? '') == null ? 'Enter valid budget' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Start Date Picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                              style: GoogleFonts.outfit(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setDialogState(() => startDate = date);
                                }
                              },
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                        
                        // End Date Picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                              style: GoogleFonts.outfit(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: startDate.add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setDialogState(() => endDate = date);
                                }
                              },
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newCamp = Campaign(
                        campaignId: 'CAMP-2026-${cropController.text.toUpperCase().substring(0, 3)}-${const Uuid().v4().substring(0, 4).toUpperCase()}',
                        cropType: cropController.text,
                        region: regionController.text,
                        state: stateController.text,
                        startDate: startDate,
                        endDate: endDate,
                        targetQuantity: double.parse(quantityController.text),
                        budget: double.parse(budgetController.text),
                        status: 'active',
                        assignedTeam: assignedMembers,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        timeline: [
                          {
                            'status': 'active',
                            'changedBy': auth.currentUser?.uid ?? 'unknown',
                            'timestamp': DateTime.now().toIso8601String(),
                            'remarks': 'Campaign initialized and released directly by ${auth.currentUser?.fullName}'
                          }
                        ],
                      );
                      db.addCampaign(newCamp, auth.currentUser!);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('Campaign ${newCamp.campaignId} successfully launched!', style: GoogleFonts.outfit()),
                        ),
                      );
                    }
                  },
                  child: const Text('Deploy Campaign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimelineDialog(Campaign campaign) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Campaign Audit Log: ${campaign.campaignId}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: campaign.timeline.length,
              itemBuilder: (context, idx) {
                final log = campaign.timeline[idx];
                final date = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded, color: Color(0xFF10B981), size: 20),
                  title: Text(
                    'Status changed to: ${log['status']?.toString().toUpperCase()}',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Actor: ${log['changedBy']} • ${DateFormat('yyyy-MM-dd HH:mm').format(date)}\nRemarks: ${log['remarks']}',
                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12),
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
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
    final filteredCampaigns = db.campaigns.where((c) {
      final matchesSearch = c.cropType.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          c.campaignId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          c.state.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatusFilter == 'all' || c.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final canCreate = auth.hasPermission('campaigns.create');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign Planning & Procurement',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure crop purchasing targets, state locations, budgets, and track procurement progress.',
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                if (canCreate)
                  ElevatedButton.icon(
                    onPressed: () => _showCreateCampaignDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Campaign'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Status Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search campaigns by ID, crop type, or state...',
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
                        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
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

            // Campaign Data Table
            Expanded(
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: filteredCampaigns.isEmpty
                    ? Center(
                        child: Text(
                          'No campaigns found matching criteria.',
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
                              columns: [
                                DataColumn(label: Text('Campaign ID', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Crop', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('State', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Dates', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Target (MT)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Budget (USD)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('Actions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                              ],
                              rows: filteredCampaigns.map((camp) {
                                final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 0);
                                final start = DateFormat('yy-MM-dd').format(camp.startDate);
                                final end = DateFormat('yy-MM-dd').format(camp.endDate);
                                
                                Color statusBadgeColor;
                                switch (camp.status.toLowerCase()) {
                                  case 'active':
                                    statusBadgeColor = const Color(0xFF10B981);
                                    break;
                                  case 'draft':
                                    statusBadgeColor = const Color(0xFF64748B);
                                    break;
                                  default:
                                    statusBadgeColor = const Color(0xFF3B82F6);
                                    break;
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(Text(camp.campaignId, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white70))),
                                    DataCell(Text(camp.cropType, style: GoogleFonts.outfit(color: Colors.white))),
                                    DataCell(Text(camp.state, style: GoogleFonts.outfit(color: Colors.white70))),
                                    DataCell(Text('$start to $end', style: GoogleFonts.outfit(fontSize: 12))),
                                    DataCell(Text(camp.targetQuantity.toString(), style: GoogleFonts.outfit())),
                                    DataCell(Text(formatCurrency.format(camp.budget), style: GoogleFonts.outfit(color: const Color(0xFF10B981)))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBadgeColor.withOpacity(0.1),
                                          border: Border.all(color: statusBadgeColor.withOpacity(0.5)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          camp.status.toUpperCase(),
                                          style: GoogleFonts.outfit(fontSize: 11, color: statusBadgeColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF64748B)),
                                        tooltip: 'View Timeline History',
                                        onPressed: () => _showTimelineDialog(camp),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
