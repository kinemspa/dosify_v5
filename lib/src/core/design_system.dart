/// ============================================================================
/// DOSIFI V5 - UNIVERSAL DESIGN SYSTEM
/// ============================================================================
///
/// This is the SINGLE SOURCE OF TRUTH for ALL styling in the entire app.
///
/// RULES:
/// 1. NEVER create inline styles in pages/widgets
/// 2. NEVER hardcode sizes, colors, fonts, spacing, opacity
/// 3. ALWAYS use constants and builders from this file
/// 4. ALWAYS import this file when creating UI
///
/// Modular sub-files (all re-exported below — importing design_system.dart
/// gives you everything):
///   design_tokens_spacing.dart   — spacing scale, page/card/field padding
///   design_tokens_opacity.dart   — opacity scale, shadow constants
///   design_tokens_radius.dart    — border widths and border radii
///   design_tokens_typography.dart — fonts, text styles, animations, alignment
///   design_builders.dart         — BoxDecoration / InputDecoration builders
///
/// ============================================================================

// Re-export all sub-modules so existing import 'design_system.dart' still works:
export 'package:dosifi_v5/src/core/design_tokens_spacing.dart';
export 'package:dosifi_v5/src/core/design_tokens_opacity.dart';
export 'package:dosifi_v5/src/core/design_tokens_radius.dart';
export 'package:dosifi_v5/src/core/design_tokens_typography.dart';
export 'package:dosifi_v5/src/core/design_builders.dart';
