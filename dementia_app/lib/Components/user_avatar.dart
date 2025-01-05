import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/auth_service.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = Supabase.instance.client.auth.currentUser;
    final userAvatarUrl = user?.userMetadata?['avatar_url'];
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'sign_out') {
          authService.signOut(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'sign_out',
          height: 20,
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Color.fromARGB(255, 250, 98, 98)),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(color: Color.fromARGB(255, 250, 98, 98)),
              ),
            ],
          ),
        ),
      ],
      offset: const Offset(0, 50),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: userAvatarUrl != null 
              ? NetworkImage(userAvatarUrl) 
              : null,
          child: userAvatarUrl == null
              ? const Icon(Icons.person, color: Colors.blue)
              : null,
        ),
      ),
    );
  }
}