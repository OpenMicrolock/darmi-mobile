import 'package:flutter/material.dart';

import '../branding.dart';

class MicrolockLogo extends StatelessWidget {
  const MicrolockLogo({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * 1.83,
      decoration: const BoxDecoration(
        color: Color(0xFF10140F),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Image.asset(
        appLogoAsset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: appName,
      ),
    );
  }
}
