// lib/presentation/screens/staff/tabs/overview_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/presentation/providers/patient_provider.dart';
import 'package:smart_hospital_app/presentation/providers/queue_provider.dart';
import 'package:smart_hospital_app/presentation/screens/staff/widgets/quick_action_card.dart';
import 'package:smart_hospital_app/presentation/screens/staff/widgets/patient_admission_dialog.dart';
import 'package:smart_hospital_app/presentation/screens/staff/widgets/department_status_card.dart';
import 'package:smart_hospital_app/presentation/screens/staff/widgets/critical_alert_card.dart';
import 'package:intl/intl.dart';

class OverviewTab extends ConsumerWidget {
  final String hospitalId;

  const OverviewTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider(hospitalId));
    final queueAsync = ref.watch(queueStreamProvider(hospitalId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientsStreamProvider(hospitalId));
        ref.invalidate(queueStreamProvider(hospitalId));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Welcome
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daily Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.person_add,
                    iconAsset: 'assets/images/qa_admit.png',
                    label: 'Admit Patient',
                    color: AppColors.success,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => PatientAdmissionDialog(
                          hospitalId: hospitalId,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.exit_to_app,
                    iconAsset: 'assets/images/qa_discharge.png',
                    label: 'Discharge',
                    color: AppColors.info,
                    onTap: () {
                      // TODO: Show discharge dialog
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.swap_horiz,
                    iconAsset: 'assets/images/qa_transfer.png',
                    label: 'Transfer',
                    color: AppColors.warning,
                    onTap: () {
                      // TODO: Show transfer dialog
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.medical_services,
                    iconAsset: 'assets/images/qa_emergency.png',
                    label: 'Emergency',
                    color: AppColors.error,
                    onTap: () {
                      // TODO: Show emergency admission
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Critical Alerts
            const Text(
              'Critical Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            patientsAsync.when(
              data: (patients) {
                final icuPatients = patients.where((p) => p.department == 'ICU').length;
                final criticalPatients = patients.where((p) => 
                  p.condition.toLowerCase().contains('critical')).length;

                return Column(
                  children: [
                    if (icuPatients > 18) // 90% of 20 beds
                      CriticalAlertCard(
                        icon: Icons.warning,
                        title: 'ICU Near Capacity',
                        subtitle: '$icuPatients/20 beds occupied',
                        color: AppColors.error,
                      ),
                    if (criticalPatients > 5)
                      CriticalAlertCard(
                        icon: Icons.priority_high,
                        title: 'Multiple Critical Patients',
                        subtitle: '$criticalPatients patients in critical condition',
                        color: AppColors.warning,
                      ),
                    queueAsync.when(
                      data: (queue) {
                        if (queue.length > 10) {
                          return CriticalAlertCard(
                            icon: Icons.people,
                            title: 'High Queue Volume',
                            subtitle: '${queue.length} patients waiting',
                            color: AppColors.warning,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Department Status Overview
            const Text(
              'Department Status Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            patientsAsync.when(
              data: (patients) {
                final departments = ['ICU', 'Emergency', 'General Ward', 'Pediatrics', 'Neurology'];
                final departmentCapacity = {
                  'ICU': 20,
                  'Emergency': 15,
                  'General Ward': 50,
                  'Pediatrics': 30,
                  'Neurology': 25,
                };

                return Column(
                  children: departments.map((dept) {
                    final deptPatients = patients.where((p) => p.department == dept).length;
                    final capacity = departmentCapacity[dept] ?? 20;
                    final available = capacity - deptPatients;

                    return DepartmentStatusCard(
                      department: dept,
                      occupied: deptPatients,
                      total: capacity,
                      available: available,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
            const SizedBox(height: 24),

            // Pending Tasks
            const Text(
              'Pending Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            patientsAsync.when(
              data: (patients) {
                final pendingDischarges = patients.where((p) => 
                  p.notes?.contains('discharge pending') ?? false).length;

                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/images/feature_analytics.png',
                        width: 20,
                        height: 20,
                        color: AppColors.info,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.task_alt, color: AppColors.info),
                      ),
                    ),
                    title: Text('Pending Discharges: $pendingDischarges'),
                    subtitle: const Text('Review and process today'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Staff on Duty
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff on Duty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStaffItem('Nurses', '12/15'),
                    _buildStaffItem('Doctors', '8/10'),
                    _buildStaffItem('Support Staff', '5/8'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffItem(String role, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(role),
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}