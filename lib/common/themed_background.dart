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
    // Expand the container to fill all available space. Without an explicit
    // constraint, a Container with a decoration sizes itself to its child,
    // which can result in the background not extending to the bottom of the
    // screen when the child is shorter than the viewport. By specifying
    // BoxConstraints.expand(), the container takes up the full dimensions
    // provided by its parent (typically the Scaffold body), ensuring the
    // background image covers the entire screen.
    return Container(
      constraints: const BoxConstraints.expand(),
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