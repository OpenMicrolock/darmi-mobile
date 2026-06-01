import 'package:flutter/material.dart';

/// Centralized color palette for the Microlock design system.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const primary = Color(0xFF1B5E3B);
  static const primaryLight = Color(0xFF2E7D4F);
  static const primaryDark = Color(0xFF0F3D25);

  // ── Accent ─────────────────────────────────────────────
  static const amber = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFBF47);
  static const amberDark = Color(0xFFD48E1A);

  // ── Surfaces (dark theme) ──────────────────────────────
  static const backgroundDark = Color(0xFF0D1B12);
  static const surfaceDark = Color(0xFF142A1B);
  static const surfaceContainerDark = Color(0xFF1A3324);
  static const surfaceContainerHighDark = Color(0xFF213D2C);
  static const cardDark = Color(0xFF1A3324);

  // ── Surfaces (light theme fallback) ────────────────────
  static const backgroundLight = Color(0xFFF4F7F5);
  static const surfaceLight = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────
  static const textPrimary = Color(0xFFE8F0EB);
  static const textSecondary = Color(0xFFA3B8AB);
  static const textMuted = Color(0xFF6B7F72);

  // ── Lock state ─────────────────────────────────────────
  static const locked = Color(0xFF2E7D4F);
  static const unlocked = Color(0xFFC62828);
  static const unlockedLight = Color(0xFFEF5350);

  // ── Lamp state ─────────────────────────────────────────
  static const lampOn = amber;
  static const lampOff = textMuted;

  // ── Connection status ──────────────────────────────────
  static const connectionActive = Color(0xFF4CAF50);
  static const connectionInactive = Color(0xFFEF5350);
  static const connectionError = Color(0xFFFF9800);
  static const connectionUnknown = textMuted;

  // ── Semantic ───────────────────────────────────────────
  static const error = Color(0xFFD32F2F);
  static const errorContainer = Color(0xFF3D1616);
  static const success = Color(0xFF2E7D32);
  static const successContainer = Color(0xFF1A3D1C);
  static const warning = Color(0xFFFF9800);

  // ── Outline / Border ───────────────────────────────────
  static const outline = Color(0xFF2D4A36);
  static const outlineVariant = Color(0xFF1F3628);

  // ── Overlay ────────────────────────────────────────────
  static const scrim = Color(0x99000000);

  /// Convenience: connection status to color.
  static Color connectionColor(String status) {
    return switch (status) {
      'active' => connectionActive,
      'inactive' => connectionInactive,
      'error' => connectionError,
      _ => connectionUnknown,
    };
  }
}
