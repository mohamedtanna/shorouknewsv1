import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onMorePressed;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.tertiaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            if (onMorePressed != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: InkWell(
                  onTap: onMorePressed,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'المزيد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
