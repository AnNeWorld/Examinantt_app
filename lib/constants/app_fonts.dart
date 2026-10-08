import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ============================================================================
/// APP FONTS & TYPOGRAPHY LIBRARY
/// ============================================================================
/// Centralized font family constants, font weights, design system typography,
/// and fluent style extensions for Examinantt App.
/// ============================================================================

/// Font Families used across the app
class AppFonts {
  AppFonts._();

  /// Primary font bundled locally in assets for instant 0-latency offline rendering
  static const String poppins = 'Poppins';

  /// Default application font family
  static const String primaryFont = poppins;

  /// Google Fonts fallbacks/options if needed dynamically
  static TextStyle googlePoppins({TextStyle? baseStyle}) =>
      GoogleFonts.poppins(textStyle: baseStyle);

  static TextStyle googlePlusJakartaSans({TextStyle? baseStyle}) =>
      GoogleFonts.plusJakartaSans(textStyle: baseStyle);

  static TextStyle googleInter({TextStyle? baseStyle}) =>
      GoogleFonts.inter(textStyle: baseStyle);
}

/// Standardized Font Weights
class AppFontWeights {
  AppFontWeights._();

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// Standard App Typography & Text Styles Presets
class AppTextStyles {
  AppTextStyles._();

  static const String _family = AppFonts.primaryFont;

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // DISPLAY STYLES (Hero numbers, large banners, splash headers)
  // ---------------------------------------------------------------------------
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: AppFontWeights.bold,
    color: AppColors.text,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: AppFontWeights.bold,
    color: AppColors.text,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: AppFontWeights.bold,
    color: AppColors.text,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ---------------------------------------------------------------------------
  // HEADLINE STYLES (Page titles, section headers)
  // ---------------------------------------------------------------------------
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: AppFontWeights.bold,
    color: AppColors.text,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.text,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.text,
    letterSpacing: -0.1,
    height: 1.35,
  );

  // ---------------------------------------------------------------------------
  // TITLE STYLES (Card headers, list item titles, dialog headers)
  // ---------------------------------------------------------------------------
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.text,
    letterSpacing: 0.0,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.text,
    letterSpacing: 0.0,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.text,
    letterSpacing: 0.0,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // BODY STYLES (General readable content, paragraphs, descriptions)
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: AppFontWeights.regular,
    color: AppColors.text,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeights.regular,
    color: AppColors.textLight,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: AppFontWeights.regular,
    color: AppColors.textLight,
    letterSpacing: 0.1,
    height: 1.45,
  );

  // ---------------------------------------------------------------------------
  // BUTTON / INTERACTIVE STYLES
  // ---------------------------------------------------------------------------
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.white,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.white,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.white,
    letterSpacing: 0.15,
    height: 1.2,
  );

  // ---------------------------------------------------------------------------
  // CAPTION & LABEL STYLES (Tags, badges, timestamp, input hint)
  // ---------------------------------------------------------------------------
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: AppFontWeights.regular,
    color: AppColors.textLight,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.textLight,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: AppFontWeights.semiBold,
    color: AppColors.textLight,
    letterSpacing: 1.2,
    height: 1.4,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeights.regular,
    color: AppColors.greyMedium,
    letterSpacing: 0.1,
  );

  // ---------------------------------------------------------------------------
  // THEME DATA TEXT THEMES (For Material 3 ThemeData integration)
  // ---------------------------------------------------------------------------
  static TextTheme get lightTextTheme => const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: buttonLarge,
        labelMedium: buttonMedium,
        labelSmall: caption,
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.textDark),
        displayMedium: displayMedium.copyWith(color: AppColors.textDark),
        displaySmall: displaySmall.copyWith(color: AppColors.textDark),
        headlineLarge: headlineLarge.copyWith(color: AppColors.textDark),
        headlineMedium: headlineMedium.copyWith(color: AppColors.textDark),
        headlineSmall: headlineSmall.copyWith(color: AppColors.textDark),
        titleLarge: titleLarge.copyWith(color: AppColors.textDark),
        titleMedium: titleMedium.copyWith(color: AppColors.textDark),
        titleSmall: titleSmall.copyWith(color: AppColors.textDark),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textDark),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textDarkSecondary),
        bodySmall: bodySmall.copyWith(color: AppColors.textDarkSecondary),
        labelLarge: buttonLarge.copyWith(color: AppColors.primary),
        labelMedium: buttonMedium.copyWith(color: AppColors.primary),
        labelSmall: caption.copyWith(color: AppColors.textDarkSecondary),
      );
}

/// ============================================================================
/// FLUENT TEXTSTYLE EXTENSIONS
/// ============================================================================
/// Allows quick and readable chaining:
/// e.g. `AppTextStyles.headlineMedium.primary.bold`
/// e.g. `AppTextStyles.bodyMedium.withColor(Colors.green).semiBold`
/// ============================================================================
extension TextStyleExtensions on TextStyle {
  // --- Weight shortcuts ---
  TextStyle get light => copyWith(fontWeight: AppFontWeights.light);
  TextStyle get regular => copyWith(fontWeight: AppFontWeights.regular);
  TextStyle get medium => copyWith(fontWeight: AppFontWeights.medium);
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeights.semiBold);
  TextStyle get bold => copyWith(fontWeight: AppFontWeights.bold);
  TextStyle get extraBold => copyWith(fontWeight: AppFontWeights.extraBold);

  // --- Size shortcut ---
  TextStyle size(double fontSize) => copyWith(fontSize: fontSize);

  // --- Color shortcuts ---
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle get white => copyWith(color: AppColors.white);
  TextStyle get primary => copyWith(color: AppColors.primary);
  TextStyle get accent => copyWith(color: AppColors.accent);
  TextStyle get darkText => copyWith(color: AppColors.text);
  TextStyle get secondary => copyWith(color: AppColors.textLight);
  TextStyle get lightText => copyWith(color: AppColors.textDark);
  TextStyle get lightSecondary => copyWith(color: AppColors.textDarkSecondary);
  TextStyle get success => copyWith(color: AppColors.success);
  TextStyle get error => copyWith(color: AppColors.error);
  TextStyle get warning => copyWith(color: AppColors.warning);

  // --- Styling & Spacing shortcuts ---
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
  TextStyle lineHeight(double height) => copyWith(height: height);
  TextStyle letterSpace(double spacing) => copyWith(letterSpacing: spacing);
  TextStyle get tight => copyWith(letterSpacing: -0.4);
  TextStyle get loose => copyWith(letterSpacing: 0.5);
  TextStyle get relaxed => copyWith(height: 1.6);
  TextStyle get compact => copyWith(height: 1.2);
}

/// ============================================================================
/// CONTEXT EXTENSIONS FOR QUICK ACCESS
/// ============================================================================
/// Easy access directly from `context`:
/// e.g. `context.typography.titleLarge` or `context.isDarkMode`
/// ============================================================================
extension TypographyContextExtension on BuildContext {
  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Quick access to theme TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to headlineLarge matching current theme
  TextStyle get headlineLarge =>
      isDarkMode ? AppTextStyles.headlineLarge.lightText : AppTextStyles.headlineLarge;

  /// Quick access to headlineMedium matching current theme
  TextStyle get headlineMedium =>
      isDarkMode ? AppTextStyles.headlineMedium.lightText : AppTextStyles.headlineMedium;

  /// Quick access to titleLarge matching current theme
  TextStyle get titleLarge =>
      isDarkMode ? AppTextStyles.titleLarge.lightText : AppTextStyles.titleLarge;

  /// Quick access to titleMedium matching current theme
  TextStyle get titleMedium =>
      isDarkMode ? AppTextStyles.titleMedium.lightText : AppTextStyles.titleMedium;

  /// Quick access to titleSmall matching current theme
  TextStyle get titleSmall =>
      isDarkMode ? AppTextStyles.titleSmall.lightText : AppTextStyles.titleSmall;

  /// Quick access to bodyLarge matching current theme
  TextStyle get bodyLarge =>
      isDarkMode ? AppTextStyles.bodyLarge.lightText : AppTextStyles.bodyLarge;

  /// Quick access to bodyMedium matching current theme
  TextStyle get bodyMedium =>
      isDarkMode ? AppTextStyles.bodyMedium.lightSecondary : AppTextStyles.bodyMedium;

  /// Quick access to bodySmall matching current theme
  TextStyle get bodySmall =>
      isDarkMode ? AppTextStyles.bodySmall.lightSecondary : AppTextStyles.bodySmall;

  /// Quick access to standard spacings
  EdgeInsets get screenPadding => AppSpacing.screenPadding;
  EdgeInsets get cardPadding => AppSpacing.cardPadding;
}

/// ============================================================================
/// STANDARD APP SPACING & INSETS SYSTEM
/// ============================================================================
/// Uniform 4pt/8pt grid spacing constants, SizedBox gap helpers,
/// padding presets, and border radii.
/// ============================================================================
class AppSpacing {
  AppSpacing._();

  // Basic spacing scale units (in pixels)
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // Vertical Spacers (SizedBox height)
  static const SizedBox verticalXxs = SizedBox(height: xxs);
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalS = SizedBox(height: s);
  static const SizedBox verticalM = SizedBox(height: m);
  static const SizedBox verticalL = SizedBox(height: l);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);
  static const SizedBox verticalXxxl = SizedBox(height: xxxl);
  static const SizedBox verticalHuge = SizedBox(height: huge);

  // Horizontal Spacers (SizedBox width)
  static const SizedBox horizontalXxs = SizedBox(width: xxs);
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalS = SizedBox(width: s);
  static const SizedBox horizontalM = SizedBox(width: m);
  static const SizedBox horizontalL = SizedBox(width: l);
  static const SizedBox horizontalXl = SizedBox(width: xl);
  static const SizedBox horizontalXxl = SizedBox(width: xxl);
  static const SizedBox horizontalXxxl = SizedBox(width: xxxl);

  // Screen & Component Padding Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0);

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius roundedM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius roundedL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));
}

