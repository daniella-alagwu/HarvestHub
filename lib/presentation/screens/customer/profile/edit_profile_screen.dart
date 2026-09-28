import 'package:flutter/material.dart';

import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/static/country_code_picker.dart';
import '../../../../data/static/labeled_dropdown.dart';
import '../../../../data/static/location_data.dart';
import '../../../../data/static/searchable_dropdown.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

/// Lets the customer edit name, phone, address and default pickup location.
/// Email is shown read-only because it is tied to the Firebase Auth account.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  static const routeName = '/customer/profile/edit';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = UserRepository();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _stateManual;
  late final TextEditingController _pickup;

  late CountryInfo _phoneCountry;
  late CountryInfo _addressCountry;
  String? _selectedState;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;

    _name = TextEditingController(text: p.name);
    _pickup = TextEditingController(text: p.pickupLocation ?? '');

    // Phone is stored as "<dial code><number>", e.g. "+2348012345678".
    _phoneCountry = _countryForPhone(p.phone) ?? LocationData.defaultCountry;
    final rawPhone = (p.phone ?? '').trim();
    _phone = TextEditingController(
      text: rawPhone.startsWith(_phoneCountry.dialCode)
          ? rawPhone.substring(_phoneCountry.dialCode.length)
          : rawPhone,
    );

    // Address is stored as "<state>, <country>".
    _addressCountry = LocationData.defaultCountry;
    _stateManual = TextEditingController();
    final address = (p.address ?? '').trim();
    final split = address.lastIndexOf(', ');
    if (split != -1) {
      final statePart = address.substring(0, split).trim();
      final countryPart = address.substring(split + 2).trim();
      _addressCountry = LocationData.countries.firstWhere(
        (c) => c.name.toLowerCase() == countryPart.toLowerCase(),
        orElse: () => LocationData.defaultCountry,
      );
      if (_addressCountry.states.contains(statePart)) {
        _selectedState = statePart;
      } else if (_addressCountry.states.isEmpty) {
        _stateManual.text = statePart;
      }
    } else if (address.isNotEmpty) {
      _stateManual.text = address;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _stateManual.dispose();
    _pickup.dispose();
    super.dispose();
  }

  /// Longest dial-code prefix wins (e.g. "+1" vs "+1242").
  CountryInfo? _countryForPhone(String? phone) {
    final value = (phone ?? '').trim();
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

  String get _stateValue => _addressCountry.states.isNotEmpty
      ? (_selectedState ?? '')
      : _stateManual.text.trim();

  String get _fullAddress => '$_stateValue, ${_addressCountry.name}';

  String get _fullPhone => '${_phoneCountry.dialCode}${_phone.text.trim()}';

  void _onAddressCountryChanged(CountryInfo? country) {
    if (country == null) return;
    setState(() {
      _addressCountry = country;
      _selectedState = null;
      _stateManual.clear();
    });
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

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _repository.updateProfile(
        name: _name.text,
        phone: _fullPhone,
        address: _fullAddress,
        pickupLocation: _pickup.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Could not save your profile. Please try again.',
          success: false);
    }
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
                    if (digits.isEmpty) return 'Phone number is required';
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

  Widget _addressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchableDropdown<CountryInfo>(
          key: ValueKey('country-${_addressCountry.iso2}'),
          label: 'Country',
          icon: Icons.public_outlined,
          value: _addressCountry,
          items: LocationData.countries,
          itemLabel: (c) => '${c.flag}  ${c.name}',
          searchHint: 'Search countries',
          onChanged: _onAddressCountryChanged,
        ),
        if (_addressCountry.states.isNotEmpty)
          LabeledDropdown<String>(
            key: ValueKey('state-${_addressCountry.iso2}'),
            label: 'State / Region',
            icon: Icons.map_outlined,
            value: _selectedState,
            hint: 'Select a state',
            items: _addressCountry.states,
            itemLabel: (s) => s,
            onChanged: (v) => setState(() => _selectedState = v),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'State is required' : null,
          )
        else
          AppTextField(
            label: 'State / Region',
            hint: 'Enter your state or region',
            controller: _stateManual,
            icon: Icons.map_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'State / Region is required'
                : null,
          ),
      ],
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
                  widget.profile.email,
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
                  _addressSection(),
                  AppTextField(
                    label: 'Preferred Pickup Location',
                    hint: 'e.g. Lekki Farmers Market',
                    controller: _pickup,
                    icon: Icons.storefront_outlined,
                  ),
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
