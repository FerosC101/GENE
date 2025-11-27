import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/user_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/presentation/providers/auth_provider.dart';
import 'package:pulse/presentation/screens/auth/login_screen.dart';
import 'package:pulse/presentation/screens/auth/widgets/auth_text_field.dart';
import 'package:pulse/presentation/screens/home/home_screen.dart';
import 'package:pulse/presentation/screens/staff/staff_dashboard_screen.dart';
import 'package:pulse/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:pulse/presentation/screens/doctor/doctor_dashboard_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final UserType userType;

  const RegisterScreen({
    super.key,
    required this.userType,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Doctor-specific
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();
  
  // Hospital Staff-specific
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  
  // Patient-specific
  final _addressController = TextEditingController();
  String? _selectedBloodType;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    // Fetch hospitals if registering hospital staff so dropdown has initial data
    if (widget.userType == UserType.hospitalStaff) {
      _fetchHospitals();
    }
  }

  Future<void> _fetchHospitals() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('hospitals').limit(1).get();
      if (snap.docs.isNotEmpty && _selectedHospitalId == null) {
        final doc = snap.docs.first;
        final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        setState(() {
          _selectedHospitalId = doc.id;
          _selectedHospitalName = data['name'] as String?;
        });
      }
    } catch (_) {
      // ignore errors here; StreamBuilder will handle live data
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> additionalData = {};
      
      switch (widget.userType) {
        case UserType.doctor:
          additionalData = {
            'specialty': _specialtyController.text.trim(),
            'licenseNumber': _licenseController.text.trim(),
            'hospitalId': _selectedHospitalId,
          };
          break;
        case UserType.hospitalStaff:
          additionalData = {
            'position': _positionController.text.trim(),
            'department': _departmentController.text.trim(),
            'staffHospitalId': _selectedHospitalId,
            'staffHospitalName': _selectedHospitalName,
            'permissions': ['bed_management', 'patient_management', 'queue_management'],
          };
          break;
        case UserType.admin:
          additionalData = {
            'permissions': ['full_access'],
            'isSystemAdmin': true,
          };
          break;
        case UserType.patient:
          additionalData = {
            'address': _addressController.text.trim(),
            if (_selectedBloodType != null) 'bloodType': _selectedBloodType,
          };
          break;
      }

      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            userType: widget.userType,
            phoneNumber: _phoneController.text.trim(),
            additionalData: additionalData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        try {
          // try provider with short timeout first
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
          // fallthrough
        }

        // fallback: fetch directly from AuthService
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(color: AppColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: () => Navigator.of(context).pop(),
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
                        'Register as ${widget.userType.displayName}',
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
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in your details to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                AuthTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+63 XXX XXX XXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                ..._buildRoleSpecificFields(),

                const SizedBox(height: 16),

                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() => _agreedToTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: const TextStyle(fontSize: 14),
                          children: const [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              userType: widget.userType,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      child: const Text('Login'),
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

  List<Widget> _buildRoleSpecificFields() {
    switch (widget.userType) {
      case UserType.doctor:
        return [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Column(
                  children: [
                    const Text(
                      'No hospitals available. Please contact admin.',
                      style: TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final hospitals = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Hospital',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHospitalId,
                    decoration: InputDecoration(
                      hintText: 'Choose your hospital',
                      prefixIcon: const Icon(Icons.local_hospital),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: hospitals.map((doc) {
                      final data = (doc.data() as Map<String, dynamic>?) ??
                          <String, dynamic>{};
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unknown Hospital'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHospitalId = value;
                        final hospitalDoc = hospitals.firstWhere(
                            (doc) => doc.id == value);
                        final data = (hospitalDoc.data() as Map<String, dynamic>?) ??
                            <String, dynamic>{};
                        _selectedHospitalName = data['name'] as String?;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a hospital';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          AuthTextField(
            controller: _specialtyController,
            label: 'Specialty',
            hint: 'e.g., Cardiology, Pediatrics',
            prefixIcon: Icons.medical_services_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your specialty';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _licenseController,
            label: 'License Number',
            hint: 'Enter your medical license number',
            prefixIcon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your license number';
              }
              return null;
            },
          ),
        ];

      case UserType.hospitalStaff:
        return [
          // Hospital selection + position/department
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Column(
                  children: [
                    const Text(
                      'No hospitals available. Please contact admin.',
                      style: TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final hospitals = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Hospital',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHospitalId,
                    decoration: InputDecoration(
                      hintText: 'Choose your hospital',
                      prefixIcon: const Icon(Icons.local_hospital),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: hospitals.map((doc) {
                      final data = (doc.data() as Map<String, dynamic>?) ??
                          <String, dynamic>{};
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unknown Hospital'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHospitalId = value;
                        final hospitalDoc = hospitals.firstWhere(
                            (doc) => doc.id == value);
                        final data = (hospitalDoc.data() as Map<String, dynamic>?) ??
                            <String, dynamic>{};
                        _selectedHospitalName = data['name'] as String?;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your hospital';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          AuthTextField(
            controller: _positionController,
            label: 'Position',
            hint: 'e.g., Nurse, Receptionist',
            prefixIcon: Icons.work_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your position';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _departmentController,
            label: 'Department',
            hint: 'e.g., Emergency, ICU',
            prefixIcon: Icons.apartment_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your department';
              }
              return null;
            },
          ),
        ];

      case UserType.admin:
        // Admin-specific fields can be added here, for now none required
        return [];

      case UserType.patient:
        return [
          AuthTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter your complete address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blood Type (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                decoration: InputDecoration(
                  hintText: 'Select your blood type',
                  prefixIcon: const Icon(Icons.bloodtype_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                items: _bloodTypes.map((bloodType) {
                  return DropdownMenuItem(
                    value: bloodType,
                    child: Text(bloodType),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBloodType = value);
                },
              ),
            ],
          ),
        ];
    }
  }
}