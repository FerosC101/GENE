// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:smart_hospital_app/core/themes/app_theme.dart';
import 'package:smart_hospital_app/data/models/user_type.dart';
import 'package:smart_hospital_app/presentation/providers/auth_provider.dart';
import 'package:smart_hospital_app/presentation/screens/auth/welcome_screen.dart';
import 'package:smart_hospital_app/presentation/screens/home/home_screen.dart';
import 'package:smart_hospital_app/presentation/screens/staff/staff_dashboard_screen.dart';
import 'package:smart_hospital_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_hospital_app/presentation/screens/doctor/doctor_dashboard_screen.dart';
import 'package:smart_hospital_app/presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional for web)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ .env file not found, using default configuration');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // remove debug prints in production; keep as info for init
    // ignore: avoid_print
    print('✅ Firebase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MedMap AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          print('❌ No user - showing WelcomeScreen');
          return const WelcomeScreen();
        }

        print('✅ User logged in: ${user.email}');
        
        final userDataAsync = ref.watch(currentUserProvider);
        
        return userDataAsync.when(
          data: (userData) {
            if (userData == null) {
              print('❌ No user data - showing WelcomeScreen');
              return const WelcomeScreen();
            }

            print('👤 User Type: ${userData.userType.name}');
            
            // Route based on user type
            switch (userData.userType) {
              case UserType.admin:
                print('🔧 Routing to AdminDashboardScreen');
                return const AdminDashboardScreen();
                
              case UserType.hospitalStaff:
                print('👔 Routing to StaffDashboardScreen');
                if (userData.staffHospitalId == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: const Center(
                      child: Text('No hospital assigned. Contact admin.'),
                    ),
                  );
                }
                return const StaffDashboardScreen();
                
              case UserType.doctor:
                print('👨‍⚕️ Routing to DoctorDashboardScreen');
                return const DoctorDashboardScreen();
                
              case UserType.patient:
                print('👤 Routing to HomeScreen (Patient)');
                return const HomeScreen();
            }
          },
          loading: () {
            print('⏳ Loading user data...');
            return const SplashScreen();
          },
          error: (error, stack) {
            print('❌ User data error: $error');
            return const WelcomeScreen();
          },
        );
      },
      loading: () {
        print('⏳ Loading auth state...');
        return const SplashScreen();
      },
      error: (error, stack) {
        print('❌ Auth state error: $error');
        return const WelcomeScreen();
      },
    );
  }
}