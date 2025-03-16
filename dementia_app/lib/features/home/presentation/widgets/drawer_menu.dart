import 'package:dementia_app/features/auth/presentation/providers/auth_service.dart';
import 'package:dementia_app/features/auth/presentation/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/providers/locale_provider.dart';  // Import generated localization files

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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.choose_language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(context)!.english),
                onTap: () {
                  Provider.of<LocaleProvider>(context, listen: false).changeLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.sinhala),
                onTap: () {
                  Provider.of<LocaleProvider>(context, listen: false).changeLocale(const Locale('si'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
                      : const AssetImage('assets/images/default_profile_pic.png') as ImageProvider,
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
            leading: const Icon(Icons.photo_album),
            title: const Text('Memories'),
            onTap: () {
              Navigator.pushNamed(context, '/memories');
            },
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              AppLocalizations.of(context)!.selected_language,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }
}
