import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/colors/app_colors.dart';
import '../theme/text_styles.dart';

Future<Uint8List?> pickImageBytes(
  BuildContext context, {
  required String title,
  double maxSize = 1200,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
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
            Text(title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 14),
            _SourceTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take a photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 6),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              subtitle: 'Select a picture from your device',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;

  final image = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: maxSize,
    maxHeight: maxSize,
  );
  if (image == null) return null;
  return image.readAsBytes();
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppColors.softGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.mainGreen),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}