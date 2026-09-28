
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../application/orders/order_provider.dart';
import '../../../../application/wishlist/wishlist_provider.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/app_page_route.dart';
import '../../splash/splash_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'edit_profile_screen.dart';

const _supportEmail = 'support@harvesthub.app';
const _supportPhone = '+234 800 000 0000';
const _appVersion = '1.0.0';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    this.onOpenOrders,
    this.onBackToHome,
  });

  final VoidCallback? onOpenOrders;
  final VoidCallback? onBackToHome;

  static const routeName = '/customer/profile';

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _userRepository = UserRepository();

  late final Stream<UserProfile?> _profileStream =
      _userRepository.watchCurrentUserProfile();

  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;

  String? _profilePhotoUrl;

  void _showSnack(
    String message, {
    required bool success,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _memberSince(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _valueOrNotSet(String? value) {
    return (value == null || value.trim().isEmpty)
        ? 'Not set'
        : value.trim();
  }

  // ─────────────────────────────────────────────
  // PROFILE PICTURE
  // ─────────────────────────────────────────────

  Future<void> _changeProfilePicture() async {
    if (_isUploadingPhoto) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Change profile picture',
                  style: AppTextStyles.headingMedium,
                ),

                const SizedBox(height: 12),

                Text(
                  'Choose how you want to add your picture.',
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.mainGreen,
                    ),
                  ),
                  title: const Text('Take a photo'),
                  subtitle: const Text('Use your camera'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                ),

                const SizedBox(height: 6),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.mainGreen,
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Select a picture from your device'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      final url = await _userRepository.uploadProfilePicture(
        File(image.path),
      );

      if (!mounted) return;

      setState(() {
        _profilePhotoUrl = url;
        _isUploadingPhoto = false;
      });

      _showSnack(
        'Profile picture updated',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _showSnack(
        'Could not update profile picture.',
        success: false,
      );
    }
  }

  // ─────────────────────────────────────────────
  // EDIT PROFILE
  // ─────────────────────────────────────────────

  Future<void> _editProfile(UserProfile profile) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
        ),
      ),
    );

    if (saved == true && mounted) {
      _showSnack(
        'Profile updated',
        success: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // CHANGE PASSWORD
  // ─────────────────────────────────────────────

  Future<void> _changePassword(String email) async {
    if (email.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Text(
          'We\'ll send a password reset link to $email.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = AuthRepository();

    try {
      await auth.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showSnack(
        'Reset link sent. Check your inbox.',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        auth.messageForResetError(e),
        success: false,
      );
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────

  Future<void> _logout() async {
    if (_isSigningOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You\'ll need to sign in again to continue shopping.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await AuthRepository().signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(
          page: const SplashScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSigningOut = false;
      });

      _showSnack(
        'Could not log out. Please try again.',
        success: false,
      );
    }
  }

  // ─────────────────────────────────────────────
  // ABOUT
  // ─────────────────────────────────────────────

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: AppColors.mainGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About HarvestHub',
                    style: AppTextStyles.headingMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'HarvestHub is a marketplace that connects you directly with '
                'local farmers. Browse fresh produce, place a pickup order and '
                'collect it at your chosen farmers market. No middlemen, just '
                'fresher food and fairer prices for the people who grow it.',
                style: AppTextStyles.bodyRegular.copyWith(
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Version $_appVersion',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CONTACT
  // ─────────────────────────────────────────────

  void _showContact() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact us',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Questions about an order or your account? Reach out.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
              _ContactRow(
                icon: Icons.mail_outline,
                label: 'Email',
                value: _supportEmail,
              ),
              const SizedBox(height: 12),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: _supportPhone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: widget.onBackToHome,
        ),
        title: const Text('Profile'),
      ),

      body: StreamBuilder<UserProfile?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.mainGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'We couldn\'t load your profile. '
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            );
          }

          final profile = snapshot.data ??
              UserProfile(
                uid: authUser?.uid ?? '',
                name: authUser?.displayName ?? '',
                email: authUser?.email ?? '',
                role: 'customer',
              );

          final displayName = profile.name.trim().isEmpty
              ? 'HarvestHub customer'
              : profile.name;

          final verified =
              profile.emailVerified ||
                  (authUser?.emailVerified ?? false);

          final photoUrl =
              _profilePhotoUrl ?? authUser?.photoURL;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            children: [
              _HeaderCard(
                initials: _initials(profile.name),
                name: displayName,
                email: profile.email,
                verified: verified,
                photoUrl: photoUrl,
                isUploadingPhoto: _isUploadingPhoto,
                onChangePhoto: _changeProfilePicture,
                memberSince: profile.createdAt == null
                    ? null
                    : _memberSince(
                        profile.createdAt!,
                      ),
              ),

              const SizedBox(height: 16),

              const _StatsRow(),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Personal details',
                trailing: TextButton.icon(
                  onPressed: snapshot.data == null
                      ? null
                      : () => _editProfile(profile),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                  ),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                children: [
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Full name',
                    value: _valueOrNotSet(profile.name),
                  ),
                  _DetailRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: _valueOrNotSet(profile.email),
                  ),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _valueOrNotSet(profile.phone),
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: _valueOrNotSet(profile.address),
                  ),
                  _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'Preferred pickup',
                    value: _valueOrNotSet(
                      profile.pickupLocation,
                    ),
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'My activity',
                children: [
                  _MenuTile(
                    icon: Icons.favorite_border,
                    label: 'Saved items',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WishlistScreen(),
                      ),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'My orders',
                    onTap: widget.onOpenOrders,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Account & support',
                children: [
                  _MenuTile(
                    icon: Icons.lock_reset_outlined,
                    label: 'Change password',
                    onTap: () => _changePassword(
                      profile.email,
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    label: 'About HarvestHub',
                    onTap: _showAbout,
                  ),
                  _MenuTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Contact us',
                    onTap: _showContact,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed:
                    _isSigningOut ? null : _logout,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                      ),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                    color: AppColors.error,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTextStyles.buttonLabel,
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'HarvestHub v$_appVersion',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HEADER CARD
// ─────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.verified,
    required this.photoUrl,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
    this.memberSince,
  });

  final String initials;
  final String name;
  final String email;
  final bool verified;
  final String? photoUrl;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;
  final String? memberSince;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.deepGreen,
            AppColors.mainGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isUploadingPhoto
                ? null
                : onChangePhoto,
            child: Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.wheatGold,
                      width: 3,
                    ),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(
                              photoUrl!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasPhoto
                      ? Text(
                          initials,
                          style: AppTextStyles.headingLarge
                              .copyWith(
                            color: AppColors.deepGreen,
                          ),
                        )
                      : null,
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: AppColors.wheatGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.deepGreen,
                        width: 2,
                      ),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGreen,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 13,
                            color: AppColors.deepGreen,
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium
                      .copyWith(
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      icon: verified
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      label: verified
                          ? 'Email verified'
                          : 'Email not verified',
                      background: verified
                          ? Colors.white.withValues(
                              alpha: 0.2,
                            )
                          : AppColors.wheatGold,
                    ),

                    if (memberSince != null)
                      _Chip(
                        icon:
                            Icons.calendar_today_outlined,
                        label:
                            'Since $memberSince',
                        background:
                            Colors.white.withValues(
                          alpha: 0.2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CHIP
// ─────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// STATS
// ─────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final wishlist = context.watch<WishlistProvider>();

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: orders.active.length,
            label: 'Active orders',
            icon: Icons.local_shipping_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: orders.past.length,
            label: 'Past orders',
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: wishlist.wishlistCount,
            label: 'Saved',
            icon: Icons.favorite_border,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// STAT TILE
// ─────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.autumnRust,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              trailing == null ? 14 : 6,
              8,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// DETAIL ROW
// ─────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 'Not set';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.deepGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style:
                          AppTextStyles.bodyRegular.copyWith(
                        color: isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontStyle: isEmpty
                            ? FontStyle.italic
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 48,
            color: AppColors.border,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MENU TILE
// ─────────────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.deepGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyRegular,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 48,
            color: AppColors.border,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CONTACT ROW
// ─────────────────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.softGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.mainGreen,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption,
            ),
            Text(
              value,
              style: AppTextStyles.bodyRegular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}