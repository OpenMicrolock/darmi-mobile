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
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFF2E7D4F), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: height * 0.2,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
