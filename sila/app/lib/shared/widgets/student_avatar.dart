import 'dart:convert';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
// صورة التلميذ - تعمل في كل التطبيق
// ═══════════════════════════════════════════
class StudentAvatar extends StatelessWidget {
  final int studentId;
  final String fullName;
  final String? photoBase64;
  final double size;
  final double borderRadius;
  final VoidCallback? onTap;

  const StudentAvatar({
    super.key,
    required this.studentId,
    required this.fullName,
    this.photoBase64,
    this.size = 52,
    this.borderRadius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = _hasPhoto
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildImage(),
          )
        : _buildInitials(isDark);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }

  bool get _hasPhoto =>
      photoBase64 != null && photoBase64!.trim().isNotEmpty;

  Widget _buildImage() {
    try {
      final bytes = base64Decode(photoBase64!);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildInitials(false),
      );
    } catch (_) {
      return _buildInitials(false);
    }
  }

  Widget _buildInitials(bool isDark) {
    final initials = _getInitials(fullName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0];
  }
}

// ═══════════════════════════════════════════
// عرض الصورة من base64 أو null (للاستخدام في حالات خاصة)
// ═══════════════════════════════════════════
ImageProvider? base64ToImageProvider(String? base64Str) {
  if (base64Str == null || base64Str.trim().isEmpty) return null;
  try {
    return MemoryImage(base64Decode(base64Str));
  } catch (_) {
    return null;
  }
}