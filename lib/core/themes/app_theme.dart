import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class AppTheme {
  static const double defaultBlurIntensity = 15.0;
  static const double defaultSurfaceOpacity = 0.1;
  static const double defaultBorderRadius = 24.0;

  static ThemeData lightTheme({
    Color? primaryColor,
    Color? secondaryColor,
    double blurIntensity = defaultBlurIntensity,
    double surfaceOpacity = defaultSurfaceOpacity,
    double borderRadius = defaultBorderRadius,
  }) {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: primaryColor ?? const Color(0xFF6366F1),
      secondary: secondaryColor ?? const Color(0xFF8B5CF6),
      surface: Colors.white.withOpacity(surfaceOpacity),
      background: const Color(0xFFF8FAFC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF0F172A),
      onBackground: const Color(0xFF0F172A),
    );

    return _baseTheme(colorScheme, blurIntensity, surfaceOpacity, borderRadius, Brightness.light);
  }

  static ThemeData darkTheme({
    Color? primaryColor,
    Color? secondaryColor,
    double blurIntensity = defaultBlurIntensity,
    double surfaceOpacity = defaultSurfaceOpacity,
    double borderRadius = defaultBorderRadius,
  }) {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: primaryColor ?? const Color(0xFF818CF8),
      secondary: secondaryColor ?? const Color(0xFFA78BFA),
      surface: const Color(0xFF1E293B).withOpacity(surfaceOpacity),
      background: const Color(0xFF0F172A),
      onPrimary: const Color(0xFF0F172A),
      onSecondary: const Color(0xFF0F172A),
      onSurface: const Color(0xFFF8FAFC),
      onBackground: const Color(0xFFF8FAFC),
    );

    return _baseTheme(colorScheme, blurIntensity, surfaceOpacity, borderRadius, Brightness.dark);
  }

  static ThemeData _baseTheme(
    ColorScheme colorScheme,
    double blurIntensity,
    double surfaceOpacity,
    double borderRadius,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground, size: 24),
        actionsIconTheme: IconThemeData(color: colorScheme.onBackground, size: 24),
      ),

      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius / 2),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.15),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        tickMarkShape: const RoundSliderTickMarkShape(),
        activeTickMarkColor: colorScheme.primary,
        inactiveTickMarkColor: colorScheme.primary.withOpacity(0.3),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        elevation: 0,
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurface.withOpacity(0.6), size: 24);
        }),
        height: 72,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.5),
        selectedColor: colorScheme.primary.withOpacity(0.2),
        disabledColor: colorScheme.onSurface.withOpacity(0.1),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        brightness: brightness,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.8),
          fontSize: 16,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        ),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        dragHandleColor: colorScheme.onSurface.withOpacity(0.3),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.15),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withOpacity(0.1),
        iconColor: colorScheme.onSurface.withOpacity(0.7),
        textColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 14,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withOpacity(0.2),
        circularTrackColor: colorScheme.primary.withOpacity(0.2),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary.withOpacity(0.3);
          return colorScheme.outline.withOpacity(0.3);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.3),
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
        textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(borderRadius / 4),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      extensions: [
        GlassmorphismTheme(
          blurIntensity: blurIntensity,
          surfaceOpacity: surfaceOpacity,
          borderRadius: borderRadius,
          borderColor: colorScheme.outline.withOpacity(0.15),
          shadowColor: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
          shadowBlurRadius: 20,
          shadowOffset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class GlassmorphismTheme extends ThemeExtension<GlassmorphismTheme> {
  final double blurIntensity;
  final double surfaceOpacity;
  final double borderRadius;
  final Color borderColor;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  const GlassmorphismTheme({
    required this.blurIntensity,
    required this.surfaceOpacity,
    required this.borderRadius,
    required this.borderColor,
    required this.shadowColor,
    required this.shadowBlurRadius,
    required this.shadowOffset,
  });

  @override
  GlassmorphismTheme copyWith({
    double? blurIntensity,
    double? surfaceOpacity,
    double? borderRadius,
    Color? borderColor,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return GlassmorphismTheme(
      blurIntensity: blurIntensity ?? this.blurIntensity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  @override
  GlassmorphismTheme lerp(ThemeExtension<GlassmorphismTheme>? other, double t) {
    if (other is! GlassmorphismTheme) return this;
    return GlassmorphismTheme(
      blurIntensity: lerpDouble(blurIntensity, other.blurIntensity, t)!,
      surfaceOpacity: lerpDouble(surfaceOpacity, other.surfaceOpacity, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shadowBlurRadius: lerpDouble(shadowBlurRadius, other.shadowBlurRadius, t)!,
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
    );
  }

  static GlassmorphismTheme? of(BuildContext context) {
    return Theme.of(context).extension<GlassmorphismTheme>();
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double? blurIntensity;
  final double? surfaceOpacity;
  final double? borderRadius;
  final Color? borderColor;
  final Color? surfaceColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blurIntensity,
    this.surfaceOpacity,
    this.borderRadius,
    this.borderColor,
    this.surfaceColor,
    this.boxShadow,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = GlassmorphismTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBlur = blurIntensity ?? glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = surfaceOpacity ?? glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = borderRadius ?? glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius;
    final effectiveBorderColor = borderColor ?? glassTheme?.borderColor ?? colorScheme.outline.withOpacity(0.15);
    final effectiveShadowColor = boxShadow?.first.color ?? glassTheme?.shadowColor ??
        (theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1));
    final effectiveShadowBlur = boxShadow?.first.blurRadius ?? glassTheme?.shadowBlurRadius ?? 20;
    final effectiveShadowOffset = boxShadow?.first.offset ?? glassTheme?.shadowOffset ?? const Offset(0, 10);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: effectiveShadowColor,
            blurRadius: effectiveShadowBlur,
            offset: effectiveShadowOffset,
          ),
        ],
        gradient: gradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor ?? colorScheme.surface.withOpacity(effectiveOpacity),
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      container = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: container,
        ),
      );
    }

    return container;
  }
}