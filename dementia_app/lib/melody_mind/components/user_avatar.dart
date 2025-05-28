import 'package:dementia_app/melody_mind/services/auth_service.dart';
import 'package:dementia_app/screens/melody_mind/analytics_screen.dart';
import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = Supabase.instance.client.auth.currentUser;
    final userAvatarUrl = user?.userMetadata?['avatar_url'];
    final userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@').first ??
        'User';

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'sign_out') {
          authService.signOut(context);
        } else if (value == 'analytics') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        }
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: AppColors.black.withOpacity(0.7),
      elevation: 8,
      itemBuilder: (context) => [
        // User info header
        PopupMenuItem<String>(
          enabled: false,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 1),

        //analytics option
        PopupMenuItem<String>(
          value: 'analytics',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Music Therapy Analytics',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ],
          ),
        ),

        //sign out option
        PopupMenuItem<String>(
          value: 'sign_out',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
          backgroundImage:
              userAvatarUrl != null ? NetworkImage(userAvatarUrl) : null,
          radius: 20,
          child: userAvatarUrl == null
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
