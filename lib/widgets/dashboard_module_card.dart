import 'package:flutter/material.dart';
import '../constants/colors.dart';

class DashboardModuleCard extends StatelessWidget {
  final String title;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final Widget? bottom;
  final VoidCallback? onTap;

  const DashboardModuleCard({
    super.key,
    required this.title,
    this.value,
    required this.icon,
    this.iconColor = AppColors.accentTeal,
    this.trailing,
    this.bottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    final bottomWidget = bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (value != null)
                  Text(
                    value!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                if (trailingWidget != null) trailingWidget,
                if (bottomWidget != null) ...[
                  const SizedBox(height: 8),
                  bottomWidget,
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
