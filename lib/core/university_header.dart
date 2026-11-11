import 'package:flutter/material.dart';

import 'app_config.dart';

class UniversityHeader extends StatelessWidget {
  final double logoSize;
  final bool light;
  final bool showLogo;

  const UniversityHeader({
    super.key,
    this.logoSize = 80,
    this.light = false,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo)
          Image.asset(
            'assets/images/university.png',
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Icon(
              Icons.account_balance,
              size: logoSize * 0.8,
              color: light ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
          ),
        if (showLogo) const SizedBox(height: 10),
        Text(
          AppConfig.universityName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}