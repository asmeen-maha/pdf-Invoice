import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Text styles used across the app.
class AppTextStyles {
  AppTextStyles._();

  // Headings (Prompt)
  static const TextStyle pageTitle = TextStyle(fontFamily: AppFonts.heading, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const TextStyle cardTitle = TextStyle(fontFamily: AppFonts.heading, fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const TextStyle sectionTitle = TextStyle(fontFamily: AppFonts.heading, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const TextStyle statValue = TextStyle(fontFamily: AppFonts.heading, fontSize: 30, fontWeight: FontWeight.w600, height: 1.1);
  static const TextStyle dayNumber = TextStyle(fontFamily: AppFonts.heading, fontSize: 22, fontWeight: FontWeight.w600, height: 1.1);
  static const TextStyle amount = TextStyle(fontFamily: AppFonts.heading, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const TextStyle label = TextStyle(fontFamily: AppFonts.heading, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const TextStyle button = TextStyle(fontFamily: AppFonts.heading, fontSize: 16, fontWeight: FontWeight.w600);

  // Body (Noto Sans Thai)
  static const TextStyle body = TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: AppColors.ink);
  static const TextStyle bodyStrong = TextStyle(fontFamily: AppFonts.body, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const TextStyle caption = TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: AppColors.muted);
  static const TextStyle small = TextStyle(fontFamily: AppFonts.body, fontSize: 12, color: AppColors.muted);
}
