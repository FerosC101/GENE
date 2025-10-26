// lib/services/model_3d_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
 

class Model3DService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick 3D model file (.glb or .gltf)
  // Returns a PlatformFile which works on web and native platforms.
  Future<PlatformFile?> pickModelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf'],
        allowMultiple: false,
        withData: true, // ensure bytes are available for web and native
      );

      if (result != null && result.files.isNotEmpty) {
        final pf = result.files.single;

        // Check file size (max 10MB)
        final fileSize = pf.size;
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('File size must be less than 10MB');
        }

        return pf;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // Upload 3D model to Firebase Storage from a PlatformFile
  Future<String> uploadModel({
    required PlatformFile platformFile,
    required String hospitalId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
      final storageRef = _storage.ref().child('hospital_models/$hospitalId/$fileName');

      // Use bytes-based upload which works on web and native (we requested withData:true)
  final bytes = platformFile.bytes;
  if (bytes == null) throw Exception('File bytes are not available for upload');
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeForExtension(platformFile.name)),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (taskSnapshot.totalBytes > 0) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress?.call(progress);
        }
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload model: $e');
    }
  }
  
  // Delete 3D model from Firebase Storage
  Future<void> deleteModel(String modelUrl) async {
    try {
      final ref = _storage.refFromURL(modelUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete model: $e');
    }
  }
  
  // Validate model file format by file name
  bool isValidModelFileName(String name) {
    final extension = name.split('.').last.toLowerCase();
    return extension == 'glb' || extension == 'gltf';
  }

  // Get model file format from file name
  String getModelFormatFromName(String name) {
    return name.split('.').last.toLowerCase();
  }

  String _contentTypeForExtension(String fileName) {
    final ext = getModelFormatFromName(fileName);
    switch (ext) {
      case 'glb':
        return 'model/gltf-binary';
      case 'gltf':
        return 'model/gltf+json';
      default:
        return 'application/octet-stream';
    }
  }
}