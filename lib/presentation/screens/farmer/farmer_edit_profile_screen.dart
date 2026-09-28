import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/models/farmer_account.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';
import '../../../data/static/country_code_picker.dart';
import '../../../data/static/location_data.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/primary_button.dart';

class FarmerEditProfileScreen extends StatefulWidget {
  const FarmerEditProfileScreen({super.key, required this.account});

  final FarmerAccount account;

  @override
  State<FarmerEditProfileScreen> createState() =>
      _FarmerEditProfileScreenState();
}

class _FarmerEditProfileScreenState extends State<FarmerEditProfileScreen> {
  static const _descriptionMax = 400;

  final _formKey = GlobalKey<FormState>();
  final _repo = FarmerDashboardRepository();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _farmName;
  late final TextEditingController _tagline;
  late final TextEditingController _description;
  late final TextEditingController _marketLocation;

  late CountryInfo _phoneCountry;

  Uint8List? _newAvatar;
  Uint8List? _newFarmImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;

    _name = TextEditingController(text: a.name);
    _farmName = TextEditingController(text: a.farmName);
    _tagline = TextEditingController(text: a.tagline);
    _description = TextEditingController(text: a.description);
    _marketLocation = TextEditingController(text: a.marketLocation);

    _phoneCountry = _countryForPhone(a.phone) ?? LocationData.defaultCountry;
    final rawPhone = a.phone.trim();
    _phone = TextEditingController(
      text: rawPhone.startsWith(_phoneCountry.dialCode)
          ? rawPhone.substring(_phoneCountry.dialCode.length)
          : rawPhone,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _farmName.dispose();
    _tagline.dispose();
    _description.dispose();
    _marketLocation.dispose();
    super.dispose();
  }

  CountryInfo? _countryForPhone(String phone) {
    final value = phone.trim();
    if (!value.startsWith('+')) return null;
    CountryInfo? best;
    for (final c in LocationData.countries) {
      if (value.startsWith(c.dialCode) &&
          (best == null || c.dialCode.length > best.dialCode.length)) {
        best = c;
      }
    }
    return best;
  }

  String get _fullPhone {
    final digits = _phone.text.replaceAll(RegExp(r'[\s-]'), '');
    return digits.isEmpty ? '' : '${_phoneCountry.dialCode}$digits';
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final bytes = await pickImageBytes(
        context,
        title: widget.account.hasAvatar
            ? 'Change profile picture'
            : 'Add a profile picture',
        maxSize: 800,
      );
      if (bytes != null && mounted) setState(() => _newAvatar = bytes);
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open that image.', success: false);
      }
    }
  }

  Future<void> _pickFarmImage() async {
    try {
      final bytes = await pickImageBytes(
        context,
        title: widget.account.hasFarmImage
            ? 'Change farm photo'
            : 'Add a farm photo',
        maxSize: 1600,
      );
      if (bytes != null && mounted) setState(() => _newFarmImage = bytes);
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open that image.', success: false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _repo.updateFarmerProfile(
        uid: widget.account.uid,
        name: _name.text,
        phone: _fullPhone,
        farmName: _farmName.text,
        marketLocation: _marketLocation.text,
        description: _description.text,
        tagline: _tagline.text,
        newAvatarBytes: _newAvatar,
        newFarmImageBytes: _newFarmImage,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final text = e.toString().replaceFirst('Exception: ', '');
      final isUpload = text.toLowerCase().contains('image upload');
      _showSnack(
        isUpload ? text : 'Could not save your profile. Please try again.',
        success: false,
      );
    }
  }

  Widget _avatarPicker() {
    final a = widget.account;
    ImageProvider? image;
    if (_newAvatar != null) {
      image = MemoryImage(_newAvatar!);
    } else if (a.hasAvatar) {
      image = NetworkImage(a.avatarUrl);
    } else {
      image = null;
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wheatGold, width: 3),
                    image: image == null
                        ? null
                        : DecorationImage(image: image, fit: BoxFit.cover),
                  ),
                  child: image == null
                      ? Icon(Icons.person_outline_rounded,
                          size: 44,
                          color: AppColors.deepGreen.withValues(alpha: 0.7))
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.mainGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            image == null ? 'Add profile picture' : 'Tap to change picture',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }

  Widget _farmImagePicker() {
    final a = widget.account;
    ImageProvider? image;
    if (_newFarmImage != null) {
      image = MemoryImage(_newFarmImage!);
    } else if (a.hasFarmImage) {
      image = NetworkImage(a.farmImageUrl);
    } else {
      image = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm photo',
            style:
                AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isSaving ? null : _pickFarmImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.softGreen.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 30, color: AppColors.mainGreen),
                        const SizedBox(height: 8),
                        Text('Add a photo of your farm',
                            style: AppTextStyles.bodyRegular
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Shown to customers on your farm page',
                            style: AppTextStyles.caption),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Change',
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Text(text, style: AppTextStyles.headingMedium),
    );
  }

  InputDecoration _phoneDecoration() {
    return InputDecoration(
      hintText: '800 000 0000',
      hintStyle: AppTextStyles.bodyMuted,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.mainGreen, width: 1.5),
      ),
    );
  }

  Widget _phoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style:
                AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountryCodePicker(
                selected: _phoneCountry,
                onChanged: (c) => setState(() => _phoneCountry = c),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyRegular,
                  decoration: _phoneDecoration(),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                    if (digits.isEmpty) return null; // optional
                    if (!RegExp(r'^\d{6,15}$').hasMatch(digits)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readOnlyEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style:
              AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_outline,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.account.email,
                  style: AppTextStyles.bodyRegular
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('Your email is tied to your sign-in and can\'t be changed here.',
            style: AppTextStyles.caption),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatarPicker(),
                  const SizedBox(height: 24),
                  _sectionLabel('Your farm'),
                  _farmImagePicker(),
                  AppTextField(
                    label: 'Farm Name',
                    hint: 'e.g. Green Valley Farms',
                    controller: _farmName,
                    icon: Icons.agriculture_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your farm name'
                        : null,
                  ),
                  AppTextField(
                    label: 'Tagline (optional)',
                    hint: 'A short line about what you grow',
                    controller: _tagline,
                    icon: Icons.short_text_rounded,
                  ),
                  AppTextField(
                    label: 'Farm Description',
                    hint:
                        'Tell customers about your farm, produce, and values.',
                    controller: _description,
                    icon: Icons.notes_rounded,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Please describe your farm';
                      if (t.length > _descriptionMax) {
                        return 'Keep it under $_descriptionMax characters';
                      }
                      return null;
                    },
                  ),
                  AppTextField(
                    label: 'Market / Pickup Location',
                    hint: 'Nearest farmers market or pickup area',
                    controller: _marketLocation,
                    icon: Icons.storefront_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a pickup location'
                        : null,
                  ),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  _sectionLabel('Personal details'),
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Your full name',
                    controller: _name,
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),
                  _readOnlyEmail(),
                  _phoneField(),
                  const SizedBox(height: 4),
                  PrimaryButton(
                    label: 'Save changes',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
