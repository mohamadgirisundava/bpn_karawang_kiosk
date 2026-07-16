import 'package:flutter/material.dart';

/// Helper class untuk responsive sizing pada layar kiosk 7 inch.
/// Base design: 600px width (portrait 7 inch tablet).
class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _scaleFactor;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    // Clamp scale: minimum 1.0 (jangan perkecil), scale up kalau layar lebih besar dari 600
    _scaleFactor = (_screenWidth / 600).clamp(0.85, 1.5);
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get scaleFactor => _scaleFactor;

  /// Scale font size
  static double sp(double size) => size * _scaleFactor;

  /// Scale width/horizontal padding
  static double w(double size) => size * _scaleFactor;

  /// Scale height/vertical padding
  static double h(double size) => size * (_screenHeight / 1024);

  /// Scale radius
  static double r(double size) => size * _scaleFactor;

  /// Is landscape orientation
  static bool get isLandscape => _screenWidth > _screenHeight;

  /// Grid columns based on width
  static int get gridColumns {
    if (_screenWidth > 900) return 3;
    if (_screenWidth > 500) return 2;
    return 1;
  }
}
