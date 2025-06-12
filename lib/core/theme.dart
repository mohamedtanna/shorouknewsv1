import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Core Brand Colors - Unchanged
  static const Color primaryColor = Color(0xFF0D47A1); // Dark Blue
  static const Color secondaryColor = Color(0xFF043785); // Darker Blue
  static const Color tertiaryColor = Color(0xFFEE8025); // Orange
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color surfaceColor = Color(0xFFF4F5F8); // Light Grey/Off-white

  // Enhanced Color Palette
  static const Color primaryLight = Color(0xFF5472D3); // Lighter primary
  static const Color primaryDark = Color(0xFF002171); // Darker primary
  static const Color secondaryLight = Color(0xFF3F5AA6); // Lighter secondary
  static const Color tertiaryLight = Color(0xFFFFB366); // Lighter orange
  static const Color tertiaryDark = Color(0xFFD96A00); // Darker orange

  // Semantic Colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  // Text Colors - Enhanced
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF616161);
  static const Color textDisabledColor = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Surface Colors
  static const Color surfaceVariant = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFE8EAF0);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFBDBDBD);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Enhanced spacing and sizing constants
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusExtraLarge = 16.0;

  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
  static const double elevationMax = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: secondaryColor,
        onSecondary: textOnSecondary,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: Colors.white,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryLight,
        onTertiaryContainer: tertiaryDark,
        error: errorColor,
        onError: Colors.white,
        errorContainer: errorLight,
        onErrorContainer: Colors.white,
        surface: backgroundColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: textSecondaryColor,
        outline: borderColor,
        outlineVariant: dividerColor,
        shadow: shadowMedium,
        surfaceTint: primaryColor,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,

      // Enhanced AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: elevationMedium,
        shadowColor: shadowMedium,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
          letterSpacing: 0.15,
        ),
        iconTheme: const IconThemeData(
          color: textOnPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: textOnPrimary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: primaryDark,
          statusBarIconBrightness: Brightness.light,
        ),
        toolbarHeight: 56,
        titleSpacing: 16,
      ),

      // Enhanced Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: textDisabledColor,
          disabledForegroundColor: Colors.white,
          elevation: elevationMedium,
          shadowColor: shadowMedium,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(88, 48),
          maximumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: textDisabledColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(88, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: textDisabledColor,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(48, 40),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tertiaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textDisabledColor,
          disabledForegroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Enhanced Card Theme
      cardTheme: const CardThemeData(
        elevation: elevationMedium,
        shadowColor: shadowLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: backgroundColor,
        clipBehavior: Clip.antiAlias,
      ),

      // Enhanced Text Theme
      textTheme: const TextTheme(
        // Display styles
        displayLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 64,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 52,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          letterSpacing: 0.0,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 40,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          letterSpacing: 0.0,
          height: 1.22,
        ),

        // Headline styles
        headlineLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.0,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.0,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.0,
          height: 1.33,
        ),

        // Title styles
        titleLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.0,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: 0.15,
          height: 1.33,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textSecondaryColor,
          letterSpacing: 0.1,
          height: 1.375,
        ),

        // Body styles
        bodyLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimaryColor,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor,
          letterSpacing: 0.4,
          height: 1.33,
        ),

        // Label styles
        labelLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondaryColor,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondaryColor,
          letterSpacing: 0.5,
          height: 1.27,
        ),
      ),

      // Enhanced Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: tertiaryColor,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: elevationHigh,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        showUnselectedLabels: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      ),

      // Enhanced Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: primaryColor,
        selectedIconTheme: IconThemeData(color: tertiaryColor, size: 24),
        unselectedIconTheme: IconThemeData(color: Colors.white70, size: 22),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: tertiaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.white70,
          fontWeight: FontWeight.w400,
        ),
        elevation: elevationMedium,
        groupAlignment: 0.0,
        labelType: NavigationRailLabelType.selected,
        useIndicator: true,
        indicatorColor: Color(0x32EE8025),
      ),

      // Enhanced Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: primaryColor,
        elevation: elevationMax,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(radiusLarge),
            bottomRight: Radius.circular(radiusLarge),
          ),
        ),
        width: 280,
      ),

      // Enhanced List Tile
      listTileTheme: const ListTileThemeData(
        textColor: textOnPrimary,
        iconColor: Colors.white70,
        selectedColor: tertiaryColor,
        selectedTileColor: Color(0x1AEE8025),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        horizontalTitleGap: 16,
        minVerticalPadding: 8,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textOnPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
      ),

      // Enhanced Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: textDisabledColor, width: 1),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: textDisabledColor,
          fontWeight: FontWeight.w400,
          fontSize: 18,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: errorColor,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        prefixIconColor: primaryColor,
        suffixIconColor: primaryColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: false,
        isCollapsed: false,
      ),

      // Enhanced Tab Bar
      tabBarTheme: const TabBarThemeData(
        labelColor: tertiaryColor,
        unselectedLabelColor: Colors.white70,
        indicatorColor: tertiaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        overlayColor: WidgetStatePropertyAll(Color(0x1AEE8025)),
      ),

      // Enhanced Divider
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),

      // Enhanced FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tertiaryColor,
        foregroundColor: Colors.white,
        disabledElevation: 0,
        elevation: elevationHigh,
        focusElevation: elevationHigh,
        hoverElevation: elevationHigh,
        highlightElevation: elevationMax,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusExtraLarge),
        ),
        sizeConstraints: const BoxConstraints(
          minWidth: 56,
          minHeight: 56,
          maxWidth: 96,
          maxHeight: 96,
        ),
      ),

      // Enhanced Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor,
        circularTrackColor: dividerColor,
        linearMinHeight: 4.0,
        refreshBackgroundColor: backgroundColor,
      ),

      // Enhanced SnackBar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: tertiaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
        ),
        elevation: elevationHigh,
        actionOverflowThreshold: 0.25,
        showCloseIcon: false,
        closeIconColor: Colors.white,
      ),

      // Enhanced Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundColor,
        elevation: elevationMax,
        shadowColor: shadowMedium,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: primaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        clipBehavior: Clip.antiAlias,
      ),

      // Enhanced Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        deleteIconColor: textSecondaryColor,
        disabledColor: textDisabledColor,
        selectedColor: primaryColor,
        secondarySelectedColor: tertiaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        brightness: Brightness.light,
        elevation: elevationLow,
        pressElevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        iconTheme: const IconThemeData(
          color: textSecondaryColor,
          size: 20,
        ),
      ),

      // Enhanced Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: dividerColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withAlpha(50),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
      ),

      // Enhanced Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha(150);
          }
          return textDisabledColor;
        }),
      ),

      // Enhanced Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Enhanced Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return borderColor;
        }),
      ),
    );
  }

  // Helper methods for consistent spacing
  static SizedBox get verticalSpaceSmall => const SizedBox(height: 8);
  static SizedBox get verticalSpaceMedium => const SizedBox(height: 16);
  static SizedBox get verticalSpaceLarge => const SizedBox(height: 24);
  static SizedBox get verticalSpaceXLarge => const SizedBox(height: 32);

  static SizedBox get horizontalSpaceSmall => const SizedBox(width: 8);
  static SizedBox get horizontalSpaceMedium => const SizedBox(width: 16);
  static SizedBox get horizontalSpaceLarge => const SizedBox(width: 24);
  static SizedBox get horizontalSpaceXLarge => const SizedBox(width: 32);

  // Helper methods for consistent padding
  static EdgeInsets get paddingSmall => const EdgeInsets.all(8);
  static EdgeInsets get paddingMedium => const EdgeInsets.all(16);
  static EdgeInsets get paddingLarge => const EdgeInsets.all(24);
  static EdgeInsets get paddingXLarge => const EdgeInsets.all(32);

  // Helper methods for consistent margins
  static EdgeInsets get marginSmall => const EdgeInsets.all(8);
  static EdgeInsets get marginMedium => const EdgeInsets.all(16);
  static EdgeInsets get marginLarge => const EdgeInsets.all(24);
  static EdgeInsets get marginXLarge => const EdgeInsets.all(32);
}
