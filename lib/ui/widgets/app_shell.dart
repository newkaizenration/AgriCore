import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agricore/models/models.dart';
import 'package:agricore/services/auth_service.dart';
import 'package:agricore/services/database_service.dart';
import 'package:agricore/ui/views/dashboard_view.dart';
import 'package:agricore/ui/views/campaigns_view.dart';
import 'package:agricore/ui/views/inspections_view.dart';
import 'package:agricore/ui/views/lab_view.dart';
import 'package:agricore/ui/views/warehouse_view.dart';
import 'package:agricore/ui/views/approvals_view.dart';
import 'package:agricore/ui/views/documents_view.dart';
import 'package:agricore/ui/views/audit_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Tabs mapping
  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Operational Dashboard',
      'icon': Icons.dashboard_rounded,
      'permission': 'dashboards.view',
    },
    {
      'title': 'Campaign Planning',
      'icon': Icons.campaign_rounded,
      'permission': 'campaigns.view',
    },
    {
      'title': 'Field Inspections',
      'icon': Icons.agriculture_rounded,
      'permission': 'inspections.view',
    },
    {
      'title': 'Laboratory Portal',
      'icon': Icons.science_rounded,
      'permission': 'labs.review',
    },
    {
      'title': 'Warehouse & Stock',
      'icon': Icons.warehouse_rounded,
      'permission': 'warehouse.manage',
    },
    {
      'title': 'Approvals Workflow',
      'icon': Icons.rule_folder_rounded,
      'permission': 'approvals.approve',
    },
    {
      'title': 'Document Center',
      'icon': Icons.folder_shared_rounded,
      'permission': 'documents.upload',
    },
    {
      'title': 'System Audit Logs',
      'icon': Icons.list_alt_rounded,
      'permission': 'audit.view',
    },
  ];

  Widget _getView(int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const CampaignsView();
      case 2:
        return const InspectionsView();
      case 3:
        return const LabView();
      case 4:
        return const WarehouseView();
      case 5:
        return const ApprovalsView();
      case 6:
        return const DocumentsView();
      case 7:
        return const AuditView();
      default:
        return const DashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    // Filter tabs based on user permissions
    final filteredTabs = _tabs.where((tab) {
      final perm = tab['permission'] as String;
      // Administrators bypass permission filters
      if (authService.currentUser?.role == UserRole.administrator) return true;
      
      // Let's grant dashboard access to all authenticated roles
      if (perm == 'dashboards.view') return true;

      return authService.hasPermission(perm);
    }).toList();

    // Map selection index back to filtered indices safety
    if (_selectedIndex >= filteredTabs.length) {
      _selectedIndex = 0;
    }

    final activeTabTitle = filteredTabs.isNotEmpty 
        ? filteredTabs[_selectedIndex]['title'] as String 
        : 'AgriCore Portal';

    final int targetGlobalIndex = filteredTabs.isNotEmpty
        ? _tabs.indexWhere((t) => t['title'] == filteredTabs[_selectedIndex]['title'])
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.agriculture_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            Text(
              'AgriCore',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                authService.currentUser?.role.name.toUpperCase() ?? 'PROCUREMENT',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Synchronize/Offline Indicator and Action button
          Row(
            children: [
              // Pending sync count badge
              if (databaseService.pendingSyncInspections.isNotEmpty)
                Tooltip(
                  message: '${databaseService.pendingSyncInspections.length} records pending offline synchronization',
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B), // Warn yellow
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_problem_rounded, size: 14, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text(
                          '${databaseService.pendingSyncInspections.length} Pending',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Online / Offline Trigger Toggle
              Container(
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: databaseService.isOffline 
                      ? const Color(0xFFEF4444).withOpacity(0.1) 
                      : const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: databaseService.isOffline 
                        ? const Color(0xFFEF4444).withOpacity(0.3) 
                        : const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    databaseService.toggleOnlineOffline();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: databaseService.isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        content: Text(
                          databaseService.isOffline 
                              ? 'Simulation Mode: Disconnected. Local caching active.' 
                              : 'Simulation Mode: Connected. Offline sync triggered!',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        databaseService.isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                        size: 16,
                        color: databaseService.isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        databaseService.isOffline ? 'OFFLINE' : 'ONLINE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: databaseService.isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // User profile menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                authService.currentUser?.fullName ?? 'User',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            onPressed: () {
              authService.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Menu for Desktop
          if (isDesktop && filteredTabs.isNotEmpty)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(right: BorderSide(color: Color(0xFF334155))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTabs.length,
                      itemBuilder: (context, index) {
                        final tab = filteredTabs[index];
                        final isSelected = index == _selectedIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF10B981).withOpacity(0.12) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              tab['icon'] as IconData,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            title: Text(
                              tab['title'] as String,
                              style: GoogleFonts.outfit(
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            dense: true,
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Active Workspace',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF475569)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Midwest Division',
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          // Main content workspace area
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: _getView(targetGlobalIndex),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar for Mobile
      bottomNavigationBar: !isDesktop && filteredTabs.isNotEmpty
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF1E293B),
              selectedItemColor: const Color(0xFF10B981),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
              items: filteredTabs.map((tab) {
                return BottomNavigationBarItem(
                  icon: Icon(tab['icon'] as IconData, size: 20),
                  label: (tab['title'] as String).split(' ').first,
                );
              }).toList(),
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : null,
    );
  }
}
