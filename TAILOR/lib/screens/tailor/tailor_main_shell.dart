import 'package:flutter/material.dart';
import '../../theme/tailor_theme.dart';
import 'tailor_home_screen.dart';
import 'tailor_orders_screen.dart';
import 'tailor_map_screen.dart';
import 'tailor_chat_screen.dart';
import 'tailor_profile_screen.dart';

class TailorMainShell extends StatefulWidget {
  const TailorMainShell({super.key});

  @override
  State<TailorMainShell> createState() => _TailorMainShellState();
}

class _TailorMainShellState extends State<TailorMainShell> {
  int _currentTabIndex = 0;

  final List<Widget> _appScreens = [
    const TailorHomeScreen(),
    const TailorOrdersScreen(),
    const TailorMapScreen(),
    const TailorChatScreen(),
    const TailorProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: TailorTheme.darkTheme,
      child: Scaffold(
        backgroundColor: TailorTheme.darkBackground,
        body: IndexedStack(
          index: _currentTabIndex,
          children: _appScreens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFFD49228),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

