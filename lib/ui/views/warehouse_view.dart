import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({super.key});

  @override
  State<WarehouseView> createState() => _WarehouseViewState();
}

class _WarehouseViewState extends State<WarehouseView> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _remarksController = TextEditingController();
  
  String _selectedWarehouseId = 'WH-KANSAS-01';
  String _selectedMovementType = 'incoming';
  String _selectedRefType = 'approval';
  final _refIdController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _remarksController.dispose();
    _refIdController.dispose();
    super.dispose();
  }

  void _submitStockMovement(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final mvt = StockMovement(
      movementId: 'MVT-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      warehouseId: _selectedWarehouseId,
      type: _selectedMovementType,
      quantity: double.parse(_quantityController.text),
      referenceType: _selectedRefType,
      referenceId: _refIdController.text.isNotEmpty ? _refIdController.text : 'MANUAL-MVT',
      remarks: _remarksController.text,
      recordedBy: auth.currentUser?.uid ?? 'unknown',
      timestamp: DateTime.now(),
    );

    // Apply movement
    db.recordStockMovement(mvt, auth.currentUser!);

    // Reset fields
    _quantityController.clear();
    _remarksController.clear();
    _refIdController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('Stock movement registered. Silo updated.', style: GoogleFonts.outfit()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    final canUpdateStock = auth.hasPermission('stock.update') || auth.hasPermission('warehouse.manage');

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Section: Warehouses & Capacity Gauges
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warehouse Coordination & Stock Allocation',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor regional silo occupancy parameters, active allocations, and incoming cargo intakes.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Warehouse Silo Occupancy List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: db.warehouses.length,
                    itemBuilder: (context, idx) {
                      final wh = db.warehouses[idx];
                      final usagePercent = (wh.availableQuantity / wh.capacity);
                      final isHighUsage = usagePercent >= 0.8;

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isHighUsage ? const Color(0xFFEF4444) : const Color(0xFF334155),
                            width: isHighUsage ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warehouse_rounded,
                                        color: isHighUsage ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            wh.name,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          ),
                                          Text(
                                            'Location: ${wh.location} • ID: ${wh.warehouseId}',
                                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isHighUsage)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.1),
                                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'CRITICAL CAPACITY WARNING',
                                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Occupancy Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: usagePercent,
                                  minHeight: 12,
                                  backgroundColor: const Color(0xFF0F172A),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isHighUsage ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Metrics row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStockMiniMetric('Occupied', '${wh.availableQuantity.toInt()} MT'),
                                  _buildStockMiniMetric('Allocated', '${wh.allocatedQuantity.toInt()} MT'),
                                  _buildStockMiniMetric('Incoming', '${wh.incomingQuantity.toInt()} MT'),
                                  _buildStockMiniMetric('Capacity Limit', '${wh.capacity.toInt()} MT'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  Text(
                    'RECENT SILO INTAKES & MOVEMENTS',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  
                  // Movements Table
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: db.stockMovements.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No stock logs registered.',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: db.stockMovements.length,
                            separatorBuilder: (c, idx) => const Divider(color: Color(0xFF334155)),
                            itemBuilder: (context, idx) {
                              final mvt = db.stockMovements[idx];
                              Color mvtColor = const Color(0xFF10B981);
                              IconData mvtIcon = Icons.arrow_downward_rounded;
                              if (mvt.type == 'outgoing') {
                                mvtColor = const Color(0xFFEF4444);
                                mvtIcon = Icons.arrow_upward_rounded;
                              } else if (mvt.type.contains('allocation')) {
                                mvtColor = const Color(0xFF3B82F6);
                                mvtIcon = Icons.lock_rounded;
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: mvtColor.withOpacity(0.1),
                                  foregroundColor: mvtColor,
                                  child: Icon(mvtIcon, size: 18),
                                ),
                                title: Text(
                                  'Silo: ${mvt.warehouseId} • Quantity: ${mvt.quantity} MT',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Action: ${mvt.type.toUpperCase()} • Ref: ${mvt.referenceType.toUpperCase()} (${mvt.referenceId})\nRemarks: ${mvt.remarks}',
                                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                                ),
                                trailing: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(mvt.timestamp),
                                  style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Sidebar Panel: Movement Logger Form
          if (canUpdateStock)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(left: BorderSide(color: Color(0xFF334155))),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Log Stock Movement',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record crop intake sheets or outgoing shipments. This directly adjusts silo metrics.',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedWarehouseId,
                          decoration: const InputDecoration(labelText: 'Target Warehouse'),
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.outfit(color: Colors.white),
                          items: db.warehouses.map((w) {
                            return DropdownMenuItem(value: w.warehouseId, child: Text(w.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedWarehouseId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _selectedMovementType,
                          decoration: const InputDecoration(labelText: 'Movement Action'),
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.outfit(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'incoming', child: Text('INCOMING (Intake)')),
                            DropdownMenuItem(value: 'outgoing', child: Text('OUTGOING (Shipment)')),
                            DropdownMenuItem(value: 'allocation_hold', child: Text('HOLD ALLOCATION')),
                            DropdownMenuItem(value: 'allocation_release', child: Text('RELEASE ALLOCATION')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMovementType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Net Weight (Metric Tons)'),
                          validator: (value) => double.tryParse(value ?? '') == null ? 'Enter valid numeric tonnage' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRefType,
                                decoration: const InputDecoration(labelText: 'Ref Type'),
                                dropdownColor: const Color(0xFF1E293B),
                                style: GoogleFonts.outfit(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'approval', child: Text('Approval Contract')),
                                  DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
                                  DropdownMenuItem(value: 'manual', child: Text('Manual Intake')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedRefType = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _refIdController,
                                decoration: const InputDecoration(labelText: 'Reference ID'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _remarksController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Movement Remarks / Cargo Details'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: () => _submitStockMovement(context),
                          child: const Text('Commit Movement Log'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStockMiniMetric(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFE2E8F0))),
      ],
    );
  }
}
