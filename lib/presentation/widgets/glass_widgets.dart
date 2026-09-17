import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reproductor_musica/core/themes/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? surfaceColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final bool enableBlur;
  final bool enableAnimation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderColor,
    this.surfaceColor,
    this.boxShadow,
    this.gradient,
    this.borderRadius,
    this.enableBlur = false,
    this.enableAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = GlassmorphismTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveRadius = (borderRadius?.topLeft.x ?? glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius);
    final effectiveBlur = glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveBorderColor = borderColor ?? glassTheme?.borderColor ?? colorScheme.outline.withValues(alpha: 0.15);
    final effectiveShadowColor = boxShadow?.first.color ?? glassTheme?.shadowColor ??
        (theme.brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08));
    final effectiveShadowBlur = boxShadow?.first.blurRadius ?? glassTheme?.shadowBlurRadius ?? 16;
    final effectiveShadowOffset = boxShadow?.first.offset ?? glassTheme?.shadowOffset ?? const Offset(0, 6);

    final content = Container(
      decoration: BoxDecoration(
        color: surfaceColor ?? colorScheme.surface.withValues(alpha: effectiveOpacity),
        gradient: gradient,
      ),
      child: child,
    );

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
        child: enableBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: content,
              )
            : content,
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

    if (enableAnimation) {
      return container.animate().fadeIn(duration: 200.ms, curve: Curves.easeOut);
    }

    return container;
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final double height;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveBlur = glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;

    return Container(
      height: height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            color: backgroundColor ?? colorScheme.surface.withOpacity(effectiveOpacity),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (leading != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: leading,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: title ?? const SizedBox.shrink(),
                    ),
                  ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));
}

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final double height;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveBlur = glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = (glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius);

    return Container(
      height: height,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(effectiveOpacity),
              border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(effectiveRadius),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: items,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
              selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double trackHeight;

  const GlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.trackHeight = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: activeColor ?? colorScheme.primary,
        inactiveTrackColor: inactiveColor ?? colorScheme.primary.withOpacity(0.2),
        thumbColor: thumbColor ?? colorScheme.primary,
        overlayColor: (thumbColor ?? colorScheme.primary).withOpacity(0.15),
        valueIndicatorColor: thumbColor ?? colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        trackHeight: trackHeight,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }
}

class GlassProgressBar extends StatelessWidget {
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const GlassProgressBar({
    super.key,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.height = 4,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primary.withOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor ?? colorScheme.primary,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 200.ms)
        .scaleX(duration: 200.ms, curve: Curves.easeOut);
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = (borderRadius?.topLeft.x ?? glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius);

    Widget button = Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface.withOpacity(effectiveOpacity),
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
      ),
      child: Icon(icon, size: size, color: color ?? colorScheme.onSurface),
    );

    if (onPressed != null) {
      button = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: button,
        ),
      );
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final EdgeInsetsGeometry? contentPadding;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveBlur = glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(effectiveOpacity),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hintText,
              labelText: labelText,
              prefixIcon: prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: colorScheme.onSurface.withOpacity(0.7)),
                      child: prefixIcon!,
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: colorScheme.onSurface.withOpacity(0.7)),
                      child: suffixIcon!,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassModalSheet extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassModalSheet({
    super.key,
    required this.child,
    this.maxHeight,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveBlur = glassTheme?.blurIntensity ?? AppTheme.defaultBlurIntensity;
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = (borderRadius?.topLeft.x ?? glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius);

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(effectiveOpacity),
        borderRadius: BorderRadius.vertical(top: Radius.circular(effectiveRadius)),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
          left: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
          right: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(effectiveRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: child,
        ),
      ),
    ).animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? avatar;
  final Color? selectedColor;
  final Color? backgroundColor;

  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.avatar,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassTheme = GlassmorphismTheme.of(context);
    final effectiveOpacity = glassTheme?.surfaceOpacity ?? AppTheme.defaultSurfaceOpacity;
    final effectiveRadius = glassTheme?.borderRadius ?? AppTheme.defaultBorderRadius;

    final bgColor = selected
        ? (selectedColor ?? colorScheme.primary.withOpacity(0.2))
        : (backgroundColor ?? colorScheme.surface.withOpacity(effectiveOpacity));
    final textColor = selected ? colorScheme.primary : colorScheme.onSurface;
    final borderColor = selected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(effectiveRadius / 2),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[
            avatar!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chip = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius / 2),
          child: chip,
        ),
      );
    }

    return chip.animate()
        .fadeIn(duration: 200.ms)
        .scale(duration: 200.ms, curve: Curves.easeOut);
  }
}