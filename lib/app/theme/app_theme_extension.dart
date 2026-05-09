import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.mutedText,
    required this.cardBackground,
    required this.cardShadow,
    required this.subtleFill,
    required this.shellHeaderBackground,
    required this.desktopDrawerBackground,
    required this.desktopDrawerForeground,
    required this.desktopDrawerMuted,
    required this.mobileDrawerBackground,
    required this.mobileDrawerForeground,
    required this.mobileDrawerMuted,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.heroOverlayBackground,
    required this.heroOverlayBorder,
    required this.crmLeadAccent,
    required this.crmEnquiryAccent,
    required this.crmTodayAccent,
    required this.crmPendingAccent,
    required this.crmTodayChartAccent,
    required this.crmOverdueChartAccent,
    required this.crmUpcomingChartAccent,
    required this.crmNoDateChartAccent,
    required this.crmActionBackground,
    required this.crmActionShadow,
    required this.crmChartGrid,
    required this.crmChartLineStart,
    required this.crmChartLineEnd,
    required this.crmChartFill,
    required this.crmChartText,
    required this.crmChartMutedText,
  });

  final Color mutedText;
  final Color cardBackground;
  final Color cardShadow;
  final Color subtleFill;
  final Color shellHeaderBackground;
  final Color desktopDrawerBackground;
  final Color desktopDrawerForeground;
  final Color desktopDrawerMuted;
  final Color mobileDrawerBackground;
  final Color mobileDrawerForeground;
  final Color mobileDrawerMuted;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color heroOverlayBackground;
  final Color heroOverlayBorder;
  final Color crmLeadAccent;
  final Color crmEnquiryAccent;
  final Color crmTodayAccent;
  final Color crmPendingAccent;
  final Color crmTodayChartAccent;
  final Color crmOverdueChartAccent;
  final Color crmUpcomingChartAccent;
  final Color crmNoDateChartAccent;
  final Color crmActionBackground;
  final Color crmActionShadow;
  final Color crmChartGrid;
  final Color crmChartLineStart;
  final Color crmChartLineEnd;
  final Color crmChartFill;
  final Color crmChartText;
  final Color crmChartMutedText;

  @override
  AppThemeExtension copyWith({
    Color? mutedText,
    Color? cardBackground,
    Color? cardShadow,
    Color? subtleFill,
    Color? shellHeaderBackground,
    Color? desktopDrawerBackground,
    Color? desktopDrawerForeground,
    Color? desktopDrawerMuted,
    Color? mobileDrawerBackground,
    Color? mobileDrawerForeground,
    Color? mobileDrawerMuted,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? heroOverlayBackground,
    Color? heroOverlayBorder,
    Color? crmLeadAccent,
    Color? crmEnquiryAccent,
    Color? crmTodayAccent,
    Color? crmPendingAccent,
    Color? crmTodayChartAccent,
    Color? crmOverdueChartAccent,
    Color? crmUpcomingChartAccent,
    Color? crmNoDateChartAccent,
    Color? crmActionBackground,
    Color? crmActionShadow,
    Color? crmChartGrid,
    Color? crmChartLineStart,
    Color? crmChartLineEnd,
    Color? crmChartFill,
    Color? crmChartText,
    Color? crmChartMutedText,
  }) {
    return AppThemeExtension(
      mutedText: mutedText ?? this.mutedText,
      cardBackground: cardBackground ?? this.cardBackground,
      cardShadow: cardShadow ?? this.cardShadow,
      subtleFill: subtleFill ?? this.subtleFill,
      shellHeaderBackground:
          shellHeaderBackground ?? this.shellHeaderBackground,
      desktopDrawerBackground:
          desktopDrawerBackground ?? this.desktopDrawerBackground,
      desktopDrawerForeground:
          desktopDrawerForeground ?? this.desktopDrawerForeground,
      desktopDrawerMuted: desktopDrawerMuted ?? this.desktopDrawerMuted,
      mobileDrawerBackground:
          mobileDrawerBackground ?? this.mobileDrawerBackground,
      mobileDrawerForeground:
          mobileDrawerForeground ?? this.mobileDrawerForeground,
      mobileDrawerMuted: mobileDrawerMuted ?? this.mobileDrawerMuted,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      heroOverlayBackground:
          heroOverlayBackground ?? this.heroOverlayBackground,
      heroOverlayBorder: heroOverlayBorder ?? this.heroOverlayBorder,
      crmLeadAccent: crmLeadAccent ?? this.crmLeadAccent,
      crmEnquiryAccent: crmEnquiryAccent ?? this.crmEnquiryAccent,
      crmTodayAccent: crmTodayAccent ?? this.crmTodayAccent,
      crmPendingAccent: crmPendingAccent ?? this.crmPendingAccent,
      crmTodayChartAccent: crmTodayChartAccent ?? this.crmTodayChartAccent,
      crmOverdueChartAccent:
          crmOverdueChartAccent ?? this.crmOverdueChartAccent,
      crmUpcomingChartAccent:
          crmUpcomingChartAccent ?? this.crmUpcomingChartAccent,
      crmNoDateChartAccent:
          crmNoDateChartAccent ?? this.crmNoDateChartAccent,
      crmActionBackground: crmActionBackground ?? this.crmActionBackground,
      crmActionShadow: crmActionShadow ?? this.crmActionShadow,
      crmChartGrid: crmChartGrid ?? this.crmChartGrid,
      crmChartLineStart: crmChartLineStart ?? this.crmChartLineStart,
      crmChartLineEnd: crmChartLineEnd ?? this.crmChartLineEnd,
      crmChartFill: crmChartFill ?? this.crmChartFill,
      crmChartText: crmChartText ?? this.crmChartText,
      crmChartMutedText: crmChartMutedText ?? this.crmChartMutedText,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t) ?? cardShadow,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t) ?? subtleFill,
      shellHeaderBackground:
          Color.lerp(shellHeaderBackground, other.shellHeaderBackground, t) ??
          shellHeaderBackground,
      desktopDrawerBackground:
          Color.lerp(
            desktopDrawerBackground,
            other.desktopDrawerBackground,
            t,
          ) ??
          desktopDrawerBackground,
      desktopDrawerForeground:
          Color.lerp(
            desktopDrawerForeground,
            other.desktopDrawerForeground,
            t,
          ) ??
          desktopDrawerForeground,
      desktopDrawerMuted:
          Color.lerp(desktopDrawerMuted, other.desktopDrawerMuted, t) ??
          desktopDrawerMuted,
      mobileDrawerBackground:
          Color.lerp(mobileDrawerBackground, other.mobileDrawerBackground, t) ??
          mobileDrawerBackground,
      mobileDrawerForeground:
          Color.lerp(mobileDrawerForeground, other.mobileDrawerForeground, t) ??
          mobileDrawerForeground,
      mobileDrawerMuted:
          Color.lerp(mobileDrawerMuted, other.mobileDrawerMuted, t) ??
          mobileDrawerMuted,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t) ??
          heroGradientStart,
      heroGradientEnd:
          Color.lerp(heroGradientEnd, other.heroGradientEnd, t) ??
          heroGradientEnd,
      heroOverlayBackground:
          Color.lerp(heroOverlayBackground, other.heroOverlayBackground, t) ??
          heroOverlayBackground,
      heroOverlayBorder:
          Color.lerp(heroOverlayBorder, other.heroOverlayBorder, t) ??
          heroOverlayBorder,
      crmLeadAccent:
          Color.lerp(crmLeadAccent, other.crmLeadAccent, t) ?? crmLeadAccent,
      crmEnquiryAccent:
          Color.lerp(crmEnquiryAccent, other.crmEnquiryAccent, t) ??
          crmEnquiryAccent,
      crmTodayAccent:
          Color.lerp(crmTodayAccent, other.crmTodayAccent, t) ??
          crmTodayAccent,
      crmPendingAccent:
          Color.lerp(crmPendingAccent, other.crmPendingAccent, t) ??
          crmPendingAccent,
      crmTodayChartAccent:
          Color.lerp(crmTodayChartAccent, other.crmTodayChartAccent, t) ??
          crmTodayChartAccent,
      crmOverdueChartAccent:
          Color.lerp(crmOverdueChartAccent, other.crmOverdueChartAccent, t) ??
          crmOverdueChartAccent,
      crmUpcomingChartAccent:
          Color.lerp(crmUpcomingChartAccent, other.crmUpcomingChartAccent, t) ??
          crmUpcomingChartAccent,
      crmNoDateChartAccent:
          Color.lerp(crmNoDateChartAccent, other.crmNoDateChartAccent, t) ??
          crmNoDateChartAccent,
      crmActionBackground:
          Color.lerp(crmActionBackground, other.crmActionBackground, t) ??
          crmActionBackground,
      crmActionShadow:
          Color.lerp(crmActionShadow, other.crmActionShadow, t) ??
          crmActionShadow,
      crmChartGrid:
          Color.lerp(crmChartGrid, other.crmChartGrid, t) ?? crmChartGrid,
      crmChartLineStart:
          Color.lerp(crmChartLineStart, other.crmChartLineStart, t) ??
          crmChartLineStart,
      crmChartLineEnd:
          Color.lerp(crmChartLineEnd, other.crmChartLineEnd, t) ??
          crmChartLineEnd,
      crmChartFill:
          Color.lerp(crmChartFill, other.crmChartFill, t) ?? crmChartFill,
      crmChartText:
          Color.lerp(crmChartText, other.crmChartText, t) ?? crmChartText,
      crmChartMutedText:
          Color.lerp(crmChartMutedText, other.crmChartMutedText, t) ??
          crmChartMutedText,
    );
  }
}
