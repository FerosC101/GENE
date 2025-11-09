// lib/presentation/screens/patient/book_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/appointment_model.dart';
import 'package:smart_hospital_app/data/models/appointment_status.dart';
import 'package:smart_hospital_app/data/models/appointment_type.dart';
import 'package:smart_hospital_app/data/models/hospital_model.dart';
import 'package:smart_hospital_app/data/models/user_model.dart';
import 'package:smart_hospital_app/data/models/doctor_schedule_model.dart';
import 'package:smart_hospital_app/presentation/providers/user_provider.dart';
import 'package:smart_hospital_app/presentation/providers/schedule_provider.dart';
import 'package:smart_hospital_app/presentation/providers/appointment_provider.dart';
import 'package:smart_hospital_app/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final HospitalModel hospital;

  const BookAppointmentScreen({
    super.key,
    required this.hospital,
  });

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  UserModel? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  AppointmentType _selectedType = AppointmentType.consultation;
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsByHospitalProvider(widget.hospital.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: doctorsAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return _buildNoDoctorsState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hospital Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, color: AppColors.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hospital.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.hospital.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step 1: Select Doctor
                _buildSectionTitle('1. Select Doctor'),
                const SizedBox(height: 12),
                _buildDoctorsList(doctors),
                const SizedBox(height: 24),

                // Step 2: Select Date
                if (_selectedDoctor != null) ...[
                  _buildSectionTitle('2. Select Date'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                ],

                // Step 3: Select Time
                if (_selectedDoctor != null && _selectedDate != null) ...[
                  _buildSectionTitle('3. Select Time'),
                  const SizedBox(height: 12),
                  _buildTimeSlots(),
                  const SizedBox(height: 24),
                ],

                // Step 4: Appointment Type
                if (_selectedTime != null) ...[
                  _buildSectionTitle('4. Appointment Type'),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                ],

                // Step 5: Chief Complaint
                if (_selectedTime != null) ...[
                  _buildSectionTitle('5. Chief Complaint'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chiefComplaintController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Briefly describe your main concern...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Symptoms (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'List your symptoms...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Book Button
                if (_selectedTime != null && _chiefComplaintController.text.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildNoDoctorsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No doctors available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This hospital has no doctors registered yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDoctorsList(List<UserModel> doctors) {
    return Column(
      children: doctors.map((doctor) {
        final isSelected = _selectedDoctor?.id == doctor.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedDoctor = doctor;
                _selectedDate = null;
                _selectedTime = null;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.fullName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.medical_services, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              doctor.specialty ?? 'General Practitioner',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (doctor.yearsOfExperience != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${doctor.yearsOfExperience} years experience',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                    : 'Select a date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedDate == null || _selectedDoctor == null) {
      return const SizedBox.shrink();
    }

    final dayOfWeek = (_selectedDate!.weekday - 1) % 7; // Convert to 0-6 (Mon-Sun)
    final scheduleAsync = ref.watch(doctorScheduleProvider(_selectedDoctor!.id));

    return scheduleAsync.when(
      data: (schedules) {
        final daySchedule = schedules.firstWhere(
          (s) => s.dayOfWeek == dayOfWeek && s.isAvailable,
          orElse: () => throw Exception('No schedule'),
        );

        final timeSlots = _generateTimeSlots(daySchedule.startTime, daySchedule.endTime, daySchedule.appointmentDuration);

        if (timeSlots.isEmpty) {
          return const Text('No available time slots');
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final isSelected = _selectedTime?.hour == slot.hour && _selectedTime?.minute == slot.minute;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTime = slot;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  slot.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Doctor not available on this day'),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppointmentType.values.map((type) {
        final isSelected = _selectedType == type;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Text(
              type.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TimeOfDay> _generateTimeSlots(String startTime, String endTime, int durationMinutes) {
    final slots = <TimeOfDay>[];
    final start = TimeOfDay(
      hour: int.parse(startTime.split(':')[0]),
      minute: int.parse(startTime.split(':')[1]),
    );
    final end = TimeOfDay(
      hour: int.parse(endTime.split(':')[0]),
      minute: int.parse(endTime.split(':')[1]),
    );

    var current = start;
    while (current.hour < end.hour || (current.hour == end.hour && current.minute < end.minute)) {
      slots.add(current);
      final newMinute = current.minute + durationMinutes;
      current = TimeOfDay(
        hour: current.hour + (newMinute ~/ 60),
        minute: newMinute % 60,
      );
    }

    return slots;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctor == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book an appointment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final appointment = AppointmentModel(
      id: '',
      patientId: user.id,
      patientName: user.fullName,
      patientPhone: user.phoneNumber ?? '',
      patientEmail: user.email,
      doctorId: _selectedDoctor!.id,
      doctorName: _selectedDoctor!.fullName,
      doctorSpecialty: _selectedDoctor!.specialty ?? 'General Practitioner',
      hospitalId: widget.hospital.id,
      hospitalName: widget.hospital.name,
      dateTime: appointmentDateTime,
      durationMinutes: 30,
      type: _selectedType,
      status: AppointmentStatus.pending,
      chiefComplaint: _chiefComplaintController.text.trim(),
      symptoms: _symptomsController.text.trim().isNotEmpty ? _symptomsController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(appointmentControllerProvider.notifier).createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
