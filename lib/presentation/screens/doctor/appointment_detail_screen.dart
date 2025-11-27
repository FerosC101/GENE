// lib/presentation/screens/doctor/appointment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/appointment_model.dart';
import 'package:pulse/data/models/appointment_status.dart' show AppointmentStatus;
import 'package:pulse/presentation/providers/appointment_provider.dart';
import 'package:intl/intl.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  ConsumerState<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  final _doctorNotesController = TextEditingController();
  final _prescriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _doctorNotesController.text = widget.appointment.doctorNotes ?? '';
    _prescriptionController.text = widget.appointment.prescription ?? '';
  }

  @override
  void dispose() {
    _doctorNotesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    final statusColor = switch (appointment.status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.info,
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled || AppointmentStatus.noShow => AppColors.error,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (appointment.status != AppointmentStatus.completed &&
              appointment.status != AppointmentStatus.cancelled)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Notes'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Information Section
            _buildSectionCard(
              title: '👤 Patient Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name:', appointment.patientName),
                  const SizedBox(height: 12),
                  _buildInfoRow('Phone:', appointment.patientPhone),
                  if (appointment.patientEmail != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('Email:', appointment.patientEmail!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appointment Details Section
            _buildSectionCard(
              title: '📅 Appointment Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Date:',
                    DateFormat('MMMM d, y').format(appointment.dateTime),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Time:',
                    '${DateFormat('hh:mm a').format(appointment.dateTime)} - '
                    '${DateFormat('hh:mm a').format(
                      appointment.dateTime.add(Duration(minutes: appointment.durationMinutes)),
                    )}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Type:', appointment.type.displayName),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chief Complaint & Symptoms Section
            if (appointment.chiefComplaint != null || appointment.symptoms != null)
              _buildSectionCard(
                title: '🩺 Patient Complaint',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appointment.chiefComplaint != null) ...[
                      const Text(
                        'Chief Complaint:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointment.chiefComplaint!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (appointment.symptoms != null) ...[
                      if (appointment.chiefComplaint != null) const SizedBox(height: 16),
                      const Text(
                        'Symptoms:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointment.symptoms!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Doctor's Notes Section
            _buildSectionCard(
              title: '📝 Doctor\'s Notes',
              child: _isEditing
                  ? TextField(
                      controller: _doctorNotesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter your clinical notes...',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : appointment.doctorNotes != null && appointment.doctorNotes!.isNotEmpty
                      ? Text(
                          appointment.doctorNotes!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text(
                          'No notes yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // Prescription Section
            _buildSectionCard(
              title: '💊 Prescription',
              child: _isEditing
                  ? TextField(
                      controller: _prescriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter prescription details...',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : appointment.prescription != null && appointment.prescription!.isNotEmpty
                      ? Text(
                          appointment.prescription!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text(
                          'No prescription yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (_isEditing)
              _buildActionButton(
                'Save Changes',
                Icons.save,
                AppColors.success,
                () => _saveChanges(),
              )
            else
              Column(
                children: [
                  if (appointment.status == AppointmentStatus.pending)
                    _buildActionButton(
                      'Confirm Appointment',
                      Icons.check_circle,
                      AppColors.success,
                      () => _updateStatus(AppointmentStatus.confirmed),
                    ),
                  if (appointment.status == AppointmentStatus.confirmed) ...[
                    _buildActionButton(
                      'Mark as Completed',
                      Icons.done_all,
                      AppColors.success,
                      () => _updateStatus(AppointmentStatus.completed),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'Mark as No Show',
                      Icons.person_off,
                      AppColors.error,
                      () => _updateStatus(AppointmentStatus.noShow),
                    ),
                  ],
                  if (appointment.status != AppointmentStatus.completed &&
                      appointment.status != AppointmentStatus.cancelled) ...[
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'Cancel Appointment',
                      Icons.cancel,
                      AppColors.error,
                      () => _cancelAppointment(),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      await ref.read(appointmentControllerProvider.notifier).updateAppointment(
            widget.appointment.id,
            {
              'doctorNotes': _doctorNotesController.text,
              'prescription': _prescriptionController.text,
            },
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(AppointmentStatus status) async {
    try {
      await ref.read(appointmentControllerProvider.notifier).updateStatus(
            widget.appointment.id,
            status,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment ${status.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(AppointmentStatus.cancelled);
    }
  }
}
