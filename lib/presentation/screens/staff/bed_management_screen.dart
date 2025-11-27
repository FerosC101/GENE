// lib/presentation/screens/staff/bed_management_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/hospital_model.dart';
import 'package:pulse/presentation/providers/hospital_provider.dart';

class BedManagementScreen extends ConsumerWidget {
  const BedManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bed Status Management'),
      ),
      body: hospitalsAsync.when(
        data: (hospitals) {
          if (hospitals.isEmpty) {
            return const Center(
              child: Text('No hospitals available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              return _BedStatusCard(hospital: hospital);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _BedStatusCard extends ConsumerStatefulWidget {
  final HospitalModel hospital;

  const _BedStatusCard({required this.hospital});

  @override
  ConsumerState<_BedStatusCard> createState() => _BedStatusCardState();
}

class _BedStatusCardState extends ConsumerState<_BedStatusCard> {
  late int _icuOccupied;
  late int _erOccupied;
  late int _wardOccupied;
  late int _waitTime;
  bool _isOperational = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _icuOccupied = widget.hospital.status.icuOccupied;
    _erOccupied = widget.hospital.status.erOccupied;
    _wardOccupied = widget.hospital.status.wardOccupied;
    _waitTime = widget.hospital.status.waitTimeMinutes;
    _isOperational = widget.hospital.status.isOperational;
  }

  Future<void> _updateBedStatus() async {
    try {
      final status = {
        'icuTotal': widget.hospital.status.icuTotal,
        'icuOccupied': _icuOccupied,
        'erTotal': widget.hospital.status.erTotal,
        'erOccupied': _erOccupied,
        'wardTotal': widget.hospital.status.wardTotal,
        'wardOccupied': _wardOccupied,
        'waitTimeMinutes': _waitTime,
        'isOperational': _isOperational,
      };

      await ref
          .read(hospitalControllerProvider.notifier)
          .updateBedStatus(widget.hospital.id, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bed status updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isOperational
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_hospital,
                color: _isOperational ? AppColors.success : AppColors.error,
              ),
            ),
            title: Text(
              widget.hospital.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuickStat(
                      'ICU',
                      '${widget.hospital.status.icuTotal - _icuOccupied}/${widget.hospital.status.icuTotal}',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      'ER',
                      '${widget.hospital.status.erTotal - _erOccupied}/${widget.hospital.status.erTotal}',
                      AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                      'Ward',
                      '${widget.hospital.status.wardTotal - _wardOccupied}/${widget.hospital.status.wardTotal}',
                      AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),
          ),
          
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // ICU Section
                  _buildBedSection(
                    'ICU Beds',
                    widget.hospital.status.icuTotal,
                    _icuOccupied,
                    AppColors.primary,
                    (value) => setState(() => _icuOccupied = value.toInt()),
                  ),
                  const SizedBox(height: 20),
                  
                  // ER Section
                  _buildBedSection(
                    'ER Beds',
                    widget.hospital.status.erTotal,
                    _erOccupied,
                    AppColors.warning,
                    (value) => setState(() => _erOccupied = value.toInt()),
                  ),
                  const SizedBox(height: 20),
                  
                  // Ward Section
                  _buildBedSection(
                    'Ward Beds',
                    widget.hospital.status.wardTotal,
                    _wardOccupied,
                    AppColors.info,
                    (value) => setState(() => _wardOccupied = value.toInt()),
                  ),
                  const SizedBox(height: 20),
                  
                  // Wait Time
                  const Text(
                    'Average Wait Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _waitTime.toDouble(),
                          min: 0,
                          max: 120,
                          divisions: 24,
                          label: '$_waitTime min',
                          onChanged: (value) {
                            setState(() => _waitTime = value.toInt());
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_waitTime min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Operational Status
                  SwitchListTile(
                    title: const Text('Operational Status'),
                    subtitle: Text(
                      _isOperational ? 'Hospital is operational' : 'Hospital is closed',
                    ),
                    value: _isOperational,
                    onChanged: (value) {
                      setState(() => _isOperational = value);
                    },
                    activeColor: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateBedStatus,
                      icon: const Icon(Icons.save),
                      label: const Text('Update Bed Status'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedSection(
    String title,
    int total,
    int occupied,
    Color color,
    Function(double) onChanged,
  ) {
    final available = total - occupied;
  (occupied / total * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$available available',
              style: TextStyle(
                fontSize: 13,
                color: available > 0 ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: occupied / total,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: Slider(
                value: occupied.toDouble(),
                min: 0,
                max: total.toDouble(),
                divisions: total,
                label: '$occupied',
                activeColor: color,
                onChanged: onChanged,
              ),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$occupied / $total',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}