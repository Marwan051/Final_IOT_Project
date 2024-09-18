import 'package:flutter/material.dart';
import 'package:flutter_client/services/firebase_service.dart';
import 'package:flutter_client/widgets/home_screen_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class MenuItem {
  final String location;
  final String title;
  final IconData icon;

  MenuItem({required this.location, required this.title, required this.icon});
}

final List<MenuItem> menuItems = [
  MenuItem(location: '/reading', title: 'Read Data', icon: Icons.sensors),
  MenuItem(location: '/writing', title: 'Write test', icon: Icons.edit),
];

class HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _firebaseService.signOut();
              if (mounted) {
                navigator.pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: menuItems
              .map(
                (element) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: HomeScreenWidget(
                      location: element.location,
                      title: element.title,
                      icon: element.icon),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
