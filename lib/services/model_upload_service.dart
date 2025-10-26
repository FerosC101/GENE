// lib/services/model_upload_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class ModelUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pick 3D model file
  Future<PlatformFile?> pick3DModelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf', 'obj', 'fbx', '3ds'],
        allowMultiple: false,
        withData: true, // ensure bytes available for web
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // Upload 3D model to Firebase Storage
  Future<String> upload3DModel(
    PlatformFile file,
    String hospitalId,
    Function(double) onProgress,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref().child('hospital_models/$hospitalId/$fileName');

      UploadTask uploadTask;
      
      if (file.bytes != null) {
        // Web upload (or when bytes are provided)
        uploadTask = ref.putData(
          file.bytes!,
          SettableMetadata(contentType: _getContentType(file.extension ?? '')),
        );
      } else {
        // No bytes available - cannot upload
        throw Exception('No file bytes available for upload. Ensure picker uses withData:true.');
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload model: $e');
    }
  }

  // Save model metadata to Firestore
  Future<void> saveModelMetadata({
    required String hospitalId,
    required String modelUrl,
    required String fileName,
    required double fileSize,
    required String uploadedBy,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('hospital_3d_models').add({
        'hospitalId': hospitalId,
        'modelUrl': modelUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': uploadedBy,
        'metadata': metadata,
      });

      // Update hospital document
      await _firestore.collection('hospitals').doc(hospitalId).update({
        'has3DModel': true,
        'model3DUrl': modelUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save model metadata: $e');
    }
  }

  // Get hospital 3D model
  Future<String?> getHospital3DModel(String hospitalId) async {
    try {
      final snapshot = await _firestore
          .collection('hospital_3d_models')
          .where('hospitalId', isEqualTo: hospitalId)
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['modelUrl'];
      }
      return null;
    } catch (e) {
      print('Error getting 3D model: $e');
      return null;
    }
  }

  // Delete 3D model
  Future<void> delete3DModel(String modelId, String modelUrl) async {
    try {
      // Delete from Storage
      final ref = _storage.refFromURL(modelUrl);
      await ref.delete();

      // Delete from Firestore
      await _firestore.collection('hospital_3d_models').doc(modelId).delete();
    } catch (e) {
      throw Exception('Failed to delete model: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'glb':
        return 'model/gltf-binary';
      case 'gltf':
        return 'model/gltf+json';
      case 'obj':
        return 'model/obj';
      case 'fbx':
        return 'application/octet-stream';
      case '3ds':
        return 'application/x-3ds';
      default:
        return 'application/octet-stream';
    }
  }
}