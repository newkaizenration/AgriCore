import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:agricore/services/auth_service.dart';
import 'package:agricore/services/database_service.dart';
import 'package:agricore/ui/widgets/responsive_layout.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Compute Metrics
    final activeCampaignsCount = db.campaigns.where((c) => c.status == 'active').length;
    final totalInspectionsCount = db.inspections.length;
    final completedInspections = db.inspections.where((i) => i.status == 'completed').length;
    final completionRate = totalInspectionsCount > 0 
        ? (completedInspections / totalInspectionsCount * 100).toStringAsFixed(1) 
        : '0.0';
    
    final activeAnomaliesCount = db.anomalies.where((a) => a.status == 'flagged').length;
    final pendingApprovalsCount = db.approvals.where((a) => a.status == 'pending').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcoming Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${auth.currentUser?.fullName.split(' ').first ?? 'Operator'}',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your operations overview for today.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Last updated: Just now',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF475569)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Grid (Responsive Columns)
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildKPICard('Active Campaigns', '$activeCampaignsCount', Icons.campaign_rounded, const Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  _buildKPICard('Inspection Completion', '$completionRate%', Icons.assignment_turned_in_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(height: 16),
                  _buildKPICard('Flagged Anomalies', '$activeAnomaliesCount', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
                  const SizedBox(height: 16),
                  _buildKPICard('Pending Approvals', '$pendingApprovalsCount', Icons.rate_review_rounded, const Color(0xFFF59E0B)),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(child: _buildKPICard('Active Campaigns', '$activeCampaignsCount', Icons.campaign_rounded, const Color(0xFF10B981))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKPICard('Inspection Completion', '$completionRate%', Icons.assignment_turned_in_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKPICard('Flagged Anomalies', '$activeAnomaliesCount', Icons.warning_amber_rounded, const Color(0xFFEF4444))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildKPICard('Pending Approvals', '$pendingApprovalsCount', Icons.rate_review_rounded, const Color(0xFFF59E0B))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Data Charts Section
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildGradeDistributionChart(context, db),
                  const SizedBox(height: 24),
                  _buildWarehouseCapacityGauge(context, db),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildGradeDistributionChart(context, db)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildWarehouseCapacityGauge(context, db)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pending Approvals & Exceptions Alerts
            _buildExceptionsAndActions(context, db, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          )
        ],
      ),
    );
  }

  Widget _buildGradeDistributionChart(BuildContext context, DatabaseService db) {
    // Count lab grades
    int gradeA = 0, gradeB = 0, gradeC = 0, gradeFail = 0;
    for (var test in db.labTests) {
      switch (test.grade) {
        case 'A':
          gradeA++;
          break;
        case 'B':
          gradeB++;
          break;
        case 'C':
          gradeC++;
          break;
        default:
          gradeFail++;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grain Quality Distribution',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggregated grades of crops certified by Midwest Laboratory.',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (max(max(gradeA, gradeB), max(gradeC, gradeFail)) + 1).toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = 'Grade A';
                            break;
                          case 1:
                            text = 'Grade B';
                            break;
                          case 2:
                            text = 'Grade C';
                            break;
                          case 3:
                            text = 'Fail';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(text, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1.0,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 11),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFF334155), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: gradeA.toDouble(), color: const Color(0xFF10B981), width: 28, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: gradeB.toDouble(), color: const Color(0xFF3B82F6), width: 28, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: gradeC.toDouble(), color: const Color(0xFFF59E0B), width: 28, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: gradeFail.toDouble(), color: const Color(0xFFEF4444), width: 28, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCapacityGauge(BuildContext context, DatabaseService db) {
    double totalCapacity = 0.0;
    double totalStored = 0.0;
    
    for (var wh in db.warehouses) {
      totalCapacity += wh.capacity;
      totalStored += wh.availableQuantity;
    }

    final usagePercent = totalCapacity > 0 ? (totalStored / totalCapacity * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Silo Capacity Allocation',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Global occupancy rate across state grain elevators.',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: totalStored,
                        title: '',
                        color: usagePercent > 85 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: (totalCapacity - totalStored).clamp(0.0, 999999.0),
                        title: '',
                        color: const Color(0xFF334155),
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${usagePercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Occupied',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionsAndActions(BuildContext context, DatabaseService db, AuthService auth) {
    // Collect active critical issues (Unresolved anomalies + high-risk items)
    final flaggedAnomalies = db.anomalies.where((a) => a.status == 'flagged').toList();
    final pendingApprovals = db.approvals.where((a) => a.status == 'pending').toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Exceptions & Action Panel',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (flaggedAnomalies.isEmpty && pendingApprovals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No pending exceptions or approval items. All systems nominal.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                ),
              ),
            )
          else ...[
            if (flaggedAnomalies.isNotEmpty) ...[
              Text(
                'CRITICAL ANOMALIES REQUIRING REVIEW (${flaggedAnomalies.length})',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444), letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(flaggedAnomalies.length, 3),
                itemBuilder: (context, idx) {
                  final anomaly = flaggedAnomalies[idx];
                  return Card(
                    color: const Color(0xFF0F172A),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 18),
                      ),
                      title: Text(
                        'Target ID: ${anomaly.targetId} (Type: ${anomaly.targetType.toUpperCase()})',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        anomaly.explanation,
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Risk: ${(anomaly.riskScore * 100).toInt()}%',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            if (pendingApprovals.isNotEmpty) ...[
              Text(
                'PENDING CONTRACTS FOR YOUR ACTION (${pendingApprovals.length})',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B), letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(pendingApprovals.length, 3),
                itemBuilder: (context, idx) {
                  final app = pendingApprovals[idx];
                  return Card(
                    color: const Color(0xFF0F172A),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFFF59E0B), size: 18),
                      ),
                      title: Text(
                        'Approval ID: ${app.approvalId}',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Linked Target: ${app.targetId} • Current Stage: ${app.currentStage.replaceAll('_', ' ').toUpperCase()}',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                    ),
                  );
                },
              ),
            ]
          ]
        ],
      ),
    );
  }
}
