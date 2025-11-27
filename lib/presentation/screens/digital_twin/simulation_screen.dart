// lib/presentation/screens/digital_twin/simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/hospital_model.dart';
import 'package:pulse/services/gemini_ai_service.dart';

enum SimulationScenario {
  patientSurge,
  massCasualty,
  equipmentFailure,
  staffShortage,
}

// Gemini AI Service Provider
final geminiServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

class SimulationScreen extends ConsumerStatefulWidget {
  final HospitalModel hospital;

  const SimulationScreen({
    super.key,
    required this.hospital,
  });

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  SimulationScenario _selectedScenario = SimulationScenario.patientSurge;
  int _additionalPatients = 50;
  int _timeHours = 2;
  bool _isSimulating = false;
  Map<String, dynamic>? _simulationResults;

  final Map<SimulationScenario, String> _scenarioNames = {
    SimulationScenario.patientSurge: 'Patient Surge',
    SimulationScenario.massCasualty: 'Mass Casualty',
    SimulationScenario.equipmentFailure: 'Equipment Failure',
    SimulationScenario.staffShortage: 'Staff Shortage',
  };

  final Map<SimulationScenario, IconData> _scenarioIcons = {
    SimulationScenario.patientSurge: Icons.trending_up,
    SimulationScenario.massCasualty: Icons.local_hospital,
    SimulationScenario.equipmentFailure: Icons.build,
    SimulationScenario.staffShortage: Icons.people_outline,
  };

  Future<void> _runSimulation() async {
    setState(() {
      _isSimulating = true;
      _simulationResults = null;
    });

    try {
      // Simulate calculation delay
      await Future.delayed(const Duration(seconds: 2));

      // Calculate impact
      final results = _calculateImpact();
      
      // Get AI recommendations
      final recommendations = await _getAIRecommendations(results);
      
      setState(() {
        _simulationResults = {
          ...results,
          'recommendations': recommendations,
        };
        _isSimulating = false;
      });
    } catch (e) {
      setState(() {
        _isSimulating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateImpact() {
    final currentOccupancy = widget.hospital.status.totalOccupied;
    final totalBeds = widget.hospital.status.totalBeds;
    
    // Calculate new occupancy
    int newOccupancy = currentOccupancy;
    
    switch (_selectedScenario) {
      case SimulationScenario.patientSurge:
        newOccupancy = currentOccupancy + _additionalPatients;
        break;
      case SimulationScenario.massCasualty:
        newOccupancy = currentOccupancy + (_additionalPatients * 1.5).toInt();
        break;
      case SimulationScenario.equipmentFailure:
      case SimulationScenario.staffShortage:
        newOccupancy = currentOccupancy;
        break;
    }
    
    final currentCapacity = (currentOccupancy / totalBeds * 100).toInt();
    final newCapacity = (newOccupancy / totalBeds * 100).toInt();
    
    // Calculate wait time increase
    final currentWait = widget.hospital.status.waitTimeMinutes;
    final waitTimeIncrease = (newCapacity - currentCapacity) * 0.5;
    final newWaitTime = (currentWait + waitTimeIncrease).toInt();
    
    // Calculate staff needed
    final staffPerPatient = 0.15;
    final additionalStaffNeeded = (_additionalPatients * staffPerPatient).toInt();
    
    // Department breakdown
    final icuImpact = _calculateDepartmentImpact(
      widget.hospital.status.icuOccupied,
      widget.hospital.status.icuTotal,
      (_additionalPatients * 0.2).toInt(),
    );
    
    final erImpact = _calculateDepartmentImpact(
      widget.hospital.status.erOccupied,
      widget.hospital.status.erTotal,
      (_additionalPatients * 0.3).toInt(),
    );
    
    final wardImpact = _calculateDepartmentImpact(
      widget.hospital.status.wardOccupied,
      widget.hospital.status.wardTotal,
      (_additionalPatients * 0.5).toInt(),
    );
    
    return {
      'currentCapacity': currentCapacity,
      'newCapacity': newCapacity,
      'currentWaitTime': currentWait,
      'newWaitTime': newWaitTime,
      'additionalStaffNeeded': additionalStaffNeeded,
      'icuImpact': icuImpact,
      'erImpact': erImpact,
      'wardImpact': wardImpact,
      'isOverCapacity': newCapacity > 100,
      'capacityDiff': newCapacity - currentCapacity,
    };
  }

  Map<String, dynamic> _calculateDepartmentImpact(
    int occupied,
    int total,
    int additional,
  ) {
    final currentPercent = (occupied / total * 100).toInt();
    final newOccupied = occupied + additional;
    final newPercent = (newOccupied / total * 100).toInt();
    
    return {
      'currentOccupied': occupied,
      'newOccupied': newOccupied,
      'total': total,
      'currentPercent': currentPercent,
      'newPercent': newPercent,
      'isOverCapacity': newOccupied > total,
      'overflow': newOccupied > total ? newOccupied - total : 0,
    };
  }

  Future<List<String>> _getAIRecommendations(Map<String, dynamic> results) async {
    final geminiService = ref.read(geminiServiceProvider);
    
    final prompt = '''
You are a hospital operations expert. Based on this simulation:

Hospital: ${widget.hospital.name}
Scenario: ${_scenarioNames[_selectedScenario]}
Additional Patients: $_additionalPatients
Time Frame: $_timeHours hours

Current Status:
- Total Capacity: ${results['currentCapacity']}%
- ICU: ${results['icuImpact']['currentPercent']}%
- ER: ${results['erImpact']['currentPercent']}%
- Ward: ${results['wardImpact']['currentPercent']}%

Projected Impact:
- New Capacity: ${results['newCapacity']}%
- ICU: ${results['icuImpact']['newPercent']}%
- ER: ${results['erImpact']['newPercent']}%
- Ward: ${results['wardImpact']['newPercent']}%
- Additional Staff Needed: ${results['additionalStaffNeeded']}
- Wait Time: ${results['currentWaitTime']}min → ${results['newWaitTime']}min

Provide exactly 4 actionable recommendations to handle this situation. Each recommendation should be one concise sentence. Format as a simple list without numbers or bullets.
''';

    try {
      final response = await geminiService.sendMessage(prompt);
      final recommendations = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(4)
          .toList();
      
      return recommendations.isNotEmpty
          ? recommendations
          : [
              'Activate emergency response protocol',
              'Call in additional staff members',
              'Prepare overflow areas for patients',
              'Coordinate with nearby hospitals',
            ];
    } catch (e) {
      return [
        'Activate emergency response protocol',
        'Call in additional staff members',
        'Prepare overflow areas for patients',
        'Coordinate with nearby hospitals',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If Simulation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scenario Selection
            const Text(
              'Select Scenario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SimulationScenario.values.map((scenario) {
                final isSelected = scenario == _selectedScenario;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedScenario = scenario;
                      _simulationResults = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _scenarioIcons[scenario],
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _scenarioNames[scenario]!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            // Parameters
            const Text(
              'Parameters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Additional Patients',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '+$_additionalPatients',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _additionalPatients.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '+$_additionalPatients patients',
                    onChanged: (value) {
                      setState(() {
                        _additionalPatients = value.toInt();
                        _simulationResults = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Time Frame',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_timeHours hours',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _timeHours.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: '$_timeHours hours',
                    onChanged: (value) {
                      setState(() {
                        _timeHours = value.toInt();
                        _simulationResults = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Run Simulation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSimulating ? null : _runSimulation,
                icon: _isSimulating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isSimulating ? 'Simulating...' : 'Run Simulation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // Results section will continue...
            if (_simulationResults != null) ..._buildResults(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults() {
    return [
      const SizedBox(height: 32),
      const Text(
        'Impact Analysis',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      
      // Overall Capacity Card
      _buildImpactCard(
        'Overall Capacity',
        Icons.donut_large,
        _simulationResults!['isOverCapacity']
            ? AppColors.error
            : AppColors.warning,
        [
          _ImpactItem(
            label: 'Current',
            value: '${_simulationResults!['currentCapacity']}%',
          ),
          _ImpactItem(
            label: 'Projected',
            value: '${_simulationResults!['newCapacity']}%',
            highlighted: true,
          ),
          _ImpactItem(
            label: 'Change',
            value: '+${_simulationResults!['capacityDiff']}%',
            isWarning: _simulationResults!['isOverCapacity'],
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Department Cards
      Row(
        children: [
          Expanded(
            child: _buildDepartmentCard('ICU', AppColors.error, _simulationResults!['icuImpact']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDepartmentCard('ER', AppColors.warning, _simulationResults!['erImpact']),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildDepartmentCard('Ward', AppColors.info, _simulationResults!['wardImpact']),
      const SizedBox(height: 16),
      
      // Wait Time & Staff
      Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              Icons.schedule,
              'Wait Time',
              '${_simulationResults!['currentWaitTime']}min',
              '${_simulationResults!['newWaitTime']}min',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              Icons.people,
              'Staff Needed',
              'Current',
              '+${_simulationResults!['additionalStaffNeeded']}',
              AppColors.info,
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      
      // AI Recommendations
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primaryLight.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_simulationResults!['recommendations'] as List<String>)
                .asMap()
                .entries
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: 24),
      
      // Action Buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _simulationResults = null;
                });
              },
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulation saved for review'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save Results'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildImpactCard(String title, IconData icon, Color color, List<_ImpactItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(String department, Color color, Map<String, dynamic> impact) {
    final isOverCapacity = impact['isOverCapacity'] as bool;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverCapacity ? AppColors.error : color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                department,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOverCapacity) ...[
                const Spacer(),
                const Icon(
                  Icons.warning,
                  color: AppColors.error,
                  size: 18,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${impact['currentPercent']}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey[400],
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${impact['newPercent']}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOverCapacity ? AppColors.error : color,
                    ),
                  ),
                  const Text(
                    'Projected',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isOverCapacity) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Overflow: ${impact['overflow']} patients',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String before, String after, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            before,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.arrow_downward,
            color: Colors.grey[400],
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            after,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;
  final bool isWarning;

  const _ImpactItem({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: highlighted ? 24 : 18,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w600,
            color: isWarning ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}