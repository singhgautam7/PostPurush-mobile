import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one colour Android hands over from the wallpaper.
///
/// Only its hue is used: every other role is derived exactly as a bundled
/// family's is, with chroma pinned, so a wallpaper scheme sits in the same
/// register as PostPurush's own. Read once and cached by Riverpod, so the
/// platform channel is not touched again on a rebuild.
final FutureProvider<Color?> wallpaperSeedProvider = FutureProvider<Color?>(
  (Ref ref) async {
    // The accent is enough: only the hue is read, and every other role is
    // derived from it exactly as a bundled family's is.
    return DynamicColorPlugin.getAccentColor();
  },
);
