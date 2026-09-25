import 'package:flutter/material.dart';


class AppColors {
  AppColors._(); 
  static const Color mainGreen = Color(0xFF25995C);

  /// bold green for headers, footers, inactive states, typography accents & overlays.
  static const Color deepGreen = Color(0xFF0D5F4E);

  /// Lighter tint of mainGreen — hover/pressed states, chip backgrounds,.
  static const Color softGreen = Color(0xFFDCF2E7);




                           // AUTUMN ACCENTS
  

/// Highlight text, secondary buttons, and banners (Rich Burnt Orange / Terracotta)
  static const Color autumnRust = Color(0xFFC85A2A);

  /// Ratings (stars), "New" badges, AI Assistant chat bubbles (Warm Harvest / Amber Gold)
  static const Color wheatGold = Color(0xFFE08D2A);

  /// Subtle borders, category cards for root veggies/grains (Deep Warm Soil Brown)
  static const Color earthySoil = Color(0xFF5A3825);


                  
                  
                          // SYSTEM / STATUS COLORS
  

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

 
                          // NEUTRALS / SURFACE
  

  /// App background — lets greens and autumn accents pop.
  static const Color background = Color(0xFFF9FAFB);

  /// Card / elevated surface color, slightly whiter than background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary body text on light surfaces.
  static const Color textPrimary = Color(0xFF1B1B1B);

  /// Secondary/muted text (timestamps, helper text, placeholders).
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color textMuted = Color(0xFF757575);

  /// Hairline dividers and input borders.
  static const Color border = Color(0xFFE5E7EB);

  
                // additions
    

  /// A muted, low-saturation green for disabled buttons/icons, so
  /// "disabled" reads clearly against mainGreen without introducing gray.
  static const Color disabledGreen = Color(0xFFA9CDBB);

  /// Overlay scrim for modals/bottom sheets 
  static const Color scrim = Color(0x660D5F4E);
}
