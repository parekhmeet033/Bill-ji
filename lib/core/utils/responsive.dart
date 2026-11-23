import 'package:flutter/material.dart';

/// Lightweight device/orientation detection used ONLY to adjust grid
/// layouts (column count / card aspect ratio) so cards don't end up with
/// large empty space on tablets. Phones always get `isTablet == false`,
/// so phone layouts are completely untouched by any of this.
class Responsive {
  Responsive._();

  /// Same 600dp "shortest side" breakpoint Material uses to distinguish
  /// phones from tablets — kept in sync with the design-size breakpoint
  /// used for ScreenUtil in main.dart.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }
}
