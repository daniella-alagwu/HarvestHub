import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/static/location_data.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/app_text_field.dart';
import '../../../data/static/country_code_picker.dart';
import '../../../data/static/labeled_dropdown.dart';
import '../../../data/static/searchable_dropdown.dart';
import '../home/home_screen.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final UserRole role;

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _stateManual = TextEditingController();
  final _businessName = TextEditingController();
  final _farmLocation = TextEditingController();
  final _authRepository = AuthRepository();

  CountryInfo _phoneCountry = LocationData.defaultCountry;

  CountryInfo _addressCountry = LocationData.defaultCountry;
  String? _selectedState;

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  bool get _isFarmer => widget.role == UserRole.farmer;
  Color get _accent => _isFarmer ? AppColors.autumnRust : AppColors.mainGreen;
  Color get _accentTint =>
      _isFarmer ? AppColors.autumnRust.withOpacity(0.12) : AppColors.softGreen;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _stateManual.dispose();
    _businessName.dispose();
    _farmLocation.dispose();
    super.dispose();
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

  String get _fullPhoneNumber =>
      '${_phoneCountry.dialCode}${_phone.text.trim()}';

  String get _stateValue => _addressCountry.states.isNotEmpty
      ? (_selectedState ?? '')
      : _stateManual.text.trim();

  String get _fullAddress => '$_stateValue, ${_addressCountry.name}';

  void _onAddressCountryChanged(CountryInfo? country) {
    if (country == null) return;
    setState(() {
      _addressCountry = country;
      _selectedState = null;
      _stateManual.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('Please accept the Terms to continue.', success: false);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isFarmer) {
        await _authRepository.registerFarmer(
          fullName: _fullName.text,
          email: _email.text,
          phone: _fullPhoneNumber,
          password: _password.text,
          businessName: _businessName.text,
          marketLocation: _farmLocation.text,
        );
      } else {
        await _authRepository.registerCustomer(
          fullName: _fullName.text,
          email: _email.text,
          phone: _fullPhoneNumber,
          password: _password.text,
          address: _fullAddress,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppPageRoute(
          page: EmailVerificationScreen(
            email: _email.text.trim(),
            role: _isFarmer ? 'farmer' : 'customer',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(_authRepository.messageForError(e), success: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isSubmitting = true);
    try {
      final role = await _authRepository.signInWithGoogle(
        intendedRole: _isFarmer ? 'farmer' : 'customer',
      );
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        Navigator.of(context).pushReplacement(
          AppPageRoute(
            page: EmailVerificationScreen(email: user.email ?? '', role: role),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          AppPageRoute(page: HomeScreen(role: role)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'google-sign-in-cancelled') return;
      if (!mounted) return;
      _showSnack(_authRepository.messageForError(e), success: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(_authRepository.messageForError(e), success: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _phoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Phone Number',
            style:
                AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountryCodePicker(
                selected: _phoneCountry,
                onChanged: (country) => setState(() => _phoneCountry = country),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyRegular,
                  decoration: InputDecoration(
                    hintText: '800 000 0000',
                    hintStyle: AppTextStyles.bodyMuted,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.mainGreen, width: 1.4),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone number is required'
                      : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                const SizedBox(height: 16),
                Text(
                  _isFarmer
                      ? 'Set up your farm profile'
                      : 'Create your account',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 25),
                ),
                const SizedBox(height: 6),
                Text(
                  _isFarmer
                      ? 'List your harvest and reach customers directly.'
                      : 'Sign up to start ordering fresh produce from local farms.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 26),
                AppTextField(
                  label: 'Full Name',
                  hint: _isFarmer ? 'e.g. Musa Ibrahim' : 'e.g. Amara Chukwu',
                  controller: _fullName,
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                if (_isFarmer) ...[
                  AppTextField(
                    label: 'Farm / Business Name',
                    hint: 'e.g. Ibrahim Family Farm',
                    controller: _businessName,
                    icon: Icons.storefront_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your farm name'
                        : null,
                  ),
                  AppTextField(
                    label: 'Market / Location',
                    hint: 'Nearest farmers market or pickup area',
                    controller: _farmLocation,
                    icon: Icons.location_on_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Location is required'
                        : null,
                  ),
                ],
                AppTextField(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  controller: _email,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                _phoneField(),
                if (!_isFarmer) _addressSection(),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _password,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.wheatGold,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isFarmer
                                ? 'Create Farmer Account'
                                : 'Create Account',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                if (!_isFarmer) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: AppTextStyles.bodyMuted),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _continueWithGoogle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.textSecondary, width: 1),
                            ),
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: AppTextStyles.bodyRegular
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}