import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: connectivityService,
      builder: (context, _) {
        if (connectivityService.isOnline) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade700,
          child: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أنت بدون إنترنت — تُعرض بيانات محفوظة محلياً',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}