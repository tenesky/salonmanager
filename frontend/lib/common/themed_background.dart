import 'package:flutter/material.dart';

/// A wrapper widget that paints a patterned background image depending on the
/// current theme (light or dark).  It should be used for screens that
/// appear after the login process.  The image assets must be declared in
/// `pubspec.yaml` under the `assets` section.
class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Choose the appropriate background asset based on the current theme.
    final String imagePath = brightness == Brightness.dark
        ? 'assets/background_dark.png'
        : 'assets/background_light.png';
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}