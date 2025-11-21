import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/wardrobe/wardrobe_bloc.dart';
import '../../bloc/wardrobe/wardrobe_event.dart';
import '../../bloc/wardrobe/wardrobe_state.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  String _selectedCategory = AppConstants.clothingCategories[0];
  String? _selectedSubcategory;
  String _selectedColor = AppConstants.clothingColors[0];
  String _selectedPattern = AppConstants.patterns[0];
  String _selectedSeason = AppConstants.seasons[0];
  final List<String> _selectedOccasions = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });

        // Analyze image with AI
        if (mounted) {
          final wardrobeBloc = context.read<WardrobeBloc>();
          wardrobeBloc.add(AnalyzeImage(_imageFile!));

          // Listen for analysis result
          await for (final state in wardrobeBloc.stream) {
            if (state is ImageAnalyzed) {
              final analysis = state.result;
              setState(() {
                _selectedCategory = analysis.category;
                _selectedSubcategory = analysis.subcategory;
                if (analysis.colors.isNotEmpty) {
                  _selectedColor = analysis.colors.first;
                }
                _selectedPattern = analysis.pattern;
                _selectedOccasions.addAll(analysis.occasions);
              });
              break;
            } else if (state is WardrobeError) {
              break;
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      final authCubit = context.read<AuthCubit>();
      final wardrobeBloc = context.read<WardrobeBloc>();

      final user = authCubit.currentUser;
      if (user == null) return;

      wardrobeBloc.add(AddClothingItem(
        userId: user.id,
        imageFile: _imageFile!,
        category: _selectedCategory,
        subcategory: _selectedSubcategory ?? '',
        color: _selectedColor,
        pattern: _selectedPattern,
        season: _selectedSeason,
        occasionTags: _selectedOccasions,
      ));

      if (!mounted) return;

      // Listen for result
      await for (final state in wardrobeBloc.stream) {
        if (state is ClothingItemAdded) {
          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item added successfully!')),
            );
          }
          break;
        } else if (state is WardrobeError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = AppConstants.subcategoriesMap[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clothing Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.clothingCategories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _selectedSubcategory = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Subcategory
              if (subcategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: subcategories.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _imageFile == null ? null : _saveItem,
                child: const Text('Add to Wardrobe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
