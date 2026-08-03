import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/colors.dart';

class PermissionCard extends StatelessWidget {
  final String name;
  final PermissionStatus? status;
  final String description;
  final IconData icon;
  final VoidCallback? onRequest;

  const PermissionCard({
    super.key,
    required this.name,
    required this.status,
    required this.description,
    required this.icon,
    required this.onRequest,
  });

  Color _getStatusColor(PermissionStatus? status) {
    if (status == null) return Colors.grey;
    if (status.isGranted) return Colors.greenAccent;
    if (status.isDenied) return Colors.orangeAccent;
    if (status.isPermanentlyDenied) return Colors.redAccent;
    return Colors.amberAccent;
  }

  String _getStatusText(PermissionStatus? status) {
    if (status == null) return 'Checking...';
    if (status.isGranted) return 'Granted';
    if (status.isDenied) return 'Denied';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    if (status.isRestricted) return 'Restricted';
    if (status.isLimited) return 'Limited';
    return 'Unknown';
  }

  IconData _getStatusIcon(PermissionStatus? status) {
    if (status == null) return Icons.hourglass_empty;
    if (status.isGranted) return Icons.check_circle_rounded;
    if (status.isDenied) return Icons.warning_rounded;
    if (status.isPermanentlyDenied) return Icons.cancel_rounded;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final isGranted = status?.isGranted == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentTeal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${_getStatusText(status)}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGranted
                            ? Colors.white12
                            : Colors.teal.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isGranted ? null : onRequest,
                      child: Text(
                        isGranted
                            ? 'Granted'
                            : status?.isPermanentlyDenied == true
                                ? 'Configure'
                                : 'Request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGranted ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
