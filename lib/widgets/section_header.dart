import 'package:flutter/material.dart';
import '../core/theme.dart'; // For consistent app styling

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle; // Optional subtitle
  final IconData? icon; // Optional icon to display before the title
  final VoidCallback? onMorePressed; // Callback when "More" button is pressed
  final String moreText; // Text for the "More" button, defaults to "المزيد"
  final Color titleColor;
  final Color iconColor;
  final Color moreTextColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onMorePressed,
    this.moreText = 'المزيد', // Default "More" text in Arabic
    this.titleColor = AppTheme.primaryColor,
    this.iconColor = AppTheme.primaryColor,
    this.moreTextColor = AppTheme.tertiaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Icon and Title/Subtitle
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 22), // Icon size
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17, // Slightly larger for section titles
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis, // Handle long titles
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side: "More" button (if callback is provided)
          if (onMorePressed != null)
            TextButton(
              onPressed: onMorePressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero, // To make the button compact
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Compact tap area
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moreText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: moreTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios, // Standard "more" icon
                    size: 14,
                    color: moreTextColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
