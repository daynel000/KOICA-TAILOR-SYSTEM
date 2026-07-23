// widgets/toast_banner.dart
import 'package:flutter/material.dart';
import '../main.dart';

class ToastBanner extends StatelessWidget {
  final String message;
  const ToastBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryLight)),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3))),
        ]),
      ),
    );
  }
}
