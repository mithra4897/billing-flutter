import 'package:flutter/material.dart';

import '../constants/app_ui_constants.dart';
import 'app_theme_extension.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = Color(0xFF0A2540);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    const extension = AppThemeExtension(
      mutedText: Color(0xFF52606D),
      cardBackground: Colors.white,
      cardShadow: Color(0x14000000),
      subtleFill: Color(0xFFF7F9FB),
      shellHeaderBackground: Colors.white,
      desktopDrawerBackground: Color(0xFF0A2540),
      desktopDrawerForeground: Colors.white,
      desktopDrawerMuted: Color(0xFFAFC2D5),
      mobileDrawerBackground: Color(0xFFF4F7FB),
      mobileDrawerForeground: Color(0xFF16324F),
      mobileDrawerMuted: Color(0xFF5A6E85),
      heroGradientStart: Color(0xFF0A2540),
      heroGradientEnd: Color(0xFF184E77),
      heroOverlayBackground: Color(0x1AFFFFFF),
      heroOverlayBorder: Color(0x1FFFFFFF),
      crmLeadAccent: Color(0xFF2F9BD6),
      crmEnquiryAccent: Color(0xFF7B4DCC),
      crmTodayAccent: Color(0xFFD2A43A),
      crmPendingAccent: Color(0xFFA7543A),
      crmTodayChartAccent: Color(0xFF3294E4),
      crmOverdueChartAccent: Color(0xFF7741C8),
      crmUpcomingChartAccent: Color(0xFFFFB331),
      crmNoDateChartAccent: Color(0xFFE5672E),
      crmActionBackground: Color(0xFF0E2238),
      crmActionShadow: Color(0x26000000),
      crmChartGrid: Color(0xFFE8EEF4),
      crmChartLineStart: Color(0xFF6FB4E9),
      crmChartLineEnd: Color(0xFF2A6A90),
      crmChartFill: Color(0xFF6FB4E9),
      crmChartText: Color(0xFF2A2E35),
      crmChartMutedText: Color(0xFF5A6775),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFEFF3F6),
      cardColor: extension.cardBackground,
      dividerColor: Colors.transparent,
      extensions: const [extension],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extension.subtleFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: EdgeInsets.zero,
        iconColor: extension.mutedText,
        collapsedIconColor: extension.mutedText,
      ),
    );
  }
}
