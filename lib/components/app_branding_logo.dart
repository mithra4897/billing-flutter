import 'package:flutter/material.dart';

import '../app/constants/app_config.dart';
import '../model/app/public_branding_model.dart';

class AppBrandingLogo extends StatelessWidget {
  const AppBrandingLogo({
    super.key,
    required this.branding,
    this.size = 44,
    this.showName = true,
    this.textColor,
  });

  final PublicBrandingModel branding;
  final double size;
  final bool showName;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final logoPath = branding.logoPath;
    final color = textColor ?? const Color(0xFF0A2540);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(logoPath, color),
        if (showName) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              branding.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogo(String? logoPath, Color color) {
    final imageUrl = AppConfig.resolvePublicFileUrl(logoPath);

    if (imageUrl == null) {
      return Icon(Icons.business, size: size, color: color);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.business, size: size, color: color),
      ),
    );
  }
}
