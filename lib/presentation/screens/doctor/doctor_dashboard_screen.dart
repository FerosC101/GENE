// lib/presentation/screens/doctor/doctor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/appointment_model.dart';
import 'package:pulse/data/models/appointment_status.dart' show AppointmentStatus;
import 'package:pulse/presentation/providers/auth_provider.dart';
import 'package:pulse/presentation/providers/appointment_provider.dart';
import 'package:pulse/presentation/screens/auth/welcome_screen.dart';
import 'package:pulse/presentation/screens/doctor/doctor_appointments_screen.dart';
import 'package:pulse/presentation/screens/doctor/doctor_schedule_screen.dart';
import 'package:pulse/presentation/screens/doctor/doctor_patients_screen.dart';
import 'package:pulse/presentation/screens/doctor/appointment_detail_screen.dart';
import 'package:intl/intl.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
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
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          final doctorId = user.id;
          final todayAppointmentsAsync = ref.watch(todayDoctorAppointmentsProvider(doctorId));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todayDoctorAppointmentsProvider(doctorId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          'assets/images/usertype_doctor.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.medical_services,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${user.fullName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.specialty ?? 'General Practitioner',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats
                  todayAppointmentsAsync.when(
                    data: (appointments) {
                      final pending = appointments.where((a) => a.status == AppointmentStatus.pending).length;
                      final confirmed = appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
                      final completed = appointments.where((a) => a.status == AppointmentStatus.completed).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total',
                                  appointments.length.toString(),
                                  Icons.event,
                                  AppColors.primary,
                                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999287/total_cygmhv.png',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Pending',
                                  pending.toString(),
                                  Icons.pending_actions,
                                  AppColors.warning,
                                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999286/pending_rdr0gv.png',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Confirmed',
                                  confirmed.toString(),
                                  Icons.check_circle,
                                  AppColors.info,
                                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999280/confirmed_znceyd.png',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Completed',
                                  completed.toString(),
                                  Icons.done_all,
                                  AppColors.success,
                                  iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999280/completed_ldpszs.png',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'All Appointments',
                          Icons.calendar_month,
                          AppColors.primary,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorAppointmentsScreen(doctorId: doctorId),
                              ),
                            );
                          },
                          iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999281/my_appointment_unk0ra.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'My Schedule',
                          Icons.schedule,
                          AppColors.info,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorScheduleScreen(
                                  doctorId: doctorId,
                                  hospitalId: user.hospitalId ?? '',
                                ),
                              ),
                            );
                          },
                          iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999286/schedule_teajaa.png',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    'My Patients',
                    Icons.people,
                    AppColors.success,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorPatientsScreen(doctorId: doctorId),
                        ),
                      );
                    },
                    iconAsset: 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763999286/my_patients_lpquud.png',
                  ),
                  const SizedBox(height: 32),

                  // Today's Appointments
                  const Text(
                    'Today\'s Appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  todayAppointmentsAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No appointments today',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enjoy your free day!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: appointments.map((appointment) {
                          return _buildAppointmentCard(context, appointment);
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? iconAsset}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          iconAsset != null
              ? (iconAsset.startsWith('http://') || iconAsset.startsWith('https://')
                  ? Image.network(
                      iconAsset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      color: color,
                      errorBuilder: (context, error, stack) => Icon(icon, color: color, size: 28),
                    )
                  : Image.asset(
                      iconAsset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      color: color,
                      errorBuilder: (context, error, stack) => Icon(icon, color: color, size: 28),
                    ))
              : Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? iconAsset,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: iconAsset != null
                      ? (iconAsset.startsWith('http://') || iconAsset.startsWith('https://')
                          ? Image.network(
                              iconAsset,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              color: color,
                              errorBuilder: (context, error, stack) => Icon(icon, color: color, size: 24),
                            )
                          : Image.asset(
                              iconAsset,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              color: color,
                              errorBuilder: (context, error, stack) => Icon(icon, color: color, size: 24),
                            ))
                      : Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appointment) {
    final statusColor = switch (appointment.status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.info,
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled || AppointmentStatus.noShow => AppColors.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(appointment: appointment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('hh:mm a').format(appointment.dateTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.chiefComplaint != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.chiefComplaint!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}