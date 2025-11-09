// lib/presentation/screens/doctor/doctor_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/doctor_schedule_model.dart';
import 'package:smart_hospital_app/presentation/providers/schedule_provider.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String hospitalId;

  const DoctorScheduleScreen({
    super.key,
    required this.doctorId,
    required this.hospitalId,
  });

  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  int _appointmentDuration = 30;
  int _maxAppointments = 16;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(doctorScheduleProvider(widget.doctorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          TextButton.icon(
            onPressed: () => _createDefaultSchedule(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Default',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedules) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Set your weekly availability. Patients can book appointments during these times.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Weekly Schedule
                const Text(
                  'Weekly Availability',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Days of the Week
                ...List.generate(7, (dayIndex) {
                  final existingSchedule = schedules.firstWhere(
                    (s) => s.dayOfWeek == dayIndex,
                    orElse: () => DoctorScheduleModel(
                      id: '',
                      doctorId: widget.doctorId,
                      hospitalId: widget.hospitalId,
                      dayOfWeek: dayIndex,
                      startTime: '09:00',
                      endTime: '17:00',
                      isAvailable: false,
                    ),
                  );

                  return _buildDayScheduleCard(existingSchedule);
                }),
                const SizedBox(height: 24),

                // Settings
                const Text(
                  '⚙️ Appointment Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
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
                    children: [
                      _buildSettingRow(
                        'Appointment Duration',
                        '$_appointmentDuration minutes',
                        Icons.timer,
                        () => _showDurationPicker(),
                      ),
                      const Divider(height: 24),
                      _buildSettingRow(
                        'Max Appointments per Day',
                        '$_maxAppointments appointments',
                        Icons.event_note,
                        () => _showMaxAppointmentsPicker(),
                      ),
                    ],
                  ),
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

  Widget _buildDayScheduleCard(DoctorScheduleModel schedule) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: schedule.isAvailable
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: schedule.isAvailable,
            onChanged: (value) => _toggleDayAvailability(schedule, value ?? false),
            activeColor: AppColors.success,
          ),
          const SizedBox(width: 12),

          // Day and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days[schedule.dayOfWeek],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: schedule.isAvailable
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.isAvailable
                      ? '${schedule.startTime} - ${schedule.endTime}'
                      : 'Not available',
                  style: TextStyle(
                    fontSize: 14,
                    color: schedule.isAvailable
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          if (schedule.isAvailable)
            IconButton(
              onPressed: () => _editSchedule(schedule),
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDayAvailability(DoctorScheduleModel schedule, bool isAvailable) async {
    try {
      if (schedule.id.isEmpty) {
        // Create new schedule
        final newSchedule = DoctorScheduleModel(
          id: '',
          doctorId: widget.doctorId,
          hospitalId: widget.hospitalId,
          dayOfWeek: schedule.dayOfWeek,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          isAvailable: isAvailable,
          maxAppointments: _maxAppointments,
          appointmentDuration: _appointmentDuration,
          createdAt: DateTime.now(),
        );
        await ref.read(scheduleControllerProvider.notifier).createSchedule(newSchedule);
      } else {
        // Update existing schedule
        await ref.read(scheduleControllerProvider.notifier).updateSchedule(
              schedule.id,
              {'isAvailable': isAvailable},
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule updated'),
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

  Future<void> _editSchedule(DoctorScheduleModel schedule) async {
    TimeOfDay? startTime = TimeOfDay(
      hour: int.parse(schedule.startTime.split(':')[0]),
      minute: int.parse(schedule.startTime.split(':')[1]),
    );

    TimeOfDay? endTime = TimeOfDay(
      hour: int.parse(schedule.endTime.split(':')[0]),
      minute: int.parse(schedule.endTime.split(':')[1]),
    );

    final result = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (context) => _TimeRangePickerDialog(
        dayName: schedule.dayName,
        initialStartTime: startTime,
        initialEndTime: endTime,
      ),
    );

    if (result != null) {
      final newStartTime = '${result['start']!.hour.toString().padLeft(2, '0')}:'
          '${result['start']!.minute.toString().padLeft(2, '0')}';
      final newEndTime = '${result['end']!.hour.toString().padLeft(2, '0')}:'
          '${result['end']!.minute.toString().padLeft(2, '0')}';

      try {
        await ref.read(scheduleControllerProvider.notifier).updateSchedule(
              schedule.id,
              {
                'startTime': newStartTime,
                'endTime': newEndTime,
              },
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated'),
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
  }

  Future<void> _createDefaultSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Default Schedule'),
        content: const Text(
          'This will create a default schedule (Mon-Fri, 9AM-5PM). '
          'Existing schedules will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(scheduleControllerProvider.notifier).createDefaultSchedule(
              doctorId: widget.doctorId,
              hospitalId: widget.hospitalId,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default schedule created'),
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
  }

  Future<void> _showDurationPicker() async {
    final durations = [15, 30, 45, 60];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Appointment Duration'),
        children: durations.map((duration) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, duration),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$duration minutes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: duration == _appointmentDuration
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: duration == _appointmentDuration
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _appointmentDuration = selected;
      });
    }
  }

  Future<void> _showMaxAppointmentsPicker() async {
    final counts = [8, 12, 16, 20, 24];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Max Appointments per Day'),
        children: counts.map((count) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, count),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$count appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: count == _maxAppointments
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: count == _maxAppointments
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _maxAppointments = selected;
      });
    }
  }
}

// Time Range Picker Dialog
class _TimeRangePickerDialog extends StatefulWidget {
  final String dayName;
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;

  const _TimeRangePickerDialog({
    required this.dayName,
    required this.initialStartTime,
    required this.initialEndTime,
  });

  @override
  State<_TimeRangePickerDialog> createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<_TimeRangePickerDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.dayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Start Time'),
            trailing: Text(
              _startTime.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End Time'),
            trailing: Text(
              _endTime.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'start': _startTime,
              'end': _endTime,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
