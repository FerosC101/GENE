# 🚀 Quick Start Guide - Testing the Appointment System

## ⚡ 5-Minute Setup & Test

### **Prerequisites:**
- ✅ Flutter SDK installed
- ✅ Firebase project configured
- ✅ Firebase rules updated (see below)
- ✅ Android/iOS emulator or physical device

---

## 🔥 Step 1: Update Firebase Rules (CRITICAL!)

Go to **Firebase Console → Firestore Database → Rules** and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow read access to hospitals for all authenticated users
    match /hospitals/{hospitalId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType in ['admin', 'hospitalStaff'];
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Appointments - accessible by patient, doctor, staff, admin
    match /appointments/{appointmentId} {
      allow read: if request.auth != null &&
        (resource.data.patientId == request.auth.uid ||
         resource.data.doctorId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType in ['hospitalStaff', 'admin']);
      
      allow create: if request.auth != null;
      
      allow update, delete: if request.auth != null &&
        (resource.data.doctorId == request.auth.uid ||
         resource.data.patientId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType in ['hospitalStaff', 'admin']);
    }
    
    // Doctor schedules - readable by all, writable by doctor/staff/admin
    match /doctor_schedules/{scheduleId} {
      allow read: if request.auth != null;
      
      allow write: if request.auth != null &&
        (resource.data.doctorId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType in ['hospitalStaff', 'admin']);
    }
  }
}
```

Click **Publish** to save the rules.

---

## 📱 Step 2: Run the App

```powershell
# Navigate to project directory
cd d:\coding\flutter\gene

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🏥 Step 3: Create Test Data

### **Create a Hospital (Via Firebase Console)**

1. Go to **Firestore Database**
2. Click **+ Start collection**
3. Collection ID: `hospitals`
4. Add document with auto-ID
5. Add fields:

```json
{
  "name": "Metro General Hospital",
  "address": "123 Main St, Manila",
  "latitude": 14.5995,
  "longitude": 120.9842,
  "phone": "+63 2 1234 5678",
  "email": "info@metrogeneral.com",
  "type": "public",
  "services": ["Emergency", "ICU", "Surgery"],
  "specialties": ["Cardiology", "Pediatrics", "Orthopedics"],
  "imageUrl": "",
  "status": {
    "icuTotal": 10,
    "icuOccupied": 5,
    "erTotal": 20,
    "erOccupied": 10,
    "wardTotal": 50,
    "wardOccupied": 30,
    "waitTimeMinutes": 45,
    "isOperational": true
  },
  "createdAt": [Firebase Timestamp - use server timestamp],
  "updatedAt": [Firebase Timestamp - use server timestamp]
}
```

---

## 👨‍⚕️ Step 4: Register as Doctor

1. **Launch App**
2. Click **"Get Started"**
3. Select **"Doctor"**
4. Fill in registration:
   - Full Name: `Dr. John Smith`
   - Email: `doctor@test.com`
   - Phone: `+63 912 345 6789`
   - Password: `password123`
   - **Hospital:** Select "Metro General Hospital" from dropdown
   - Specialty: `Cardiology`
   - License Number: `DOC123456`
5. Click **"Create Account"**

✅ You should now be on the **Doctor Dashboard**

---

## 🗓️ Step 5: Set Doctor Schedule

1. From Doctor Dashboard, click **"My Schedule"**
2. Click **"Default"** button (top right)
   - This creates Mon-Fri, 9AM-5PM schedule
3. Confirm creation
4. ✅ Schedule is now set!

**OR manually:**
1. Toggle **Monday** ON
2. Click **"Edit"** → Set 09:00 AM - 05:00 PM
3. Repeat for other days

---

## 🧑 Step 6: Register as Patient

1. **Logout** from doctor account (top right)
2. Click **"Get Started"**
3. Select **"Patient"**
4. Fill in registration:
   - Full Name: `Jane Doe`
   - Email: `patient@test.com`
   - Phone: `+63 923 456 7890`
   - Password: `password123`
   - Address: `456 Oak St, Manila`
   - Blood Type: `O+` (optional)
5. Click **"Create Account"**

✅ You should now be on the **Patient Home Screen**

---

## 📅 Step 7: Book an Appointment

### **From Patient Home:**

1. Click **"Search hospitals"** bar
2. Select **"Metro General Hospital"**
3. On hospital detail page, click **"Book Appointment"** (big blue button at top)

### **Booking Flow:**

**Step 1 - Select Doctor:**
- You should see Dr. John Smith (Cardiology)
- Click on the doctor card

**Step 2 - Select Date:**
- Click the date selector
- Choose a weekday (Monday-Friday) - MUST be a day doctor is available
- Click OK

**Step 3 - Select Time:**
- Choose from available time slots (e.g., 09:00 AM, 09:30 AM, etc.)
- Click on a time slot

**Step 4 - Appointment Type:**
- Select "Consultation"

**Step 5 - Chief Complaint:**
- Enter: `Chest pain and irregular heartbeat`
- Click **"Book Appointment"**

✅ **Success!** Appointment created with status "Pending"

---

## 👨‍⚕️ Step 8: Doctor Confirms Appointment

1. **Logout** from patient account
2. **Login** as doctor (`doctor@test.com` / `password123`)
3. You should see the appointment on **Today's Appointments** (if booked for today) or **All Appointments**
4. Click on the appointment card
5. Click **"Confirm Appointment"**
6. Add doctor notes: `Initial consultation for cardiac evaluation`
7. Click **"Save Changes"**

✅ **Status changed to "Confirmed"**

---

## 🎯 Step 9: View from Patient Side

1. **Logout** from doctor account
2. **Login** as patient (`patient@test.com` / `password123`)
3. Click **"My Appointments"** card on home screen
4. You should see the confirmed appointment under **"Upcoming Appointments"**
5. Click to view details
6. ✅ You can see the status is now **"Confirmed"**!

---

## ✅ Test Complete!

### **You just successfully:**
1. ✅ Created a hospital in Firestore
2. ✅ Registered a doctor with hospital assignment
3. ✅ Set doctor's weekly schedule
4. ✅ Registered a patient
5. ✅ Booked an appointment
6. ✅ Doctor confirmed the appointment
7. ✅ Patient viewed the confirmed appointment

---

## 🎉 What Works Now

### **Doctor Features:**
- ✅ Dashboard with today's stats
- ✅ View all appointments (filtered by status)
- ✅ Confirm/Complete/Cancel appointments
- ✅ Add notes and prescriptions
- ✅ Manage weekly schedule
- ✅ View patient history

### **Patient Features:**
- ✅ Search hospitals
- ✅ View hospital details
- ✅ Book appointments with doctors
- ✅ View upcoming and past appointments
- ✅ Cancel appointments
- ✅ View prescriptions

---

## 🐛 Common Issues & Solutions

### **Issue 1: "No doctors available"**
**Solution:** 
- Make sure doctor registration included hospital selection
- Check `users` collection - doctor should have `hospitalId` field
- Verify `hospitalId` matches the hospital document ID

### **Issue 2: "No time slots available"**
**Solution:**
- Doctor must have created a schedule first
- Check `doctor_schedules` collection
- Selected date must be an enabled day (isAvailable: true)
- Ensure you selected a weekday if using default schedule

### **Issue 3: Firebase permission denied**
**Solution:**
- Update Firestore rules (Step 1)
- Make sure user is authenticated
- Check browser console/Flutter logs for detailed errors

### **Issue 4: "Hospital dropdown empty"**
**Solution:**
- Create at least one hospital in Firestore (Step 3)
- Refresh the registration screen
- Check Firebase Console for hospital documents

---

## 📊 Check Firebase Data

### **After testing, you should see:**

**Firestore Collections:**
```
hospitals/
  └─ [hospitalId]/
      └─ name, address, status, etc.

users/
  └─ [doctorId]/
      └─ userType: "doctor"
      └─ hospitalId: "[hospitalId]"
      └─ specialty: "Cardiology"
  └─ [patientId]/
      └─ userType: "patient"

doctor_schedules/
  └─ [scheduleId]/
      └─ doctorId: "[doctorId]"
      └─ dayOfWeek: 0 (Monday)
      └─ startTime: "09:00"
      └─ endTime: "17:00"
  └─ [scheduleId]/
      └─ dayOfWeek: 1 (Tuesday)
      ...

appointments/
  └─ [appointmentId]/
      └─ patientId: "[patientId]"
      └─ doctorId: "[doctorId]"
      └─ hospitalId: "[hospitalId]"
      └─ status: "confirmed"
      └─ dateTime: [timestamp]
      └─ chiefComplaint: "Chest pain..."
```

---

## 🎬 Next Steps

### **Test More Features:**
1. ✅ Complete an appointment (Doctor side)
2. ✅ Add prescription (Doctor side)
3. ✅ View prescription (Patient side)
4. ✅ Cancel an appointment (Patient side)
5. ✅ Mark as no-show (Doctor side)
6. ✅ View patient history (Doctor → My Patients)
7. ✅ Edit doctor schedule (Change hours)

### **Add More Test Data:**
1. Create 2-3 more hospitals
2. Register 2-3 more doctors (different specialties)
3. Book multiple appointments
4. Test appointment filtering (Pending, Confirmed, Completed)

---

## 🏆 Success Metrics

Your system is working if:
- ✅ Doctor sees new appointments in dashboard
- ✅ Patient can book without errors
- ✅ Statuses update in real-time
- ✅ Time slots respect doctor schedule
- ✅ Both sides see the same appointment data
- ✅ Notifications work (if implemented)

---

## 📱 Screenshots to Take

For documentation:
1. Doctor Dashboard
2. Doctor Schedule Screen
3. Appointment Detail (with notes)
4. Patient Booking Flow (all 5 steps)
5. Patient Appointments List
6. Hospital Detail with "Book Appointment" button

---

## 🎊 Congratulations!

You've successfully tested the complete appointment booking system!

**Built with:**
- Flutter 3.x
- Firebase (Firestore + Auth)
- Riverpod State Management
- Material Design 3

---

## 📞 Need Help?

If something doesn't work:
1. Check Flutter console for errors
2. Verify Firebase rules
3. Check Firestore data structure
4. Ensure user is authenticated
5. Clear app data and restart

---

**Happy Testing! 🚀**

Made with ❤️ for Smart Hospital App
