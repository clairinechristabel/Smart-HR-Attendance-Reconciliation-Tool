// lib/widgets/user_avatar.dart
import 'package:flutter/material.dart' hide Text;
import 'package:staff_portal/core/localization/localized_text.dart';
import '../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final String? role;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.initials,
    this.role,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ??
        (role != null ? AppTheme.roleColor(role!) : AppTheme.primaryGreen);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
