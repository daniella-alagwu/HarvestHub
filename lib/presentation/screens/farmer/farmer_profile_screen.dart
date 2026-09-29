import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/wishlist/wishlist_provider.dart';
import '../../../data/models/farmer_account.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/farmer_dashboard_repository.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/image_source_sheet.dart';
import '../splash/splash_screen.dart';
import 'farmer_edit_profile_screen.dart';

const _supportEmail = 'support@harvesthub.app';
const _supportPhone = '+234 800 000 0000';
const _appVersion = '1.0.0';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, this.onBackToOverview});

  final VoidCallback? onBackToOverview;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _repo = FarmerDashboardRepository();

  String? _uid;
  Stream<FarmerAccount>? _accountStream;
  Stream<List<ProductModel>>? _productsStream;
  Stream<List<OrderModel>>? _ordersStream;

  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingFarmImage = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _uid = uid;
      _accountStream = _repo.watchFarmerAccount(uid);
      _productsStream = _repo.streamProducts(uid);
      _ordersStream = _repo.streamOrders(uid);
    }
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

  String _valueOrNotSet(String value) =>
      value.trim().isEmpty ? 'Not set' : value.trim();

  Future<void> _quickChangeImage(
    FarmerAccount account, {
    required bool isAvatar,
  }) async {
    if (isAvatar ? _isUploadingPhoto : _isUploadingFarmImage) return;

    try {
      final bytes = await pickImageBytes(
        context,
        title: isAvatar
            ? (account.hasAvatar
                ? 'Change profile picture'
                : 'Add a profile picture')
            : (account.hasFarmImage ? 'Change farm photo' : 'Add a farm photo'),
        maxSize: isAvatar ? 800 : 1600,
      );
      if (bytes == null || !mounted) return;

      setState(() {
        if (isAvatar) {
          _isUploadingPhoto = true;
        } else {
          _isUploadingFarmImage = true;
        }
      });

      await _repo.updateFarmerProfile(
        uid: account.uid,
        name: account.name,
        phone: account.phone,
        farmName: account.farmName,
        marketLocation: account.marketLocation,
        description: account.description,
        tagline: account.tagline,
        newAvatarBytes: isAvatar ? bytes : null,
        newFarmImageBytes: isAvatar ? null : bytes,
      );

      if (!mounted) return;
      _showSnack(
        isAvatar ? 'Profile picture updated' : 'Farm photo updated',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      final text = e.toString().replaceFirst('Exception: ', '');
      _showSnack(
        text.toLowerCase().contains('image upload')
            ? text
            : 'Could not update the picture. Please try again.',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _isUploadingFarmImage = false;
        });
      }
    }
  }

  Future<void> _editProfile(FarmerAccount account) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FarmerEditProfileScreen(account: account),
      ),
    );
    if (saved == true && mounted) {
      _showSnack('Profile updated', success: true);
    }
  }

  Future<void> _changePassword(String email) async {
    if (email.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Text('We\'ll send a password reset link to $email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = AuthRepository();
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack('Reset link sent. Check your inbox.', success: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(auth.messageForResetError(e), success: false);
    }
  }

  Future<void> _logout() async {
    if (_isSigningOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await AuthRepository().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(page: const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      _showSnack('Could not log out. Please try again.', success: false);
    }
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    child: const Icon(Icons.eco_rounded,
                        color: AppColors.mainGreen),
                  ),
                  const SizedBox(width: 12),
                  Text('About HarvestHub', style: AppTextStyles.headingMedium),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'HarvestHub connects local farmers directly with customers. '
                'List your produce, manage stock and orders, and let people '
                'collect fresh food from your chosen market or pickup point.',
                style: AppTextStyles.bodyRegular.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Text('Version $_appVersion', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }

  void _showContact() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact us', style: AppTextStyles.headingMedium),
              const SizedBox(height: 6),
              Text('Need help with your farm account? Reach out.',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              const _ContactRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: _supportEmail),
              const SizedBox(height: 12),
              const _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _supportPhone),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.onBackToOverview == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: widget.onBackToOverview,
              ),
        title: const Text('Profile'),
      ),
      body: _accountStream == null
          ? Center(
              child: Text('You\'re not signed in.',
                  style: AppTextStyles.bodyMuted),
            )
          : StreamBuilder<FarmerAccount>(
              stream: _accountStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.mainGreen),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
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

                final account = snapshot.data!;
                final authUser = FirebaseAuth.instance.currentUser;
                final verified =
                    account.emailVerified || (authUser?.emailVerified ?? false);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _HeaderCard(
                      account: account,
                      verified: verified,
                      isUploadingPhoto: _isUploadingPhoto,
                      onChangePhoto: () =>
                          _quickChangeImage(account, isAvatar: true),
                      memberSince: account.createdAt == null
                          ? null
                          : _memberSince(account.createdAt!),
                    ),
                    const SizedBox(height: 16),
                    _StatsRow(
                      productsStream: _productsStream!,
                      ordersStream: _ordersStream!,
                      rating: account.rating,
                      farmerId: account.uid,
                    ),
                    const SizedBox(height: 16),
                    _FollowersPanel(farmerId: account.uid),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Farm details',
                      trailing: TextButton.icon(
                        onPressed: () => _editProfile(account),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.mainGreen,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      children: [
                        _FarmBanner(
                          imageUrl: account.farmImageUrl,
                          isUploading: _isUploadingFarmImage,
                          onTap: () =>
                              _quickChangeImage(account, isAvatar: false),
                        ),
                        _DetailRow(
                          icon: Icons.agriculture_outlined,
                          label: 'Farm name',
                          value: _valueOrNotSet(account.farmName),
                        ),
                        if (account.tagline.trim().isNotEmpty)
                          _DetailRow(
                            icon: Icons.short_text_rounded,
                            label: 'Tagline',
                            value: account.tagline.trim(),
                          ),
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'About your farm',
                          value: _valueOrNotSet(account.description),
                        ),
                        _DetailRow(
                          icon: Icons.storefront_outlined,
                          label: 'Market / pickup location',
                          value: _valueOrNotSet(account.marketLocation),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Personal details',
                      trailing: TextButton.icon(
                        onPressed: () => _editProfile(account),
                        icon: const Icon(Icons.edit_outlined, size: 16),
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
                          value: _valueOrNotSet(account.name),
                        ),
                        _DetailRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: _valueOrNotSet(account.email),
                        ),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _valueOrNotSet(account.phone),
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
                          onTap: () => _changePassword(account.email),
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
                      onPressed: _isSigningOut ? null : _logout,
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTextStyles.buttonLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('HarvestHub v$_appVersion',
                          style: AppTextStyles.caption),
                    ),
                    const SizedBox(height: 72),
                  ],
                );
              },
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.account,
    required this.verified,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
    this.memberSince,
  });

  final FarmerAccount account;
  final bool verified;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;
  final String? memberSince;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = account.hasAvatar;
    final name =
        account.name.trim().isEmpty ? 'HarvestHub farmer' : account.name;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.mainGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isUploadingPhoto ? null : onChangePhoto,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wheatGold, width: 3),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(account.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasPhoto
                      ? Text(
                          account.initials,
                          style: AppTextStyles.headingLarge
                              .copyWith(color: AppColors.deepGreen),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.wheatGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepGreen, width: 2),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGreen,
                            ),
                          )
                        : const Icon(Icons.camera_alt,
                            size: 13, color: AppColors.deepGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.headingMedium.copyWith(color: Colors.white),
                ),
                if (account.farmName.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    account.farmName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColors.wheatGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
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
                      label: verified ? 'Email verified' : 'Email not verified',
                      background: verified
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.wheatGold,
                    ),
                    if (memberSince != null)
                      _Chip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Since $memberSince',
                        background: Colors.white.withValues(alpha: 0.2),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.productsStream,
    required this.ordersStream,
    required this.rating,
    required this.farmerId,
  });

  final Stream<List<ProductModel>> productsStream;
  final Stream<List<OrderModel>> ordersStream;
  final double rating;
  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: productsStream,
      builder: (context, productSnap) {
        return StreamBuilder<List<OrderModel>>(
          stream: ordersStream,
          builder: (context, orderSnap) {
            final products = productSnap.data?.length ?? 0;
            final orders = orderSnap.data?.length ?? 0;
            final followersCount = context.watch<WishlistProvider>();
            return FutureBuilder<int>(
              future: followersCount.followersCountFor(farmerId),
              builder: (context, followerSnap) {
                final followers = followerSnap.data ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '$products',
                        label: 'Products',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value: '$orders',
                        label: 'Orders',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value: '$followers',
                        label: 'Followers',
                        icon: Icons.people_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        value: rating > 0 ? rating.toStringAsFixed(1) : '—',
                        label: 'Rating',
                        icon: Icons.star_outline_rounded,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FollowersPanel extends StatelessWidget {
  const _FollowersPanel({required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: FutureBuilder<List<String>>(
        future: context
            .read<WishlistProvider>()
            .customerNamesFollowingFarmer(farmerId),
        builder: (context, snapshot) {
          final names = snapshot.data ?? const <String>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border_rounded,
                      size: 18, color: AppColors.mainGreen),
                  const SizedBox(width: 8),
                  Text('Customers following you',
                      style: AppTextStyles.headingMedium),
                ],
              ),
              const SizedBox(height: 12),
              if (names.isEmpty)
                Text(
                  'No customers have followed your farm yet.',
                  style: AppTextStyles.bodyMuted,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: names
                      .map((name) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(name,
                                style: AppTextStyles.caption
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.autumnRust),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headingMedium),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _FarmBanner extends StatelessWidget {
  const _FarmBanner({
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
  });

  final String imageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: GestureDetector(
        onTap: isUploading ? null : onTap,
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softGreen.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: isUploading
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : hasImage
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Change photo',
                                style: AppTextStyles.caption
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: AppColors.mainGreen),
                        const SizedBox(height: 6),
                        Text('Add a farm photo',
                            style: AppTextStyles.bodyRegular
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
        ),
      ),
    );
  }
}

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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, trailing == null ? 14 : 6, 8, 4),
            child: Row(
              children: [
                Expanded(
                    child: Text(title, style: AppTextStyles.headingMedium)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.deepGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontStyle: isEmpty ? FontStyle.italic : null,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 48, color: AppColors.border),
      ],
    );
  }
}

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.deepGreen),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppTextStyles.bodyRegular)),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 48, color: AppColors.border),
      ],
    );
  }
}

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
          child: Icon(icon, size: 18, color: AppColors.mainGreen),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              value,
              style: AppTextStyles.bodyRegular
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
