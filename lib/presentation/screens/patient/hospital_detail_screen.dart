// lib/presentation/screens/patient/hospital_detail_screen.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/hospital_model.dart';
import 'package:smart_hospital_app/presentation/screens/patient/book_appointment_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalDetailScreen extends StatelessWidget {
  final HospitalModel hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  String _hospitalLogoAsset(String name) {
    final n = name.toLowerCase();
    if (n.contains('metro') && n.contains('general')) {
      return 'assets/images/hospital_metro_general.jpg';
    }
    if (n.contains('batangas') && n.contains('medical')) {
      return 'assets/images/hospital_batangas_medical.jpg';
    }
    return 'assets/images/icon_hospital.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share hospital details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          _hospitalLogoAsset(hospital.name),
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hospital.type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hospital.status.isOperational
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hospital.status.isOperational
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hospital.status.isOperational
                              ? 'Currently Operational'
                              : 'Currently Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Information
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItemAsset(
                    'assets/images/icon_location.png',
                    'Address',
                    hospital.address,
                    () async {
                      final url = 'https://maps.google.com/?q=${hospital.latitude},${hospital.longitude}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  _buildContactItem(
                    Icons.phone,
                    'Phone',
                    hospital.phone,
                    () async {
                      final url = 'tel:${hospital.phone}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  _buildContactItem(
                    Icons.email,
                    'Email',
                    hospital.email,
                    () async {
                      final url = 'mailto:${hospital.email}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bed Availability
                  const Text(
                    'Bed Availability',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBedStatusCard(
                    'ICU Beds',
                    hospital.status.icuOccupied,
                    hospital.status.icuTotal,
                    AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildBedStatusCard(
                    'Emergency Beds',
                    hospital.status.erOccupied,
                    hospital.status.erTotal,
                    AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  _buildBedStatusCard(
                    'Ward Beds',
                    hospital.status.wardOccupied,
                    hospital.status.wardTotal,
                    AppColors.info,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/icon_wait_time.png',
                          width: 20,
                          height: 20,
                          color: AppColors.warning,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.access_time, color: AppColors.warning),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Wait Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${hospital.status.waitTimeMinutes} minutes',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Services
                  if (hospital.services.isNotEmpty) ...[
                    const Text(
                      'Available Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hospital.services.map((service) {
                        return Chip(
                          label: Text(service),
                          backgroundColor: AppColors.success.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Specialties
                  if (hospital.specialties.isNotEmpty) ...[
                    const Text(
                      'Medical Specialties',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hospital.specialties.map((specialty) {
                        return Chip(
                          label: Text(specialty),
                          backgroundColor: AppColors.info.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookAppointmentScreen(hospital: hospital),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Book Appointment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = 'tel:${hospital.phone}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final url = 'https://maps.google.com/?q=${hospital.latitude},${hospital.longitude}';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return _buildContactItemCore(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      label: label,
      value: value,
      onTap: onTap,
    );
  }

  Widget _buildContactItemAsset(
    String iconAsset,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return _buildContactItemCore(
      leading: Image.asset(
        iconAsset,
        width: 20,
        height: 20,
        color: AppColors.primary,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, color: AppColors.primary, size: 20),
      ),
      label: label,
      value: value,
      onTap: onTap,
    );
  }

  Widget _buildContactItemCore({
    required Widget leading,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: leading,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildBedStatusCard(
    String title,
    int occupied,
    int total,
    Color color,
  ) {
    final available = total - occupied;
    final percentage = (occupied / total * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
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
                  fontWeight: FontWeight.bold,
                  color: available > 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: occupied / total,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$occupied / $total beds occupied ($percentage%)',
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