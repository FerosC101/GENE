# Doctor vs Patient Interfaces

## Overview
The app has **different interfaces** for doctors and patients, each tailored to their specific needs.

---

## 🏥 **Doctor Interface** (DoctorDashboardWebSimple)

### Features:
- **Welcome Card** - Personalized greeting with doctor's name
- **Today's Overview** - Statistics dashboard showing:
  - Total appointments (mobile only)
  - Patient count (mobile only)
  - Pending appointments (mobile only)
  - Completed appointments (mobile only)
- **Quick Actions**:
  - Manage Schedule - Set availability
  - View Appointments - See upcoming appointments
  - My Patients - View patient list
- **Special Note**: Info card explaining mobile app has full features

### Visual Differences:
- **Primary color scheme** (medical blue)
- **Professional dashboard layout**
- **Doctor-specific actions** and metrics
- **Gradient header** with role identification

### Routing:
```dart
case UserType.doctor:
  return const DoctorDashboardWebSimple();
```

---

## 👤 **Patient Interface** (HomeScreen)

### Features:
- **Search Hospitals** - Find medical facilities
- **Hospital Map** - Interactive Google Maps view
- **Hospital List** - Browse all hospitals with details:
  - Distance from user
  - Bed availability (ICU, ER, Ward)
  - Wait times
  - Contact information
- **AI Health Chat** - Get medical guidance
- **Quick Stats** - System-wide hospital statistics

### Visual Differences:
- **User-friendly layout**
- **Map-centric design**
- **Search and browse functionality**
- **Focus on finding care**

### Routing:
```dart
case UserType.patient:
  return const HomeScreen();
```

---

## 🔐 Testing Different User Types

### To test as a Doctor:
1. Register/Login with email
2. In Firebase Console > Firestore > users collection
3. Find your user document
4. Change `userType` field to: `"doctor"`
5. Add doctor-specific fields:
   - `specialty`: "Cardiology" (or any specialty)
   - `licenseNumber`: "MD-123456"
   - `hospitalId`: (ID of a hospital from hospitals collection)
6. Refresh the app - you'll see **Doctor Dashboard**

### To test as a Patient:
1. Register/Login with email
2. User type is `"patient"` by default
3. You'll see the **Home Screen** with hospital map

---

## 📱 Full Features on Mobile

The **web version** has a simplified doctor dashboard because of a Flutter web compilation issue with appointment models.

### Full Doctor Features (Android/iOS):
- ✅ View all appointments (today, upcoming, past)
- ✅ Manage appointment schedule (set availability hours)
- ✅ Update appointment status (confirm/complete/cancel)
- ✅ Add clinical notes and prescriptions
- ✅ View patient details
- ✅ Appointment notifications

### To Run on Android:
```bash
flutter run -d <android-device-id>
```

### To Run on Windows:
```bash
flutter run -d windows
```

---

## 🎨 Visual Comparison

| Feature | Doctor Dashboard | Patient Home |
|---------|-----------------|--------------|
| **Primary Action** | Manage appointments | Find hospitals |
| **Main View** | Appointment list | Hospital map |
| **Color Scheme** | Medical blue gradient | Standard theme |
| **Navigation** | Dashboard cards | Search + browse |
| **Focus** | Provider workflow | Care seeker |

---

## Current Status

✅ **Working**: Different interfaces for doctor vs patient
⚠️ **Web Limitation**: Doctor appointment features simplified (mobile has full features)
✅ **Routing**: Correctly routes based on user type
✅ **UI**: Distinct visual design for each role

---

## Troubleshooting

**If you see the same interface for both:**

1. **Check your user type in Firebase**:
   - Open Firebase Console
   - Go to Firestore Database
   - Open `users` collection
   - Find your user document
   - Verify `userType` field is set correctly

2. **Hot restart the app**:
   - Press `R` in the terminal (capital R for hot restart)
   - Or stop and run `flutter run -d chrome` again

3. **Check browser console**:
   - Look for routing logs like:
   - `👨‍⚕️ Routing to DoctorDashboardWebSimple` (doctor)
   - `👤 Routing to HomeScreen (Patient)` (patient)

4. **Clear cache and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```
