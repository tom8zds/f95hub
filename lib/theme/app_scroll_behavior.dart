import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// App-wide scroll behavior that lets every scrollable (carousel, page views,
/// lists) be dragged with a mouse or trackpad, not just touch/stylus.
///
/// Flutter's default [MaterialScrollBehavior] only accepts touch-like pointers
/// for drag scrolling, which leaves desktop mouse users unable to swipe the
/// screenshot carousel or page between gallery images.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
