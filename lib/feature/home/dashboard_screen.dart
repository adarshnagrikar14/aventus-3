import 'package:flutter/material.dart';
import 'package:hackathon/feature/chat/chat_bot.dart';
import 'package:hackathon/feature/food/home_food.dart';
import 'package:hackathon/feature/home/screens/home.dart';
import 'package:hackathon/feature/home/screens/exercise.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Placeholder widgets for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    Home(),
    HomeFood(),
    Exercise(),
    ChatBot(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbh Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Exercise',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_outlined),
            selectedIcon: Icon(Icons.assistant),
            label: 'AI Assistant',
          ),
        ],
        elevation: 4.0,
        backgroundColor: Colors.white,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
