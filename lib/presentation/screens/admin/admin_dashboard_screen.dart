// lib/presentation/screens/admin/admin_dashboard_screen.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/presentation/providers/auth_provider.dart';
import 'package:pulse/presentation/providers/hospital_provider.dart';
import 'package:pulse/presentation/screens/auth/welcome_screen.dart';
import 'package:pulse/presentation/screens/staff/doctor_management_screen.dart';
import 'package:pulse/presentation/screens/admin/staff_management_screen.dart';
import 'package:pulse/presentation/screens/admin/hospital_management_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No user data'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.fullName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'System Administrator',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // System Statistics
                hospitalsAsync.when(
                  data: (hospitals) {
                    int totalBeds = 0;
                    int occupiedBeds = 0;
                    int totalStaff = hospitals.length * 15; // Placeholder

                    for (var hospital in hospitals) {
                      totalBeds += hospital.status.totalBeds;
                      occupiedBeds += hospital.status.totalOccupied;
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Hospitals',
                                value: hospitals.length.toString(),
                                iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996689/icon_hospital_ekdup6.png',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Beds',
                                value: totalBeds.toString(),
                                iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/icon_bed_akitqa.png',
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Occupancy',
                                value: '${(occupiedBeds / totalBeds * 100).toInt()}%',
                                iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996689/feature_analytics_t1hcql.png',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Staff',
                                value: totalStaff.toString(),
                                iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_hospital_staff_bh0leu.png',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error: $error'),
                ),
                const SizedBox(height: 32),

                // Management Sections
                const Text(
                  'System Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ManagementCard(
                  title: 'Hospital Management',
                  subtitle: 'Add, edit, or remove hospitals from the system',
                  iconAsset: 'assets/images/icon_hospital.png',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HospitalManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _ManagementCard(
                  title: 'Staff Management',
                  subtitle: 'Manage hospital staff accounts and permissions',
                  iconAsset: 'assets/images/usertype_hospital_staff.png',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StaffManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _ManagementCard(
                  title: 'Doctor Management',
                  subtitle: 'Manage doctors across all hospitals',
                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_doctor_yigfmz.png',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _ManagementCard(
                  title: 'Digital Twin Viewer',
                  subtitle: 'View 3D hospital models and run simulations',
                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996686/feature_map_is3b5u.png',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    _showHospitalSelectorForDigitalTwin(context, ref);
                  },
                ),

                _ManagementCard(
                  title: 'System Analytics',
                  subtitle: 'View comprehensive system-wide analytics',
                  iconAsset: 'assets/images/feature_analytics.png',
                  color: AppColors.warning,
                  onTap: () {
                    // TODO: Navigate to analytics
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showHospitalSelectorForDigitalTwin(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.read(hospitalsStreamProvider);
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Hospital'),
        content: SizedBox(
          width: double.maxFinite,
          child: hospitalsAsync.when(
            data: (hospitals) {
              final hospitalsWithModels = hospitals
                  .where((h) => h.has3dModel)
                  .toList();
              
              if (hospitalsWithModels.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No hospitals with 3D models yet'),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: hospitalsWithModels.length,
                itemBuilder: (context, index) {
                  final hospital = hospitalsWithModels[index];
                  return ListTile(
                    leading: const Icon(Icons.view_in_ar, color: AppColors.primary),
                    title: Text(hospital.name),
                    subtitle: Text('${hospital.modelMetadata?.floors ?? 0} floors'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DigitalTwinScreen(
                            hospitalId: hospital.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? iconAsset;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.icon,
    this.iconAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconAsset != null
                ? (iconAsset!.startsWith('http://') || iconAsset!.startsWith('https://')
                    ? Image.network(
                        iconAsset!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: color,
                        errorBuilder: (context, error, stackTrace) => Icon(icon ?? Icons.circle, color: color, size: 24),
                      )
                    : Image.asset(
                        iconAsset!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: color,
                        errorBuilder: (context, error, stackTrace) => Icon(icon ?? Icons.circle, color: color, size: 24),
                      ))
                : Icon(icon ?? Icons.circle, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Management Card Widget
class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconAsset != null
                    ? (iconAsset!.startsWith('http://') || iconAsset!.startsWith('https://')
                        ? Image.network(
                            iconAsset!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            color: color,
                            errorBuilder: (context, error, stackTrace) => Icon(icon ?? Icons.circle, color: color, size: 28),
                          )
                        : Image.asset(
                            iconAsset!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            color: color,
                            errorBuilder: (context, error, stackTrace) => Icon(icon ?? Icons.circle, color: color, size: 28),
                          ))
                    : Icon(icon ?? Icons.circle, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A simple placeholder DigitalTwinScreen so the referenced screen exists.
// Replace this with the real implementation when available.
class DigitalTwinScreen extends StatelessWidget {
  final String hospitalId;

  const DigitalTwinScreen({Key? key, required this.hospitalId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Twin Viewer'),
      ),
      body: Center(
        child: Text('Digital Twin for hospital: $hospitalId'),
      ),
    );
  }
}