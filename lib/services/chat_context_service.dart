// lib/services/chat_context_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_hospital_app/services/location_service.dart';

class ChatContextService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Get hospitals with location-based distance
  Future<Map<String, dynamic>> getHospitalContext() async {
    try {
      print('📍 Fetching hospital context...');
      
      // Get user's current location
      Position? userPosition = await _locationService.getCurrentLocation();
      
      // Fetch all operational hospitals
      final hospitalsSnapshot = await _firestore
          .collection('hospitals')
          .get();

      if (hospitalsSnapshot.docs.isEmpty) {
        print('❌ No hospitals found in database');
        return {
          'hospitals': [],
          'error': 'No hospitals registered in the system yet.',
          'totalStats': {
            'totalIcu': 0,
            'totalEr': 0,
            'totalWard': 0,
          },
        };
      }

      print('✅ Found ${hospitalsSnapshot.docs.length} hospitals');

  List<Map<String, dynamic>> hospitalsList = [];
  int totalIcuAvailable = 0;
  int totalErAvailable = 0;
  int totalWardAvailable = 0;

      for (var doc in hospitalsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as Map<String, dynamic>?;
        
        if (status == null) continue;

        // Helper to normalize numeric fields which may be stored as int/double/string
        int toInt(dynamic v) {
          if (v == null) return 0;
          if (v is int) return v;
          if (v is double) return v.toInt();
          if (v is String) {
            final parsedInt = int.tryParse(v);
            if (parsedInt != null) return parsedInt;
            final parsedDouble = double.tryParse(v);
            if (parsedDouble != null) return parsedDouble.toInt();
            return 0;
          }
          if (v is num) return v.toInt();
          return 0;
        }

        final icuTotal = toInt(status['icuTotal']);
        final icuOccupied = toInt(status['icuOccupied']);
        final erTotal = toInt(status['erTotal']);
        final erOccupied = toInt(status['erOccupied']);
        final wardTotal = toInt(status['wardTotal']);
        final wardOccupied = toInt(status['wardOccupied']);

        final icuAvailable = icuTotal - icuOccupied;
        final erAvailable = erTotal - erOccupied;
        final wardAvailable = wardTotal - wardOccupied;

        totalIcuAvailable += icuAvailable;
        totalErAvailable += erAvailable;
        totalWardAvailable += wardAvailable;

        // Calculate distance if user location is available
        double? distance;
        if (userPosition != null) {
          final hospitalLat = (data['latitude'] ?? 0.0).toDouble();
          final hospitalLon = (data['longitude'] ?? 0.0).toDouble();
          
          distance = _locationService.calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            hospitalLat,
            hospitalLon,
          );
        }
        
        hospitalsList.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Hospital',
          'address': data['address'] ?? 'No address',
          'phone': data['phone'] ?? 'No phone',
          'type': data['type'] ?? 'public',
          'icuTotal': icuTotal,
          'icuOccupied': icuOccupied,
          'icuAvailable': icuAvailable,
          'erTotal': erTotal,
          'erOccupied': erOccupied,
          'erAvailable': erAvailable,
          'wardTotal': wardTotal,
          'wardOccupied': wardOccupied,
          'wardAvailable': wardAvailable,
          'waitTime': status['waitTimeMinutes'] ?? 0,
          'isOperational': status['isOperational'] ?? true,
          'distance': distance,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        });
      }

      // Sort by distance if available
      if (userPosition != null) {
        hospitalsList.sort((a, b) {
          final distA = a['distance'] ?? double.infinity;
          final distB = b['distance'] ?? double.infinity;
          return distA.compareTo(distB);
        });
        print('✅ Hospitals sorted by distance');
      }

      String? userLocation;
      if (userPosition != null) {
        userLocation = await _locationService.getAddressFromCoordinates(
          userPosition.latitude,
          userPosition.longitude,
        );
        print('📍 User location: $userLocation');
      }

      return {
        'hospitals': hospitalsList,
        'userLocation': userLocation ?? 'Location not available',
        'totalStats': {
          'totalIcu': totalIcuAvailable,
          'totalEr': totalErAvailable,
          'totalWard': totalWardAvailable,
        },
        'hasLocation': userPosition != null,
      };
    } catch (e) {
      print('❌ Error fetching hospital context: $e');
      return {
        'hospitals': [],
        'error': 'Unable to fetch hospital data: $e',
        'totalStats': {
          'totalIcu': 0,
          'totalEr': 0,
          'totalWard': 0,
        },
      };
    }
  }

  // Save chat history to Firebase
  Future<void> saveChatMessage(
    String userId,
    String message,
    String type,
  ) async {
    try {
      await _firestore
          .collection('chat_history')
          .doc(userId)
          .collection('messages')
          .add({
        'content': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  // Get chat history from Firebase
  Stream<QuerySnapshot> getChatHistory(String userId) {
    return _firestore
        .collection('chat_history')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots();
  }
}