import '../../screen.dart';

class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF4666E1);
  static const Color lightCanvas = Color(0xFFEEF2FA);
  static const Color darkCanvas = Color(0xFF0D2042);
  static const Color darkScaffold = Color(0xFF08111F);
  static const ThemeMode defaultMode = ThemeMode.system;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDAE0F9),
          onPrimaryContainer: const Color(0xFF1C285A),
          secondary: const Color(0xFF8990B0),
          onSecondary: darkCanvas,
          secondaryContainer: const Color(0xFFE7E8EF),
          onSecondaryContainer: const Color(0xFF363946),
          tertiary: const Color(0xFF28ADBB),
          onTertiary: const Color(0xFF062F34),
          tertiaryContainer: const Color(0xFFD4EEF1),
          onTertiaryContainer: const Color(0xFF123C42),
          error: const Color(0xFFE25867),
          onError: darkCanvas,
          errorContainer: const Color(0xFFF9DDE0),
          onErrorContainer: const Color(0xFF641E28),
          surface: const Color(0xFFF8F9FD),
          onSurface: darkCanvas,
          outline: const Color(0xFF65688A),
          outlineVariant: const Color(0xFFE1E4E7),
          inverseSurface: const Color(0xFF1B3155),
          onInverseSurface: const Color(0xFFEAEDF1),
          inversePrimary: const Color(0xFF9EAEF0),
          shadow: Colors.black,
          scrim: Colors.black,
          surfaceTint: primary,
        );

    const extension = AppThemeExtension(
      mutedText: Color(0xFF65688A),
      success: Color(0xFF28ADBB),
      warning: Color(0xFFE1CD3C),
      info: Color(0xFF55B0DB),
      cardBackground: Color(0xFFF8F9FD),
      cardShadow: Color(0x13000000),
      subtleFill: Color(0xFFF3F4F8),
      shellHeaderBackground: Colors.white,
      desktopDrawerBackground: Colors.white,
      desktopDrawerForeground: Color(0xFF0D2042),
      desktopDrawerMuted: Color(0xFF65688A),
      mobileDrawerBackground: Color(0xFFF8F9FD),
      mobileDrawerForeground: Color(0xFF0D2042),
      mobileDrawerMuted: Color(0xFF65688A),
      heroGradientStart: Color(0xFF6F5FE0),
      heroGradientEnd: Color(0xFF4666E1),
      heroOverlayBackground: Color(0x1AFFFFFF),
      heroOverlayBorder: Color(0x1FFFFFFF),
      crmLeadAccent: Color(0xFF55B0DB),
      crmEnquiryAccent: Color(0xFF6F5FE0),
      crmTodayAccent: Color(0xFFE1CD3C),
      crmPendingAccent: Color(0xFFE17846),
      crmTodayChartAccent: Color(0xFF55B0DB),
      crmOverdueChartAccent: Color(0xFF6F5FE0),
      crmUpcomingChartAccent: Color(0xFFE1CD3C),
      crmNoDateChartAccent: Color(0xFFE17846),
      crmActionBackground: Color(0xFF0D2042),
      crmActionShadow: Color(0x260D2042),
      crmChartGrid: Color(0xFFE1E4E7),
      crmChartLineStart: Color(0xFF55B0DB),
      crmChartLineEnd: Color(0xFF4666E1),
      crmChartFill: Color(0xFF55B0DB),
      crmChartText: Color(0xFF0D2042),
      crmChartMutedText: Color(0xFF65688A),
      tableBorder: Color(0xFFDEE1E5),
      tableHeaderBackground: Color(0xFFEAEDF1),
      tableTitleText: Color(0xFF0D2042),
      tableMutedText: Color(0xFF65688A),
      tableLinkText: Color(0xFF4666E1),
      tableRowAlternate: Color(0xFFF3F4F8),
      tableRowHover: Color(0xFFE9EDF8),
      tableRowSelected: Color(0xFFDAE0F9),
      tableCellText: Color(0xFF0D2042),
      tableInputBorder: Color(0xFFE1E4E7),
    );

    return _build(
      colorScheme: colorScheme,
      extension: extension,
      scaffoldBackground: lightCanvas,
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF263F78),
          onPrimaryContainer: const Color(0xFFEAEDF1),
          secondary: const Color(0xFF94A3B8),
          onSecondary: darkCanvas,
          secondaryContainer: const Color(0xFF27364B),
          onSecondaryContainer: const Color(0xFFEAEDF1),
          tertiary: const Color(0xFF55B0DB),
          onTertiary: darkCanvas,
          tertiaryContainer: const Color(0xFF174B61),
          onTertiaryContainer: const Color(0xFFDDF5FF),
          error: const Color(0xFFFF8995),
          onError: darkCanvas,
          errorContainer: const Color(0xFF6A2732),
          onErrorContainer: const Color(0xFFFFE8EA),
          surface: const Color(0xFF121F33),
          onSurface: const Color(0xFFE7EDF6),
          outline: const Color(0xFF7C8DA5),
          outlineVariant: const Color(0xFF2C3D55),
          inverseSurface: const Color(0xFFF8F9FD),
          onInverseSurface: darkCanvas,
          inversePrimary: primary,
          shadow: Colors.black,
          scrim: Colors.black,
          surfaceTint: primary,
        );

    const extension = AppThemeExtension(
      mutedText: Color(0xFF9AA8BC),
      success: Color(0xFF45C3CF),
      warning: Color(0xFFE9D85F),
      info: Color(0xFF70C6EA),
      cardBackground: Color(0xFF121F33),
      cardShadow: Color(0x66000000),
      subtleFill: Color(0xFF17263A),
      shellHeaderBackground: Color(0xFF101C2D),
      desktopDrawerBackground: Color(0xFF091A36),
      desktopDrawerForeground: Color(0xFFF8F9FD),
      desktopDrawerMuted: Color(0xFF94A3B8),
      mobileDrawerBackground: Color(0xFF101C2D),
      mobileDrawerForeground: Color(0xFFF8F9FD),
      mobileDrawerMuted: Color(0xFF94A3B8),
      heroGradientStart: Color(0xFF6F5FE0),
      heroGradientEnd: Color(0xFF4666E1),
      heroOverlayBackground: Color(0x1AFFFFFF),
      heroOverlayBorder: Color(0x1FFFFFFF),
      crmLeadAccent: Color(0xFF70C6EA),
      crmEnquiryAccent: Color(0xFF9A8CF0),
      crmTodayAccent: Color(0xFFE9D85F),
      crmPendingAccent: Color(0xFFF09568),
      crmTodayChartAccent: Color(0xFF70C6EA),
      crmOverdueChartAccent: Color(0xFF9A8CF0),
      crmUpcomingChartAccent: Color(0xFFE9D85F),
      crmNoDateChartAccent: Color(0xFFF09568),
      crmActionBackground: Color(0xFF4666E1),
      crmActionShadow: Color(0x734666E1),
      crmChartGrid: Color(0xFF2C3D55),
      crmChartLineStart: Color(0xFF70C6EA),
      crmChartLineEnd: Color(0xFF6F87E7),
      crmChartFill: Color(0xFF55B0DB),
      crmChartText: Color(0xFFEAEDF1),
      crmChartMutedText: Color(0xFF9AA8BC),
      tableBorder: Color(0xFF2C3D55),
      tableHeaderBackground: Color(0xFF1B2B42),
      tableTitleText: Color(0xFFF8F9FD),
      tableMutedText: Color(0xFF9AA8BC),
      tableLinkText: Color(0xFF9BAEF5),
      tableRowAlternate: Color(0xFF16263B),
      tableRowHover: Color(0xFF1D334F),
      tableRowSelected: Color(0xFF263F78),
      tableCellText: Color(0xFFE2E9F3),
      tableInputBorder: Color(0xFF3B4F69),
    );

    return _build(
      colorScheme: colorScheme,
      extension: extension,
      scaffoldBackground: darkScaffold,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppThemeExtension extension,
    required Color scaffoldBackground,
  }) {
    final textTheme = _textTheme(colorScheme);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      side: BorderSide(color: extension.tableBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      cardColor: extension.cardBackground,
      dividerColor: colorScheme.outlineVariant,
      disabledColor: extension.mutedText.withValues(alpha: 0.45),
      extensions: [extension],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: extension.shellHeaderBackground,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: extension.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: extension.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extension.subtleFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppUiConstants.spacingSm,
          horizontal: AppUiConstants.spacingMd,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: extension.mutedText),
        hintStyle: textTheme.bodyMedium?.copyWith(color: extension.mutedText),
        helperStyle: textTheme.bodySmall?.copyWith(color: extension.mutedText),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        border: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.outlineVariant,
          disabledForegroundColor: extension.mutedText,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingMd,
            vertical: AppUiConstants.spacingSm,
          ),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.outlineVariant,
          disabledForegroundColor: extension.mutedText,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingMd,
            vertical: AppUiConstants.spacingSm,
          ),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingMd,
            vertical: AppUiConstants.spacingSm,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: controlShape,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: _selectionFill(colorScheme, extension),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: _selectionFill(colorScheme, extension),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: _selectionFill(colorScheme, extension),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.outlineVariant.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.45);
          }
          return colorScheme.outlineVariant;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: extension.subtleFill,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppUiConstants.spacingSm,
          vertical: AppUiConstants.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        decoration: BoxDecoration(
          color: extension.cardBackground,
          border: Border.all(color: extension.tableBorder),
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        ),
        headingRowHeight: 46,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: AppUiConstants.spacingSm,
        columnSpacing: AppUiConstants.spacingXl,
        headingRowColor: WidgetStatePropertyAll(
          extension.tableHeaderBackground,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return extension.tableRowSelected;
          }
          if (states.contains(WidgetState.hovered)) {
            return extension.tableRowHover;
          }
          return Colors.transparent;
        }),
        headingTextStyle: textTheme.labelMedium?.copyWith(
          color: extension.tableTitleText,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: textTheme.bodySmall?.copyWith(
          color: extension.tableCellText,
        ),
        dividerThickness: 1,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: extension.mobileDrawerBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: extension.desktopDrawerBackground,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: extension.desktopDrawerMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: extension.desktopDrawerForeground,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: extension.desktopDrawerMuted,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: extension.mutedText,
        textColor: colorScheme.onSurface,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        shape: controlShape,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: extension.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        textStyle: textTheme.bodyMedium,
        shape: cardShape,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: extension.subtleFill,
          border: inputBorder,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(extension.cardBackground),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: extension.mutedText,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: colorScheme.primary,
        dividerColor: colorScheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
        circularTrackColor: colorScheme.outlineVariant,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: EdgeInsets.zero,
        iconColor: extension.mutedText,
        collapsedIconColor: extension.mutedText,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          extension.mutedText.withValues(alpha: 0.55),
        ),
        trackColor: WidgetStatePropertyAll(
          colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        radius: const Radius.circular(AppUiConstants.pillRadius),
        thickness: const WidgetStatePropertyAll(6),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      brightness: colorScheme.brightness,
      fontFamily: 'Nunito',
    ).textTheme;

    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(fontFamily: 'Nunito');
  }

  static WidgetStateProperty<Color?> _selectionFill(
    ColorScheme colorScheme,
    AppThemeExtension extension,
  ) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return extension.mutedText.withValues(alpha: 0.45);
      }
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      return colorScheme.outline;
    });
  }
}
