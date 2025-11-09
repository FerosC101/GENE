# 🤖 AI Chatbot Appointment Booking Integration Guide

## 📋 Overview

This guide explains how to integrate appointment booking functionality into the existing AI chatbot (`ai_chat_screen.dart`).

---

## 🎯 Current AI Chatbot Status

**Location:** `lib/presentation/screens/ai/ai_chat_screen.dart`

**Current Features:**
- ✅ Chat with Gemini AI
- ✅ Hospital context awareness
- ✅ Quick action buttons
- ✅ Typing indicators
- ✅ Message history

**What's Missing:**
- ❌ Appointment booking via chat
- ❌ Doctor search integration
- ❌ Appointment confirmation flow

---

## 🚀 How to Add Appointment Booking to AI Chatbot

### **Step 1: Update Gemini Prompt Context**

**File to modify:** `lib/services/gemini_service.dart` or `lib/gemini_service.dart`

Add appointment booking capabilities to the system prompt:

```dart
final systemPrompt = '''
You are an AI medical assistant for a smart hospital system.

Your capabilities include:
1. Answer medical questions
2. Help find hospitals and services
3. **Book appointments with doctors** ⬅️ ADD THIS
4. Provide emergency guidance

For appointment booking:
- When user asks to "book appointment" or "schedule consultation":
  1. Ask for their preferred specialty (e.g., cardiologist, pediatrician)
  2. Show available doctors
  3. Suggest available dates/times
  4. Confirm booking details

Response format for appointment booking:
{
  "action": "book_appointment",
  "specialty": "cardiology",
  "preferredDate": "2024-12-15"
}

Always be helpful, accurate, and professional.
''';
```

---

### **Step 2: Add Appointment Intent Detection**

**File to modify:** `lib/presentation/providers/chat_provider.dart`

Add logic to detect appointment booking intents:

```dart
Future<void> sendMessage(String message) async {
  // Add user message
  final userMessage = ChatMessage(
    text: message,
    isUser: true,
    timestamp: DateTime.now(),
  );
  state = [...state, userMessage];

  // Detect appointment booking intent
  if (_isAppointmentIntent(message)) {
    await _handleAppointmentBooking(message);
    return;
  }

  // Regular AI response
  final response = await _geminiService.sendMessage(message);
  final aiMessage = ChatMessage(
    text: response,
    isUser: false,
    timestamp: DateTime.now(),
  );
  state = [...state, aiMessage];
}

bool _isAppointmentIntent(String message) {
  final lowercased = message.toLowerCase();
  return lowercased.contains('book') && lowercased.contains('appointment') ||
         lowercased.contains('schedule') && lowercased.contains('doctor') ||
         lowercased.contains('see a doctor') ||
         lowercased.contains('consultation');
}

Future<void> _handleAppointmentBooking(String message) async {
  // Navigate to booking screen or start inline booking flow
  // Option 1: Direct navigation
  _navigateToBookingScreen();
  
  // Option 2: Inline booking flow (multi-step)
  await _startInlineBooking();
}
```

---

### **Step 3: Add Booking Flow State Machine**

Create a new state to track booking progress:

```dart
enum BookingStep {
  selectSpecialty,
  selectDoctor,
  selectDate,
  selectTime,
  enterComplaint,
  confirm,
}

class AppointmentBookingState {
  final BookingStep currentStep;
  final String? specialty;
  final String? doctorId;
  final DateTime? date;
  final TimeOfDay? time;
  final String? complaint;

  AppointmentBookingState({
    this.currentStep = BookingStep.selectSpecialty,
    this.specialty,
    this.doctorId,
    this.date,
    this.time,
    this.complaint,
  });

  AppointmentBookingState copyWith({...}) {
    // Implementation
  }
}
```

---

### **Step 4: Add Quick Action for Booking**

**File to modify:** `lib/presentation/screens/ai/ai_chat_screen.dart`

Add a quick action button:

```dart
QuickActionButton(
  icon: Icons.calendar_today,
  label: 'Book Appointment',
  color: AppColors.primary,
  onTap: () => _sendQuickAction('book_appointment'),
),
```

---

### **Step 5: Implement Multi-Step Booking in Chat**

```dart
Future<void> _startInlineBooking() async {
  // Step 1: Ask for specialty
  final specialtyMessage = ChatMessage(
    text: 'I can help you book an appointment! What type of doctor do you need?\n\n'
          '- Cardiologist\n'
          '- Pediatrician\n'
          '- General Practitioner\n'
          '- Dermatologist\n'
          'Or tell me your condition.',
    isUser: false,
    timestamp: DateTime.now(),
    isBookingPrompt: true,
  );
  state = [...state, specialtyMessage];
}

// When user responds with specialty
Future<void> _fetchDoctors(String specialty) async {
  final doctors = await _userRepository.getDoctorsBySpecialty(specialty);
  
  final doctorsList = doctors.map((d) => 
    '👨‍⚕️ Dr. ${d.fullName} - ${d.yearsOfExperience} years exp'
  ).join('\n');
  
  final message = ChatMessage(
    text: 'Here are available doctors:\n\n$doctorsList\n\n'
          'Which doctor would you like to see?',
    isUser: false,
    timestamp: DateTime.now(),
  );
  state = [...state, message];
}
```

---

### **Step 6: Add Confirmation & Create Appointment**

```dart
Future<void> _confirmBooking(AppointmentBookingState bookingState) async {
  final confirmMessage = ChatMessage(
    text: 'Perfect! Let me confirm your appointment:\n\n'
          '👨‍⚕️ Doctor: Dr. ${bookingState.doctorName}\n'
          '📅 Date: ${DateFormat('MMMM d, y').format(bookingState.date!)}\n'
          '⏰ Time: ${bookingState.time!.format(context)}\n'
          '💬 Reason: ${bookingState.complaint}\n\n'
          'Type "CONFIRM" to book, or "CANCEL" to cancel.',
    isUser: false,
    timestamp: DateTime.now(),
  );
  state = [...state, confirmMessage];
}

Future<void> _createAppointment(AppointmentBookingState bookingState) async {
  final appointment = AppointmentModel(
    id: '',
    patientId: currentUser.id,
    patientName: currentUser.fullName,
    patientPhone: currentUser.phoneNumber ?? '',
    patientEmail: currentUser.email,
    doctorId: bookingState.doctorId!,
    doctorName: bookingState.doctorName!,
    doctorSpecialty: bookingState.specialty!,
    hospitalId: bookingState.hospitalId!,
    hospitalName: bookingState.hospitalName!,
    dateTime: DateTime(
      bookingState.date!.year,
      bookingState.date!.month,
      bookingState.date!.day,
      bookingState.time!.hour,
      bookingState.time!.minute,
    ),
    type: AppointmentType.consultation,
    status: AppointmentStatus.pending,
    chiefComplaint: bookingState.complaint,
    createdAt: DateTime.now(),
  );

  await ref.read(appointmentControllerProvider.notifier).createAppointment(appointment);

  final successMessage = ChatMessage(
    text: '✅ Appointment booked successfully!\n\n'
          'Your appointment is pending confirmation from the doctor.\n'
          'You can view it in "My Appointments".',
    isUser: false,
    timestamp: DateTime.now(),
  );
  state = [...state, successMessage];
}
```

---

## 🎨 Enhanced UI Components

### **Add Booking Card Widget**

```dart
class BookingCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onTap;

  const BookingCard({...});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Dr. $doctorName', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medical_services, size: 16),
                  const SizedBox(width: 4),
                  Text(specialty),
                  const Spacer(),
                  Text(DateFormat('MMM d').format(date)),
                  const SizedBox(width: 8),
                  Text(time.format(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🔗 Integration Points

### **ChatMessage Model Extension**

Add fields to support booking prompts:

```dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isBookingPrompt;        // NEW
  final BookingStep? bookingStep;     // NEW
  final Map<String, dynamic>? data;   // NEW - For doctor/hospital data

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isBookingPrompt = false,
    this.bookingStep,
    this.data,
  });
}
```

---

## 📝 Example Conversation Flow

```
User: "I need to book an appointment"

AI: "I can help you book an appointment! What type of doctor do you need?
     - Cardiologist
     - Pediatrician
     - General Practitioner
     - Dermatologist
     Or tell me your condition."

User: "I need a cardiologist"

AI: "Here are available cardiologists:
     👨‍⚕️ Dr. Maria Santos - 15 years exp
     👨‍⚕️ Dr. John Reyes - 8 years exp
     
     Which doctor would you like to see?"

User: "Dr. Maria Santos"

AI: "Great choice! When would you like to see Dr. Maria Santos?
     
     Available dates:
     📅 December 15, 2024
     📅 December 16, 2024
     📅 December 18, 2024"

User: "December 15"

AI: "Dr. Maria Santos is available on December 15 at these times:
     ⏰ 09:00 AM
     ⏰ 10:00 AM
     ⏰ 02:00 PM
     ⏰ 03:30 PM"

User: "10:00 AM"

AI: "Perfect! What's the reason for your visit?"

User: "Chest pain and irregular heartbeat"

AI: "Let me confirm your appointment:
     👨‍⚕️ Doctor: Dr. Maria Santos
     📅 Date: December 15, 2024
     ⏰ Time: 10:00 AM
     💬 Reason: Chest pain and irregular heartbeat
     
     Type 'CONFIRM' to book, or 'CANCEL' to cancel."

User: "CONFIRM"

AI: "✅ Appointment booked successfully!
     
     Your appointment is pending confirmation from the doctor.
     You can view it in 'My Appointments'."
```

---

## 🎯 Alternative: Direct Navigation

**Simpler approach** - Just navigate to existing booking screen:

```dart
void _handleAppointmentBooking() {
  // Show AI message
  final message = ChatMessage(
    text: 'I'll help you book an appointment! Let me take you to the booking screen.',
    isUser: false,
    timestamp: DateTime.now(),
  );
  state = [...state, message];

  // Navigate after short delay
  Future.delayed(const Duration(milliseconds: 500), () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HospitalListScreen(),
      ),
    );
  });
}
```

---

## 🚀 Quick Implementation Steps

### **Option A: Full Conversational Booking (Complex)**
1. ✅ Update Gemini prompt with booking capabilities
2. ✅ Add booking state machine
3. ✅ Implement multi-step flow
4. ✅ Add confirmation logic
5. ✅ Create appointment via repository
6. ⏱️ **Estimated Time:** 4-6 hours

### **Option B: Direct Navigation (Simple)**
1. ✅ Detect booking intent in user message
2. ✅ Show AI confirmation message
3. ✅ Navigate to existing BookAppointmentScreen
4. ⏱️ **Estimated Time:** 30 minutes

---

## 💡 Recommendation

**Start with Option B** (Direct Navigation) because:
- ✅ Reuses existing booking screen
- ✅ Less code to maintain
- ✅ Faster to implement
- ✅ Still provides value
- ✅ Can upgrade to Option A later

**Then upgrade to Option A** when:
- Users request in-chat booking
- You have time for full implementation
- You want to showcase advanced AI features

---

## 📦 Required Imports

```dart
import 'package:smart_hospital_app/presentation/screens/patient/book_appointment_screen.dart';
import 'package:smart_hospital_app/presentation/providers/appointment_provider.dart';
import 'package:smart_hospital_app/data/models/appointment_model.dart';
import 'package:intl/intl.dart';
```

---

## ✨ Future Enhancements

1. **Voice Booking** - Use speech-to-text
2. **Smart Suggestions** - Recommend doctors based on symptoms
3. **Rescheduling** - Reschedule via chat
4. **Reminders** - "Your appointment is in 2 days"
5. **Follow-ups** - "How was your appointment with Dr. Santos?"
6. **Multi-language** - Support local languages

---

**Made with ❤️ for Smart Hospital App**
