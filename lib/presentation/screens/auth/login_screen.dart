import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/user_type.dart';
import 'package:pulse/presentation/providers/auth_provider.dart';
import 'package:pulse/presentation/screens/auth/register_screen.dart';
import 'package:pulse/presentation/screens/auth/widgets/auth_text_field.dart';
import 'package:pulse/presentation/screens/home/home_screen.dart';
import 'package:pulse/presentation/screens/staff/staff_dashboard_screen.dart';
import 'package:pulse/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:pulse/presentation/screens/doctor/doctor_dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final UserType userType;

  const LoginScreen({
    super.key,
    required this.userType,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        // Wait for the user data to be available from the provider, then
        // navigate explicitly to the correct screen. This is more reliable
        // on mobile where the navigation stack can differ.
        try {
          // First try: wait briefly for the provider stream to emit
          final userData = await ref.read(currentUserProvider.future).timeout(const Duration(seconds: 4));
          if (userData != null) {
            final Widget target;
            switch (userData.userType) {
              case UserType.admin:
                target = const AdminDashboardScreen();
                break;
              case UserType.hospitalStaff:
                target = const StaffDashboardScreen();
                break;
              case UserType.doctor:
                target = const DoctorDashboardScreen();
                break;
              case UserType.patient:
                target = const HomeScreen();
                break;
            }

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => target),
              (route) => false,
            );
            return;
          }
        } catch (_) {
          // fallthrough: try direct fetch via AuthService
        }

        // Fallback: directly query AuthService for the current user data
        try {
          final authService = ref.read(authServiceProvider);
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }

          final userData = await authService.getUserData(currentUser.uid);
          if (userData == null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }

          final Widget target;
          switch (userData.userType) {
            case UserType.admin:
              target = const AdminDashboardScreen();
              break;
            case UserType.hospitalStaff:
              target = const StaffDashboardScreen();
              break;
            case UserType.doctor:
              target = const DoctorDashboardScreen();
              break;
            case UserType.patient:
              target = const HomeScreen();
              break;
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => target),
            (route) => false,
          );
        } catch (e) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(color: AppColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        widget.userType == UserType.patient
                            ? 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_patient_cpp8bs.png'
                            : widget.userType == UserType.doctor
                                ? 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_doctor_yigfmz.png'
                                : widget.userType == UserType.hospitalStaff
                                    ? 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_hospital_staff_bh0leu.png'
                                    : 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_admin_gqcnrm.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          widget.userType.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.userType.displayName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text('Forgot Password?'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              userType: widget.userType,
                            ),
                          ),
                        );
                      },
                      child: const Text('Register'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}