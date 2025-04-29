import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/dashboard_content.dart';
import 'package:e_commerce_app/widgets/Admin/Drawer/admin_sidebar.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/dashboard_header.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/dashboard_stats_row.dart';

class AdminDesktop extends StatefulWidget {
  const AdminDesktop({super.key});

  @override
  State<AdminDesktop> createState() => _AdminDesktopState();
}

class _AdminDesktopState extends State<AdminDesktop> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentPage = 'Dashboard';

  void _navigateToPage(String pageName) {
    setState(() {
      _currentPage = pageName;
    });

    // Close drawer if open (on mobile/tablet)
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;
    final isTablet = screenWidth > 650 && screenWidth <= 1100;
    final isMobile = screenWidth <= 650;

    Widget mainContent;

    // Determine which content to show based on selected page
    switch (_currentPage) {
      case 'Dashboard':
        mainContent = const DashboardContent();
        break;
      // Other cases will be added as they're implemented
      default:
        mainContent = const Center(child: Text('Content not implemented yet'));
    }

    return Scaffold(
      key: _scaffoldKey,
      // Show drawer for mobile and tablet
      drawer: isDesktop
          ? null
          : AdminSidebar(
              currentPage: _currentPage,
              onPageSelected: _navigateToPage,
              isMobile: isMobile,
            ),
      body: Row(
        children: [
          // Show sidebar for desktop
          if (isDesktop)
            AdminSidebar(
              currentPage: _currentPage,
              onPageSelected: _navigateToPage,
              isMobile: false,
            ),

          // Main content area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with optional drawer button
                DashboardHeader(
                  title: _currentPage,
                  onMenuTap: isDesktop
                      ? null
                      : () => _scaffoldKey.currentState?.openDrawer(),
                  isMobile: isMobile,
                ),

                // Stats row
                const DashboardStatsRow(),

                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: mainContent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
