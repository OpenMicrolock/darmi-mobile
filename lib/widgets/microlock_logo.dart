import 'package:flutter/material.dart';

import '../branding.dart';

class MicrolockLogo extends StatelessWidget {
  const MicrolockLogo({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      appLogoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: appName,
    );
  }
}
