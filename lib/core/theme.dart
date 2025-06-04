import 'package:flutter/material.dart';

class AppTheme {
  // Colors from the original app
  static const Color primaryColor = Color(0xFF0D47A1); // Dark Blue
  static const Color secondaryColor = Color(0xFF043785); // Darker Blue
  static const Color tertiaryColor = Color(0xFFEE8025); // Orange
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color surfaceColor = Color(0xFFF4F5F8); // Light Grey/Off-white

  // Additional common colors you might need
  static const Color errorColor = Color(0xFFB00020); // Standard Material error red
  static const Color onSuccessColor = Colors.green; // Standard green for success
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color textDisabledColor = Colors.grey;


  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal', // Default font for the entire app
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor, 
        primary: primaryColor,   
        secondary: secondaryColor, 
        tertiary: tertiaryColor, 
        surface: surfaceColor,
        // Removed 'background: backgroundColor,' as it's not a direct param for fromSeed
        // and scaffoldBackgroundColor handles the main background.
        error: errorColor, 
      ),
      
      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, 
        elevation: 0, 
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, 
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 15, 
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), 
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
           textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        )
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600, 
            fontSize: 15,
          )
        )
      ),
      
      // Corrected: CardTheme -> CardThemeData
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), 
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
        color: Colors.white, 
        surfaceTintColor: Colors.transparent, 
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 57, fontWeight: FontWeight.w400, color: textPrimaryColor, letterSpacing: -0.25),
        displayMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 45, fontWeight: FontWeight.w400, color: textPrimaryColor, letterSpacing: 0.0),
        displaySmall: TextStyle(fontFamily: 'Tajawal', fontSize: 36, fontWeight: FontWeight.w400, color: textPrimaryColor, letterSpacing: 0.0),

        headlineLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 32, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 0.0),
        headlineMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 28, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 0.0),
        headlineSmall: TextStyle(fontFamily: 'Tajawal', fontSize: 24, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 0.0),

        titleLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w500, color: primaryColor, letterSpacing: 0.15),
        titleMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor, letterSpacing: 0.15), 
        titleSmall: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w500, color: textSecondaryColor, letterSpacing: 0.1),

        bodyLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.normal, color: textPrimaryColor, letterSpacing: 0.5, height: 1.5),
        bodyMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.normal, color: textPrimaryColor, letterSpacing: 0.25, height: 1.4),
        bodySmall: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.normal, color: textSecondaryColor, letterSpacing: 0.4, height: 1.3),

        labelLarge: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.1), 
        labelMedium: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryColor, letterSpacing: 0.5),
        labelSmall: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.w500, color: textSecondaryColor, letterSpacing: 0.5),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryColor, 
        selectedItemColor: tertiaryColor,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed, 
        selectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
        elevation: 8.0, 
      ),
      
      drawerTheme: const DrawerThemeData(
        backgroundColor: primaryColor, 
      ),
      
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white, 
        iconColor: Colors.white70,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w500, 
          color: Colors.white,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: Colors.white70,
        )
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Corrected: withOpacity -> withAlpha
        fillColor: surfaceColor.withAlpha((255 * 0.5).round()), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // Corrected: withOpacity -> withAlpha
          borderSide: BorderSide(color: primaryColor.withAlpha((255 * 0.3).round())), 
        ),
        enabledBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(8),
          // Corrected: withOpacity -> withAlpha
          borderSide: BorderSide(color: primaryColor.withAlpha((255 * 0.4).round())),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5), 
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle( // Added const
          fontFamily: 'Tajawal',
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle( // Added const
          fontFamily: 'Tajawal',
          color: Colors.grey[500], 
        ),
        // Corrected: withOpacity -> withAlpha
        prefixIconColor: primaryColor.withAlpha((255 * 0.7).round()),
        suffixIconColor: primaryColor.withAlpha((255 * 0.7).round()),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
      ),

      // Corrected: TabBarTheme -> TabBarThemeData
      tabBarTheme: const TabBarThemeData(
        labelColor: tertiaryColor, 
        unselectedLabelColor: Colors.white70, 
        indicatorColor: tertiaryColor, 
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w500, fontSize: 14),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey[300], 
        thickness: 0.8,
        space: 1, 
        indent: 16, 
        endIndent: 16, 
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tertiaryColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor, 
        linearTrackColor: Colors.grey, 
        linearMinHeight: 4.0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800], 
        contentTextStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white),
        actionTextColor: tertiaryColor,
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4.0,
      ),

      // Corrected: DialogTheme -> DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor,
        elevation: 8.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: const TextStyle(fontFamily: 'Tajawal', color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(fontFamily: 'Tajawal', color: textPrimaryColor, fontSize: 15, height: 1.4),
      ),
    );
  }
}
