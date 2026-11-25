import 'package:flutter/material.dart';
import '../app_sizes.dart';

/// "Słupek" aplikacji: na szerokich ekranach (tablet, desktop, web) treść ma szerokość
/// telefonu, wyśrodkowana na szarym tle. Owija cały Navigator (MaterialApp.router builder),
/// więc obejmuje wszystkie strony, Drawer i dialogi.
class AppFrame extends StatelessWidget {
  final Widget child;

  const AppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE0E0E0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxMobileWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            // ClipRect: bez tego Drawer rysowałby się poza "słupkiem" aplikacji na szerokim ekranie
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
