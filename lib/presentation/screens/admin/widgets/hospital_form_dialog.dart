// lib/presentation/screens/admin/widgets/hospital_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/hospital_model.dart';
import 'package:smart_hospital_app/services/model_3d_service.dart';
import 'package:file_picker/file_picker.dart';

class HospitalFormDialog extends ConsumerStatefulWidget {
  final HospitalModel? hospital;

  const HospitalFormDialog({
    super.key,
    this.hospital,
  });

  @override
  ConsumerState<HospitalFormDialog> createState() => _HospitalFormDialogState();
}

class _HospitalFormDialogState extends ConsumerState<HospitalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Model3DService _model3DService = Model3DService();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _longController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _imageUrlController;
  late TextEditingController _icuTotalController;
  late TextEditingController _erTotalController;
  late TextEditingController _wardTotalController;
  late TextEditingController _floorsController;
  
  String _selectedType = 'public';
  List<String> _selectedServices = [];
  List<String> _selectedSpecialties = [];
  
  // 3D Model Upload State
  PlatformFile? _selected3DModel;
  String? _selectedModelFileName;
  bool _isUploadingModel = false;
  double _uploadProgress = 0.0;
  
  final List<String> _hospitalTypes = ['public', 'private', 'specialty'];
  final List<String> _availableServices = [
    'Emergency',
    'ICU',
    'Surgery',
    'Pharmacy',
    'Laboratory',
    'Radiology',
    'Outpatient',
    'Inpatient',
  ];
  final List<String> _availableSpecialties = [
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Oncology',
    'General Surgery',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hospital?.name ?? '');
    _addressController = TextEditingController(text: widget.hospital?.address ?? '');
    _latController = TextEditingController(text: widget.hospital?.latitude.toString() ?? '');
    _longController = TextEditingController(text: widget.hospital?.longitude.toString() ?? '');
    _phoneController = TextEditingController(text: widget.hospital?.phone ?? '');
    _emailController = TextEditingController(text: widget.hospital?.email ?? '');
    _imageUrlController = TextEditingController(text: widget.hospital?.imageUrl ?? '');
    
    _icuTotalController = TextEditingController(
      text: widget.hospital?.status.icuTotal.toString() ?? '20'
    );
    _erTotalController = TextEditingController(
      text: widget.hospital?.status.erTotal.toString() ?? '15'
    );
    _wardTotalController = TextEditingController(
      text: widget.hospital?.status.wardTotal.toString() ?? '100'
    );
    _floorsController = TextEditingController(
      text: widget.hospital?.modelMetadata?.floors.toString() ?? '3'
    );
    
    if (widget.hospital != null) {
      _selectedType = widget.hospital!.type;
      _selectedServices = List.from(widget.hospital!.services);
      _selectedSpecialties = List.from(widget.hospital!.specialties);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _longController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _icuTotalController.dispose();
    _erTotalController.dispose();
    _wardTotalController.dispose();
    _floorsController.dispose();
    super.dispose();
  }

  Future<void> _pick3DModel() async {
    try {
      final pf = await _model3DService.pickModelFile();
      if (pf != null) {
        setState(() {
          _selected3DModel = pf;
          _selectedModelFileName = pf.name;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: $_selectedModelFileName'),
              backgroundColor: AppColors.success,
            ),
          );
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
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Return hospital data + 3D model file
      Navigator.pop(context, {
        'hospitalData': {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_longController.text) ?? 0.0,
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'type': _selectedType,
          'services': _selectedServices,
          'specialties': _selectedSpecialties,
          'imageUrl': _imageUrlController.text.trim(),
          'status': {
            'icuTotal': int.tryParse(_icuTotalController.text) ?? 0,
            'icuOccupied': widget.hospital?.status.icuOccupied ?? 0,
            'erTotal': int.tryParse(_erTotalController.text) ?? 0,
            'erOccupied': widget.hospital?.status.erOccupied ?? 0,
            'wardTotal': int.tryParse(_wardTotalController.text) ?? 0,
            'wardOccupied': widget.hospital?.status.wardOccupied ?? 0,
            'waitTimeMinutes': widget.hospital?.status.waitTimeMinutes ?? 15,
            'isOperational': widget.hospital?.status.isOperational ?? true,
          },
        },
        'model3DFile': _selected3DModel,
        'floors': int.tryParse(_floorsController.text) ?? 3,
        'existingModelUrl': widget.hospital?.model3dUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.hospital == null ? 'Add Hospital' : 'Edit Hospital',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Name',
                          prefixIcon: Icon(Icons.local_hospital),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter hospital name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.map),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.map),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _hospitalTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          prefixIcon: Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Bed Capacity
                      const Text(
                        'Bed Capacity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _icuTotalController,
                              decoration: const InputDecoration(
                                labelText: 'ICU Beds',
                                prefixIcon: Icon(Icons.bed),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _erTotalController,
                              decoration: const InputDecoration(
                                labelText: 'ER Beds',
                                prefixIcon: Icon(Icons.bed),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _wardTotalController,
                              decoration: const InputDecoration(
                                labelText: 'Ward Beds',
                                prefixIcon: Icon(Icons.bed),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 3D Model Upload Section (OPTIONAL)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '3D Building Model',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Optional - Can be added later',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'OPTIONAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload a 3D model (.glb or .gltf format, max 10MB)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Show existing model status
                            if (widget.hospital?.has3dModel == true && _selected3DModel == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '3D Model Already Uploaded',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (widget.hospital?.modelMetadata != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${widget.hospital!.modelMetadata!.floors} floors • ${widget.hospital!.modelMetadata!.fileSizeFormatted}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Show selected new file
                            if (_selected3DModel != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: AppColors.info,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedModelFileName ?? 'Unknown file',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(_selected3DModel!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _selected3DModel = null;
                                          _selectedModelFileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Floor count (only required if 3D model is selected)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _floorsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Number of Floors',
                                      prefixIcon: Icon(Icons.layers),
                                      hintText: '3',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_selected3DModel != null || widget.hospital?.has3dModel == true) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required when 3D model is present';
                                        }
                                        final floors = int.tryParse(value);
                                        if (floors == null || floors < 1 || floors > 20) {
                                          return 'Enter 1-20 floors';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isUploadingModel ? null : _pick3DModel,
                                    icon: const Icon(Icons.upload_file),
                                    label: Text(
                                      _selected3DModel == null 
                                          ? (widget.hospital?.has3dModel == true ? 'Replace Model' : 'Select Model')
                                          : 'Change Model'
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_isUploadingModel) ...[
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: _uploadProgress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Services
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableServices.map((service) {
                          final isSelected = _selectedServices.contains(service);
                          return FilterChip(
                            label: Text(service),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(service);
                                } else {
                                  _selectedServices.remove(service);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Specialties
                      const Text(
                        'Specialties',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSpecialties.map((specialty) {
                          final isSelected = _selectedSpecialties.contains(specialty);
                          return FilterChip(
                            label: Text(specialty),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSpecialties.add(specialty);
                                } else {
                                  _selectedSpecialties.remove(specialty);
                                }
                              });
                            },
                            selectedColor: AppColors.info.withOpacity(0.2),
                            checkmarkColor: AppColors.info,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isUploadingModel ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploadingModel ? null : _handleSave,
                    child: Text(widget.hospital == null ? 'Add Hospital' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}