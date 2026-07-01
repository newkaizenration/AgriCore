import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:agricore/models/models.dart';
import 'package:agricore/services/auth_service.dart';
import 'package:agricore/services/database_service.dart';

class InspectionsView extends StatefulWidget {
  const InspectionsView({super.key});

  @override
  State<InspectionsView> createState() => _InspectionsViewState();
}

class _InspectionsViewState extends State<InspectionsView> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateInspectionDialog(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final formKey = GlobalKey<FormState>();
    final farmerNameController = TextEditingController();
    final farmerPhoneController = TextEditingController();
    final farmerAddressController = TextEditingController();
    final cropVarietyController = TextEditingController();
    final quantityController = TextEditingController();
    final moistureController = TextEditingController(text: '12.5');
    final notesController = TextEditingController();
    
    String selectedCampaignId = db.campaigns.isNotEmpty ? db.campaigns.first.campaignId : '';
    double latitude = 39.0483;
    double longitude = -95.6780;
    bool gpsCaptured = false;
    
    int visualQualityScore = 7;
    List<String> imageUrls = [];
    bool imageUploaded = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(
                'Record Field Inspection',
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
                        DropdownButtonFormField<String>(
                          value: selectedCampaignId,
                          decoration: const InputDecoration(labelText: 'Linked Campaign'),
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.outfit(color: Colors.white),
                          items: db.campaigns.map((c) {
                            return DropdownMenuItem(value: c.campaignId, child: Text(c.campaignId));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCampaignId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmerNameController,
                          decoration: const InputDecoration(labelText: 'Farmer / Vendor Name'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Farmer Contact Phone'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: farmerAddressController,
                          decoration: const InputDecoration(labelText: 'Farmer Farm Address'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cropVarietyController,
                          decoration: const InputDecoration(labelText: 'Crop Variety (e.g. Hard Red Wheat)'),
                          validator: (value) => value == null || value.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Est. Quantity (MT)'),
                                validator: (value) => double.tryParse(value ?? '') == null ? 'Enter number' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: moistureController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Moisture Level (%)'),
                                validator: (value) => double.tryParse(value ?? '') == null ? 'Enter number' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Visual Quality Slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visual Quality Score: $visualQualityScore/10',
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                            ),
                            Slider(
                              value: visualQualityScore.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: const Color(0xFF10B981),
                              inactiveColor: const Color(0xFF334155),
                              onChanged: (val) {
                                setDialogState(() => visualQualityScore = val.toInt());
                              },
                            ),
                          ],
                        ),
                        
                        // GPS capture mock
                        Row(
                          children: [
                            Icon(
                              gpsCaptured ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                              color: gpsCaptured ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gpsCaptured 
                                    ? 'GPS Captured: Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}' 
                                    : 'GPS Coordinates not captured',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  gpsCaptured = true;
                                  latitude = 39.0 + (5 * (DateTime.now().millisecond / 1000));
                                  longitude = -95.0 - (3 * (DateTime.now().microsecond / 1000000));
                                });
                              },
                              icon: const Icon(Icons.my_location_rounded, size: 16),
                              label: const Text('Capture'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Camera capture mock
                        Row(
                          children: [
                            Icon(
                              imageUploaded ? Icons.photo_library_rounded : Icons.add_a_photo_rounded,
                              color: imageUploaded ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                imageUploaded ? '1 Photo attached (stored)' : 'No photos attached',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  imageUploaded = true;
                                  imageUrls = ['https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b'];
                                });
                              },
                              icon: const Icon(Icons.camera_alt_rounded, size: 16),
                              label: const Text('Snap Photo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Inspection Remarks / Notes'),
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
                      final newInsp = Inspection(
                        inspectionId: 'INSP-${Uuid().v4().substring(0, 6).toUpperCase()}',
                        campaignId: selectedCampaignId,
                        farmerName: farmerNameController.text,
                        farmerPhone: farmerPhoneController.text,
                        farmerAddress: farmerAddressController.text,
                        locationName: 'Farmer Farm Field Plot',
                        latitude: latitude,
                        longitude: longitude,
                        cropVariety: cropVarietyController.text,
                        estimatedQuantity: double.parse(quantityController.text),
                        moistureLevel: double.parse(moistureController.text),
                        visualQualityScore: visualQualityScore,
                        notes: notesController.text,
                        imageUrls: imageUrls,
                        inspectorId: auth.currentUser?.uid ?? 'unknown',
                        status: 'completed',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      db.submitInspection(newInsp, auth.currentUser!);
                      Navigator.pop(context);
                      
                      final modeMsg = db.isOffline 
                          ? 'Inspection stored in local cache queue.' 
                          : 'Inspection successfully saved & workflow triggered.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: db.isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          content: Text(modeMsg, style: GoogleFonts.outfit()),
                        ),
                      );
                    }
                  },
                  child: Text(db.isOffline ? 'Save Locally (Cache)' : 'Submit Inspection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);

    // Apply Filter & Search
    final filteredInspections = db.inspections.where((i) {
      final matchesSearch = i.farmerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          i.inspectionId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          i.cropVariety.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatusFilter == 'all' || i.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final canSubmit = auth.hasPermission('inspections.execute') || auth.hasPermission('campaigns.create');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner for Offline Mode
            if (db.isOffline)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Mode Active. Field inspection data entered will be stored in your local Cache and synchronized to Firebase Cloud immediately once connectivity is re-established.',
                        style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Inspections',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log farm coordinates, estimated volumes, verify moisture parameters, and snap crop images.',
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                if (canSubmit)
                  ElevatedButton.icon(
                    onPressed: () => _showCreateInspectionDialog(context),
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Add Inspection'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Filter Options
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search inspections by farmer, ID, crop variety...',
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
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'flagged', child: Text('Flagged (Anomaly)')),
                        DropdownMenuItem(value: 'cached_offline', child: Text('Cached Offline')),
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

            // Inspections List
            Expanded(
              child: filteredInspections.isEmpty
                  ? Center(
                      child: Text(
                        'No inspections found.',
                        style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredInspections.length,
                      itemBuilder: (context, idx) {
                        final insp = filteredInspections[idx];
                        
                        Color badgeColor = const Color(0xFF10B981);
                        if (insp.status == 'flagged') {
                          badgeColor = const Color(0xFFEF4444);
                        } else if (insp.status == 'cached_offline') {
                          badgeColor = const Color(0xFFF59E0B);
                        }

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: const Color(0xFF334155).withOpacity(0.7)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFF0F172A),
                                    child: insp.imageUrls.isNotEmpty
                                        ? Image.network(
                                            insp.imageUrls.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) => const Icon(Icons.broken_image_rounded, color: Color(0xFF475569)),
                                          )
                                        : const Icon(Icons.image_not_supported_rounded, color: Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            insp.inspectionId,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(0.1),
                                              border: Border.all(color: badgeColor.withOpacity(0.4)),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              insp.status.toUpperCase().replaceAll('_', ' '),
                                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Farmer: ${insp.farmerName} • Contact: ${insp.farmerPhone}',
                                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                      ),
                                      Text(
                                        'Crop Variety: ${insp.cropVariety} • Est. Quantity: ${insp.estimatedQuantity} MT',
                                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.opacity_rounded, size: 14, color: insp.moistureLevel > 14.5 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Moisture: ${insp.moistureLevel}%',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: insp.moistureLevel > 14.5 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.star_half_rounded, size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Visual Quality: ${insp.visualQualityScore}/10',
                                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'GPS Captured',
                                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                                          ),
                                        ],
                                      ),
                                      if (insp.notes.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Notes: ${insp.notes}',
                                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
