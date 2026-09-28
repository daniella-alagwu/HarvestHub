import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';

const List<String> _productCategories = [
  'Vegetables',
  'Fruits',
  'Bakery',
  'Dairy',
  'Tubers & Roots',
  'Grains & Cereals',
  'Oil & Oilseeds',
  'Spices',
  'Legumes & Pulses',
];
const List<String> _productUnits = [
  'kg',
  'g',
  'litre',
  'ml',
  'piece',
  'dozen',
  'bunch',
  'pack',
  'crate',
];


class FarmerAddProductScreen extends StatefulWidget {
  const FarmerAddProductScreen({super.key, this.existingProduct});

  final ProductModel? existingProduct;

  @override
  State<FarmerAddProductScreen> createState() => _FarmerAddProductScreenState();
}

class _FarmerAddProductScreenState extends State<FarmerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  final _repo = FarmerDashboardRepository();
  final _picker = ImagePicker();

  Uint8List? _newImageBytes;
  String? _selectedCategory;
  String _selectedUnit = 'kg';
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameController = TextEditingController(text: p?.itemName ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.pricePerUnit.toString() : '');
    _stockController =
        TextEditingController(text: p != null ? p.stockQty.toString() : '');
    _selectedCategory = p?.category ?? _productCategories.first;
    _selectedUnit = p?.unit ?? 'kg';
    if (!_productUnits.contains(_selectedUnit)) _selectedUnit = 'kg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _newImageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final category = _selectedCategory?.trim();
    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a product category.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        await _repo.updateProduct(
          productId: widget.existingProduct!.productId,
          farmerId: uid,
          itemName: _nameController.text.trim(),
          category: category,
          unit: _selectedUnit,
          description: _descriptionController.text.trim(),
          pricePerUnit: double.parse(_priceController.text.trim()),
          stockQty: int.parse(_stockController.text.trim()),
          newImageBytes: _newImageBytes,
          existingImageUrl: widget.existingProduct!.imageUrl,
        );
      } else {
        await _repo.addProduct(
          farmerId: uid,
          itemName: _nameController.text.trim(),
          category: category,
          unit: _selectedUnit,
          description: _descriptionController.text.trim(),
          pricePerUnit: double.parse(_priceController.text.trim()),
          stockQty: int.parse(_stockController.text.trim()),
          imageBytes: _newImageBytes,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save product: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.existingProduct?.imageUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEditing ? 'Edit product' : 'Add product',
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(12),
                      image: _newImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_newImageBytes!),
                              fit: BoxFit.cover)
                          : (existingImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(existingImageUrl),
                                  fit: BoxFit.cover)
                              : null),
                    ),
                    child: (_newImageBytes == null && existingImageUrl.isEmpty)
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.deepGreen, size: 28),
                              SizedBox(height: 8),
                              Text('Tap to add a photo',
                                  style: TextStyle(
                                      color: AppColors.deepGreen,
                                      fontSize: 13)),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel('Product name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('e.g. Heirloom Tomatoes'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Category'),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration('Select a category'),
                  items: _productCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Category is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Product unit'),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: _inputDecoration('Select a unit'),
                  items: _productUnits
                      .map((unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedUnit = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration:
                      _inputDecoration('Short description of the product'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Price per unit (₦)'),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('e.g. 4800'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Price is required';
                    if (double.tryParse(v.trim()) == null)
                      return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Quantity in stock'),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('e.g. 20'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Stock quantity is required';
                    if (int.tryParse(v.trim()) == null)
                      return 'Enter a whole number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Add product',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mainGreen, width: 1.4)),
    );
  }
}
