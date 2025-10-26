// lib/data/models/simulation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SimulationScenario {
  normalOperation,
  massEmergency,
  pandemicOutbreak,
  naturalDisaster,
  peakHours,
  lowStaffing;

  String get displayName {
    switch (this) {
      case SimulationScenario.normalOperation:
        return 'Normal Operation';
      case SimulationScenario.massEmergency:
        return 'Mass Emergency';
      case SimulationScenario.pandemicOutbreak:
        return 'Pandemic Outbreak';
      case SimulationScenario.naturalDisaster:
        return 'Natural Disaster';
      case SimulationScenario.peakHours:
        return 'Peak Hours';
      case SimulationScenario.lowStaffing:
        return 'Low Staffing';
    }
  }

  String get description {
    switch (this) {
      case SimulationScenario.normalOperation:
        return 'Regular daily operations with typical patient flow';
      case SimulationScenario.massEmergency:
        return 'Large-scale emergency with 50+ critical patients';
      case SimulationScenario.pandemicOutbreak:
        return 'Infectious disease outbreak requiring isolation';
      case SimulationScenario.naturalDisaster:
        return 'Earthquake, typhoon, or major disaster response';
      case SimulationScenario.peakHours:
        return 'Rush hour with maximum patient admissions';
      case SimulationScenario.lowStaffing:
        return 'Limited staff availability scenario';
    }
  }

  Map<String, dynamic> get parameters {
    switch (this) {
      case SimulationScenario.normalOperation:
        return {
          'patientInflux': 10,
          'icuDemand': 15,
          'erDemand': 20,
          'wardDemand': 30,
          'staffAvailability': 100,
        };
      case SimulationScenario.massEmergency:
        return {
          'patientInflux': 50,
          'icuDemand': 80,
          'erDemand': 90,
          'wardDemand': 60,
          'staffAvailability': 100,
        };
      case SimulationScenario.pandemicOutbreak:
        return {
          'patientInflux': 40,
          'icuDemand': 70,
          'erDemand': 60,
          'wardDemand': 85,
          'staffAvailability': 80,
        };
      case SimulationScenario.naturalDisaster:
        return {
          'patientInflux': 60,
          'icuDemand': 75,
          'erDemand': 95,
          'wardDemand': 70,
          'staffAvailability': 90,
        };
      case SimulationScenario.peakHours:
        return {
          'patientInflux': 35,
          'icuDemand': 40,
          'erDemand': 55,
          'wardDemand': 45,
          'staffAvailability': 100,
        };
      case SimulationScenario.lowStaffing:
        return {
          'patientInflux': 20,
          'icuDemand': 30,
          'erDemand': 35,
          'wardDemand': 40,
          'staffAvailability': 60,
        };
    }
  }
}

class SimulationResult {
  final String id;
  final String hospitalId;
  final SimulationScenario scenario;
  final Map<String, dynamic> inputParameters;
  final Map<String, dynamic> results;
  final DateTime timestamp;
  final int duration; // in minutes

  SimulationResult({
    required this.id,
    required this.hospitalId,
    required this.scenario,
    required this.inputParameters,
    required this.results,
    required this.timestamp,
    required this.duration,
  });

  factory SimulationResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SimulationResult(
      id: doc.id,
      hospitalId: data['hospitalId'] ?? '',
      scenario: SimulationScenario.values.firstWhere(
        (e) => e.name == data['scenario'],
        orElse: () => SimulationScenario.normalOperation,
      ),
      inputParameters: Map<String, dynamic>.from(data['inputParameters'] ?? {}),
      results: Map<String, dynamic>.from(data['results'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      duration: data['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'scenario': scenario.name,
      'inputParameters': inputParameters,
      'results': results,
      'timestamp': Timestamp.fromDate(timestamp),
      'duration': duration,
    };
  }
}

class Hospital3DModel {
  final String id;
  final String hospitalId;
  final String modelUrl;
  final String fileName;
  final double fileSize; // in MB
  final DateTime uploadedAt;
  final String uploadedBy;
  final Map<String, dynamic>? metadata;

  Hospital3DModel({
    required this.id,
    required this.hospitalId,
    required this.modelUrl,
    required this.fileName,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
    this.metadata,
  });

  factory Hospital3DModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hospital3DModel(
      id: doc.id,
      hospitalId: data['hospitalId'] ?? '',
      modelUrl: data['modelUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileSize: (data['fileSize'] ?? 0.0).toDouble(),
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospitalId': hospitalId,
      'modelUrl': modelUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadedAt': FieldValue.serverTimestamp(),
      'uploadedBy': uploadedBy,
      'metadata': metadata,
    };
  }
}