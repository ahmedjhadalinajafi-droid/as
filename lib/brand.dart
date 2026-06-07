import 'package:flutter/material.dart';

/// Brand palette shared across the app.
const kBrandNavy = Color(0xFF1B3D6F);
const kBrandGold = Color(0xFFC9A843);

/// Brand accent color for **text and icons**.
///
/// Navy in light mode, gold in dark / night mode — so the deep blue text
/// that is hard to read on a dark background turns into the warm gold accent.
Color brandColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kBrandGold : kBrandNavy;
