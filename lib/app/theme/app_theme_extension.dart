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
    );
  }
}
