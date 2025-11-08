// lib/presentation/screens/staff/tabs/bed_status_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/presentation/providers/patient_provider.dart';
import 'package:smart_hospital_app/presentation/screens/staff/widgets/bed_card.dart';

class BedStatusTab extends ConsumerStatefulWidget {
  final String hospitalId;

  const BedStatusTab({super.key, required this.hospitalId});

  @override
  ConsumerState<BedStatusTab> createState() => _BedStatusTabState();
}

class _BedStatusTabState extends ConsumerState<BedStatusTab> {
  String _selectedDepartment = 'All';
  String _selectedStatus = 'All';

  final List<String> _departments = [
    'All',
    'ICU',
    'Emergency',
    'General Ward',
    'Pediatrics',
    'Neurology',
  ];

  final List<String> _statuses = [
    'All',
    'Occupied',
    'Available',
  ];

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsStreamProvider(widget.hospitalId));

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDepartment = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bed List
        Expanded(
          child: patientsAsync.when(
            data: (patients) {
              // Filter patients
              var filteredPatients = patients.where((p) {
                if (_selectedDepartment != 'All' && p.department != _selectedDepartment) {
                  return false;
                }
                return true;
              }).toList();

              // Generate bed list (occupied + available)
              final departmentCapacity = {
                'ICU': 20,
                'Emergency': 15,
                'General Ward': 50,
                'Pediatrics': 30,
                'Neurology': 25,
              };

              List<Widget> bedCards = [];

              if (_selectedDepartment == 'All') {
                // Show all departments
                for (var dept in _departments.skip(1)) {
                  final deptPatients = filteredPatients.where((p) => p.department == dept).toList();
                  final capacity = departmentCapacity[dept] ?? 20;
                  
                  bedCards.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        dept,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );

                  // Occupied beds
                  for (var patient in deptPatients) {
                    bedCards.add(BedCard(patient: patient, isOccupied: true));
                  }

                  // Available beds
                  if (_selectedStatus == 'All' || _selectedStatus == 'Available') {
                    final availableCount = capacity - deptPatients.length;
                    for (var i = 0; i < availableCount; i++) {
                      bedCards.add(BedCard(
                        patient: null,
                        isOccupied: false,
                        bedNumber: '${dept.substring(0, 3).toUpperCase()}-${deptPatients.length + i + 1}',
                        department: dept,
                      ));
                    }
                  }
                }
              } else {
                // Show selected department
                final capacity = departmentCapacity[_selectedDepartment] ?? 20;
                
                // Occupied beds
                if (_selectedStatus == 'All' || _selectedStatus == 'Occupied') {
                  for (var patient in filteredPatients) {
                    bedCards.add(BedCard(patient: patient, isOccupied: true));
                  }
                }

                // Available beds
                if (_selectedStatus == 'All' || _selectedStatus == 'Available') {
                  final availableCount = capacity - filteredPatients.length;
                  for (var i = 0; i < availableCount; i++) {
                    bedCards.add(BedCard(
                      patient: null,
                      isOccupied: false,
                      bedNumber: '${_selectedDepartment.substring(0, 3).toUpperCase()}-${filteredPatients.length + i + 1}',
                      department: _selectedDepartment,
                    ));
                  }
                }
              }

              if (bedCards.isEmpty) {
                return const Center(
                  child: Text('No beds match the selected filters'),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: bedCards,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}