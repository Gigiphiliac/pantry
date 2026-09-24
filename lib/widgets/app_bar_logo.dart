import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable app bar logo widget displaying the Pantry brand mark.
///
/// Uses [flutter_svg] to render [logoAppbar.svg] with a theme-aware colour.
/// Replace [assetName] once the real SVG asset is ready.
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key, this.size = 32});

  /// Logo size in logical pixels. Defaults to 32.
  final double size;

  static const _assetName = 'assets/images/logo_appbar.svg';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          _assetName,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          fit: BoxFit.contain,
          semanticsLabel: 'Pantry',
        ),
      ),
    );
  }
}