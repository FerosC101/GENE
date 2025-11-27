import 'package:flutter/material.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/user_type.dart';

class RoleCard extends StatelessWidget {
  final UserType userType;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.userType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.network(
                    _assetFor(userType),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      userType.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userType.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userType.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _assetFor(UserType type) {
    switch (type) {
      case UserType.patient:
        return 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_patient_cpp8bs.png';
      case UserType.doctor:
        return 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_doctor_yigfmz.png';
      case UserType.hospitalStaff:
        return 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_hospital_staff_bh0leu.png';
      case UserType.admin:
        return 'https://res.cloudinary.com/dhqosbqeh/image/upload/v1763996687/usertype_admin_gqcnrm.png';
    }
  }
}