// ============================================================
// screens/main_shell.dart
//
// The root screen that holds the bottom navigation bar and
// manages which tab is currently visible.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'orders_screen.dart';
import 'ai_scan_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../widgets/toast_banner.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;

  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    // Load data once when the app shell is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInitialData();
    });
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _navigateToTab(int tabIndex) {
    setState(() => _currentTabIndex = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Active tab content
          IndexedStack(
            index: _currentTabIndex,
            children: [
              HomeScreen(
                onNavigateToTab: _navigateToTab,
                onShowToast: _showToast,
              ),
              MapScreen(
                onNavigateToTab: _navigateToTab,
                onShowToast: _showToast,
              ),
              OrdersScreen(
                onNavigateToTab: _navigateToTab,
                onShowToast: _showToast,
              ),
              AIScanScreen(
                onNavigateToTab: _navigateToTab,
                onShowToast: _showToast,
                isActive: _currentTabIndex == 3,
              ),
              ChatScreen(
                onNavigateToTab: _navigateToTab,
              ),
              ProfileScreen(
                onNavigateToTab: _navigateToTab,
              ),
            ],
          ),

          // Toast notification banner (appears above all content)
          if (_toastMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: ToastBanner(message: _toastMessage!),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(provider),
    );
  }



  Widget _buildBottomNavBar(AppProvider provider) {
    final tabs = [
      _NavTab(icon: Icons.home_rounded, label: 'Home'),
      _NavTab(icon: Icons.map_rounded, label: 'Map'),
      _NavTab(icon: Icons.content_cut_rounded, label: 'Orders'),
      _NavTab(icon: Icons.document_scanner_rounded, label: 'AI Scan'),
      _NavTab(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat',
        badgeCount: provider.unreadMessageCount,
      ),
      _NavTab(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isActive = _currentTabIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToTab(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              tab.icon,
                              size: 22,
                              color: isActive
                                  ? AppColors.primaryLight
                                  : AppColors.textMuted,
                            ),
                            if (tab.badgeCount != null && tab.badgeCount! > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.primaryLight
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: isActive ? 20 : 0,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final int? badgeCount;

  const _NavTab({required this.icon, required this.label, this.badgeCount});
}
