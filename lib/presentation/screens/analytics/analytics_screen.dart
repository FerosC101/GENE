// lib/presentation/screens/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/presentation/providers/hospital_provider.dart';
import 'package:pulse/presentation/screens/analytics/ml_predictions_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedHospitalId; // null means "All Hospitals"

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            initialValue: 'today',
            onSelected: (value) {
              // Handle time period selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
            ],
          ),
        ],
      ),
      body: hospitalsAsync.when(
        data: (hospitals) {
          if (hospitals.isEmpty) {
            return _buildEmptyState();
          }

          // Filter hospitals based on selection
          final filteredHospitals = _selectedHospitalId == null
              ? hospitals
              : hospitals.where((h) => h.id == _selectedHospitalId).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(hospitalsStreamProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Filter Dropdown
                  _buildHospitalFilter(hospitals),
                  const SizedBox(height: 24),

                  // System Overview Cards
                  _buildSystemOverview(filteredHospitals),
                  const SizedBox(height: 24),

                  // ML Predictions Button
                  _buildMLButton(context),
                  const SizedBox(height: 24),

                  // Bed Occupancy Rate Chart
                  _buildSectionHeader('Bed Occupancy Rate'),
                  const SizedBox(height: 16),
                  _buildOccupancyChart(filteredHospitals),
                  const SizedBox(height: 24),

                  // Hospital Comparison
                  if (_selectedHospitalId == null) ...[
                    _buildSectionHeader('Hospital Comparison'),
                    const SizedBox(height: 16),
                    _buildHospitalComparison(filteredHospitals),
                    const SizedBox(height: 24),
                  ],

                  // Department Performance
                  _buildSectionHeader('Department Performance'),
                  const SizedBox(height: 16),
                  _buildDepartmentPerformance(filteredHospitals),
                  const SizedBox(height: 24),

                  // Capacity Alerts
                  _buildSectionHeader('Capacity Alerts'),
                  const SizedBox(height: 16),
                  _buildCapacityAlerts(filteredHospitals),
                  const SizedBox(height: 24),

                  // AI Insights
                  _buildSectionHeader('AI Insights'),
                  const SizedBox(height: 16),
                  _buildAIInsights(filteredHospitals),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No data available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Analytics will appear when hospital data is available',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalFilter(List hospitals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text(
            'Filter by Hospital:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedHospitalId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Hospitals'),
                ),
                ...hospitals.map<DropdownMenuItem<String?>>((hospital) {
                  return DropdownMenuItem<String?>(
                    value: hospital.id,
                    child: Text(
                      hospital.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedHospitalId = value;
                });
              },
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview(List hospitals) {
    final totalBeds = hospitals.fold<int>(0, (sum, h) => sum + h.status.totalBeds as int);
    final totalOccupied = hospitals.fold<int>(0, (sum, h) => sum + h.status.totalOccupied as int);
    final availableBeds = totalBeds - totalOccupied;
    final operationalHospitals = hospitals.where((h) => h.status.isOperational).length;
    final avgWaitTime = hospitals.isNotEmpty
        ? hospitals.fold<int>(0, (sum, h) => sum + h.status.waitTimeMinutes as int) ~/ hospitals.length
        : 0;
    final occupancyRate = totalBeds > 0 ? (totalOccupied / totalBeds * 100).toInt() : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Beds',
                '$totalBeds',
                '$occupancyRate% occupied',
                Icons.hotel,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Available',
                '$availableBeds',
                'beds open',
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Hospitals',
                '$operationalHospitals',
                'operational',
                Icons.local_hospital,
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Avg Wait',
                '$avgWaitTime min',
                'current time',
                Icons.access_time,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MLPredictionsScreen()),
          );
        },
        icon: const Icon(Icons.psychology, size: 24),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'View ML Predictions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '4 Models',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildOccupancyChart(List hospitals) {
    final icuOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuOccupied) as int);
    final icuTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuTotal) as int);
    final erOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.erOccupied) as int);
    final erTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.erTotal) as int);
    final wardOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.wardOccupied) as int);
    final wardTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.wardTotal) as int);

    final double icuRate = icuTotal > 0 ? (icuOccupied / icuTotal * 100) : 0.0;
    final double erRate = erTotal > 0 ? (erOccupied / erTotal * 100) : 0.0;
    final double wardRate = wardTotal > 0 ? (wardOccupied / wardTotal * 100) : 0.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: icuRate.toDouble(),
                  color: AppColors.error,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: erRate.toDouble(),
                  color: AppColors.warning,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: wardRate.toDouble(),
                  color: AppColors.info,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['ICU', 'ER', 'Ward'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildHospitalComparison(List hospitals) {
    return Column(
      children: hospitals.map<Widget>((hospital) {
        final occupancyRate = hospital.status.totalBeds > 0
            ? hospital.status.totalOccupied / hospital.status.totalBeds
            : 0;
        final percentage = (occupancyRate * 100).toInt();
        
        Color progressColor;
        if (occupancyRate >= 0.9) {
          progressColor = AppColors.error;
        } else if (occupancyRate >= 0.7) {
          progressColor = AppColors.warning;
        } else {
          progressColor = AppColors.success;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancyRate,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${hospital.status.totalOccupied}/${hospital.status.totalBeds} beds',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Wait: ${hospital.status.waitTimeMinutes} min',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDepartmentPerformance(List hospitals) {
    final icuOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuOccupied) as int);
    final icuTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuTotal) as int);
    final erOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.erOccupied) as int);
    final erTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.erTotal) as int);
    final wardOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.wardOccupied) as int);
    final wardTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.wardTotal) as int);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDepartmentRow(
            'ICU',
            icuOccupied,
            icuTotal,
            AppColors.error,
            Icons.emergency,
          ),
          const Divider(height: 24),
          _buildDepartmentRow(
            'Emergency Room',
            erOccupied,
            erTotal,
            AppColors.warning,
            Icons.local_hospital,
          ),
          const Divider(height: 24),
          _buildDepartmentRow(
            'Ward',
            wardOccupied,
            wardTotal,
            AppColors.info,
            Icons.hotel,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(
    String name,
    int occupied,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (occupied / total * 100).toInt() : 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$occupied / $total beds',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityAlerts(List hospitals) {
    final criticalHospitals = hospitals.where((h) {
      final rate = h.status.totalBeds > 0 
          ? h.status.totalOccupied / h.status.totalBeds 
          : 0;
      return rate > 0.9;
    }).toList();

    if (criticalHospitals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Clear',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No capacity alerts at this time',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: criticalHospitals.map((hospital) {
        final rate = hospital.status.totalOccupied / hospital.status.totalBeds;
        final percentage = (rate * 100).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Critical capacity: $percentage% occupancy',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIInsights(List hospitals) {
    final insights = <Map<String, dynamic>>[];
    
    // Calculate system metrics
    final totalOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.totalOccupied) as int);
    final totalBeds = hospitals.fold<int>(0, (sum, h) => (sum + h.status.totalBeds) as int);
    final systemOccupancy = totalBeds > 0 ? totalOccupied / totalBeds : 0;
    final avgWaitTime = hospitals.isNotEmpty
        ? hospitals.fold<int>(0, (sum, h) => (sum + h.status.waitTimeMinutes) as int) / hospitals.length
        : 0.0;

    // Generate insights
    if (systemOccupancy > 0.85) {
      insights.add({
        'icon': Icons.trending_up,
        'color': AppColors.error,
        'title': 'High System Occupancy',
        'description': 'System at ${(systemOccupancy * 100).toInt()}% capacity. Consider activating overflow protocols.',
      });
    }

    if (avgWaitTime > 45) {
      insights.add({
        'icon': Icons.access_time,
        'color': AppColors.warning,
        'title': 'Extended Wait Times',
        'description': 'Average wait time is ${avgWaitTime.toInt()} minutes. Recommend increasing triage efficiency.',
      });
    }

    // Check ICU capacity
    final icuOccupied = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuOccupied) as int);
    final icuTotal = hospitals.fold<int>(0, (sum, h) => (sum + h.status.icuTotal) as int);
    final icuRate = icuTotal > 0 ? icuOccupied / icuTotal : 0;

    if (icuRate > 0.85) {
      insights.add({
        'icon': Icons.emergency,
        'color': AppColors.error,
        'title': 'ICU Critical Capacity',
        'description': 'ICU at ${(icuRate * 100).toInt()}% capacity. Prepare discharge and transfer plans.',
      });
    }

    // Positive insights
    if (systemOccupancy < 0.7 && avgWaitTime < 30) {
      insights.add({
        'icon': Icons.check_circle,
        'color': AppColors.success,
        'title': 'Optimal Performance',
        'description': 'System running efficiently with good capacity and minimal wait times.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.lightbulb_outline,
        'color': AppColors.info,
        'title': 'System Stable',
        'description': 'All metrics within normal parameters. Continue monitoring.',
      });
    }

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (insight['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: insight['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['description'] as String,
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
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}