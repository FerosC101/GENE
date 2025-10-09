// lib/presentation/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/user_type.dart';
import 'package:smart_hospital_app/presentation/screens/auth/login_screen.dart';
import 'package:smart_hospital_app/presentation/screens/auth/register_screen.dart';
import 'package:smart_hospital_app/presentation/screens/auth/widgets/role_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  final bool isLogin;

  const RoleSelectionScreen({
    super.key,
    this.isLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Select Your Role to Login' : 'Select Your Role'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isLogin
                    ? 'Choose your account type to continue'
                    : 'How would you like to use MedMap AI?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Role Cards
              Expanded(
                child: ListView(
                  children: [
                    RoleCard(
                      userType: UserType.patient,
                      onTap: () => _navigateToAuth(context, UserType.patient),
                    ),
                    const SizedBox(height: 16),
                    RoleCard(
                      userType: UserType.doctor,
                      onTap: () => _navigateToAuth(context, UserType.doctor),
                    ),
                    const SizedBox(height: 16),
                    RoleCard(
                      userType: UserType.hospitalStaff,
                      onTap: () => _navigateToAuth(context, UserType.hospitalStaff),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAuth(BuildContext context, UserType userType) {
    if (isLogin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(userType: userType),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(userType: userType),
        ),
      );
    }
  }
}