// lib/presentation/screens/staff/widgets/department_status_card.dart
import 'package:flutter/material.dart';
import 'package:pulse/core/constants/app_colors.dart';

class DepartmentStatusCard extends StatelessWidget {
  final String department;
  final int occupied;
  final int total;
  final int available;

  const DepartmentStatusCard({
    super.key,
    required this.department,
    required this.occupied,
    required this.total,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (occupied / total * 100).toInt();
    final color = percentage > 90
        ? AppColors.error
        : percentage > 70
            ? AppColors.warning
            : AppColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  department,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$available available',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: occupied / total,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$occupied / $total beds occupied ($percentage%)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}