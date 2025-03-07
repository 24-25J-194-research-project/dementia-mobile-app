import 'package:flutter/material.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../widgets/drawer_menu.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}


class HomeScreenState extends State<HomeScreen> {
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() async {
    var user = await AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        userName = user.lastName;
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${getGreeting()}, $userName!',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(size: 36, color: Colors.black),
      ),
      drawer: const DrawerMenu(),
      body: const Center(
        child: Text(
          'Welcome to Memory Bloom!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
