import 'package:dementia_app/features/auth/presentation/providers/auth_service.dart';
import 'package:dementia_app/features/auth/presentation/screens/login.dart';
import 'package:flutter/material.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  DrawerMenuState createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPhotoUrl = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    var user = await AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        userName = "${user.firstName} ${user.lastName}";
        userEmail = user.email;
        userPhotoUrl = "";
      });
    }
  }

  Future<void> _logOut() async {
    await AuthService().logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return LoginPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : const NetworkImage(
                          'https://www.gravatar.com/avatar/2c7d99fe281ecd3bcd65ab915bac6dd5?s=250'),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: _logOut,
          ),
        ],
      ),
    );
  }
}
