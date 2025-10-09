// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_type.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserType userType;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;
  
  // Patient-specific fields
  final String? bloodType;
  final DateTime? dateOfBirth;
  final String? address;
  final List<String>? medicalHistory;
  final String? emergencyContact;
  
  // Doctor-specific fields
  final String? specialty;
  final String? licenseNumber;
  final String? hospitalId;
  final List<String>? qualifications;
  final int? yearsOfExperience;
  
  // Hospital Staff-specific fields
  final String? staffHospitalId;
  final String? department;
  final String? position;
  final List<String>? permissions;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.userType,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLogin,
    this.bloodType,
    this.dateOfBirth,
    this.address,
    this.medicalHistory,
    this.emergencyContact,
    this.specialty,
    this.licenseNumber,
    this.hospitalId,
    this.qualifications,
    this.yearsOfExperience,
    this.staffHospitalId,
    this.department,
    this.position,
    this.permissions,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.name == data['userType'],
        orElse: () => UserType.patient,
      ),
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      bloodType: data['bloodType'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      address: data['address'],
      medicalHistory: data['medicalHistory'] != null 
          ? List<String>.from(data['medicalHistory']) 
          : null,
      emergencyContact: data['emergencyContact'],
      specialty: data['specialty'],
      licenseNumber: data['licenseNumber'],
      hospitalId: data['hospitalId'],
      qualifications: data['qualifications'] != null 
          ? List<String>.from(data['qualifications']) 
          : null,
      yearsOfExperience: data['yearsOfExperience'],
      staffHospitalId: data['staffHospitalId'],
      department: data['department'],
      position: data['position'],
      permissions: data['permissions'] != null 
          ? List<String>.from(data['permissions']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      if (bloodType != null) 'bloodType': bloodType,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (address != null) 'address': address,
      if (medicalHistory != null) 'medicalHistory': medicalHistory,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (specialty != null) 'specialty': specialty,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (hospitalId != null) 'hospitalId': hospitalId,
      if (qualifications != null) 'qualifications': qualifications,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (staffHospitalId != null) 'staffHospitalId': staffHospitalId,
      if (department != null) 'department': department,
      if (position != null) 'position': position,
      if (permissions != null) 'permissions': permissions,
    };
  }
}