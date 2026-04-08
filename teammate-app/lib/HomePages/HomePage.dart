import 'package:flutter/material.dart';
import 'ProfileWidget.dart';
import 'AIScorePage.dart';
import 'MateListPage.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Map<String, dynamic> _user;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _widgetOptions = <Widget>[
      const AIScorePage(),
      const MateListPage(),
      ProfileWidget(user: _user, onProfileUpdated: _updateUser),
    ];
  }

  void _updateUser(Map<String, dynamic> newUser) {
    setState(() {
      _user = newUser;
      _widgetOptions[2] = ProfileWidget(user: _user, onProfileUpdated: _updateUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Mates'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}