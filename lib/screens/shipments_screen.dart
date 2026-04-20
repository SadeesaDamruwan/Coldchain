// lib/screens/shipments_screen.dart
import 'package:flutter/material.dart';
import '../models/container_model.dart';
import '../services/shipments_service.dart';
import 'container_details_screen.dart';

class ShipmentsScreen extends StatefulWidget {
  final Function(ContainerModel) onTrackContainer;

  const ShipmentsScreen({super.key, required this.onTrackContainer});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final ShipmentsService _shipmentsService = ShipmentsService();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateFilter(String status) {
    setState(() => _selectedFilter = status);
    _animationController.reset();
    _animationController.forward();
  }

  // --- Robust Add Container Form ---
  void _showAddContainerForm() {
    final formKey = GlobalKey<FormState>();
    final idController = TextEditingController();
    final locationController = TextEditingController();
    final tempController = TextEditingController();
    final humidityController = TextEditingController(); // <-- NEW CONTROLLER
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24.0, right: 24.0, top: 24.0,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add New Shipment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: 'Container ID (e.g. CNT-006)',
                          prefixIcon: const Icon(Icons.qr_code, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'ID is required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: 'Starting Location',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Location is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Side-by-side inputs for Temp and Humidity
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tempController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Initial Temp (°C)',
                                prefixIcon: const Icon(Icons.thermostat, color: Colors.orange),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: humidityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Humidity (%)',
                                prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isLoading ? null : () async {
                            if (formKey.currentState!.validate()) {
                              setModalState(() => isLoading = true);

                              double initialTemp = double.tryParse(tempController.text) ?? 4.0;
                              double initialHumidity = double.tryParse(humidityController.text) ?? 50.0;

                              // Push to Firebase via Service
                              await _shipmentsService.addContainer(
                                id: idController.text.trim(),
                                location: locationController.text.trim(),
                                initialTemp: initialTemp,
                                initialHumidity: initialHumidity, // <-- NEW DATA PASSED
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${idController.text} successfully tracked!'),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                    )
                                );
                              }
                            }
                          },
                          child: isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Add Shipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.sort), title: const Text('Sort by Temperature (High to Low)'), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Filter by Region'), onTap: () => Navigator.pop(context)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: () => Navigator.pop(context), child: const Text('Apply Filters')))
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContainerForm,
        backgroundColor: Colors.blue.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Shipment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 20, right: 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cold Chain', style: TextStyle(color: Color(0xFF1F2937), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.settings_outlined), color: const Color(0xFF4B5563), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.person_outline), color: const Color(0xFF4B5563), iconSize: 28, onPressed: () {}),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                  _animationController.reset();
                                  _animationController.forward();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search containers...',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _showAdvancedFilters,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.filter_alt_outlined, color: Colors.grey.shade700),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All'),
                              _buildFilterChip('Safe'),
                              _buildFilterChip('Warning'),
                              _buildFilterChip('Critical'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: StreamBuilder<List<ContainerModel>>(
                    stream: _shipmentsService.containersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Error loading shipments.')));
                      }
                      if (!snapshot.hasData) {
                        return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                      }

                      final containers = snapshot.data!;

                      final displayedList = containers.where((c) {
                        final matchesSearch = c.id.toLowerCase().contains(_searchQuery.toLowerCase());
                        final matchesStatus = _selectedFilter == 'All' || c.status == _selectedFilter;
                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (displayedList.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text('No containers found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayedList.length,
                        itemBuilder: (context, index) {
                          return _buildAnimatedContainerCard(displayedList[index], index);
                        },
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _updateFilter(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.blue.shade700 : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainerCard(ContainerModel container, int index) {
    final double delay = (index * 0.1).clamp(0.0, 1.0);

    final Animation<Offset> slideAnimation = Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeOutCubic)));

    final Animation<double> fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeIn)));

    Color statusColor;
    Color statusBgColor;
    switch (container.status) {
      case 'Safe':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        break;
      case 'Warning':
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        break;
      case 'Critical':
      default:
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade50;
        break;
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContainerDetailsScreen(
                  container: container,
                  onTrackPressed: () {
                    Navigator.pop(context);
                    widget.onTrackContainer(container);
                  },
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(container.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(container.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(container.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),

                // --- ADDED HUMIDITY TO CARD UI ---
                Row(
                  children: [
                    // Temperature Section
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: statusBgColor, shape: BoxShape.circle),
                            child: Icon(Icons.thermostat, color: statusColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(container.temperature.toStringAsFixed(1), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
                                  const SizedBox(width: 2),
                                  const Text('°C', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                                ],
                              ),
                              Text('Temp', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                            ],
                          )
                        ],
                      ),
                    ),

                    // Humidity Section
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.water_drop, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(container.humidity.toStringAsFixed(0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  const SizedBox(width: 2),
                                  const Text('%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                                ],
                              ),
                              Text('Humidity', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}