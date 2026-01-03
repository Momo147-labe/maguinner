import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/animated_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/products_content.dart';
import '../widgets/clients_content.dart';
import '../widgets/suppliers_content.dart';
import '../widgets/sales_content.dart';
import '../widgets/purchases_content.dart';
import '../widgets/inventory_content.dart';
import '../widgets/reports_content.dart';
import '../widgets/users_content.dart';
import '../widgets/store_content.dart';
import '../models/user.dart';
import '../models/store_info.dart';
import '../core/database/database_helper.dart';

/// Layout principal SPA Desktop
class MainLayout extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final String initialRoute;

  const MainLayout({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.initialRoute = '/dashboard',
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  String _currentRoute = '/dashboard';
  late AnimationController _sidebarController;
  late Timer _clockTimer;
  String _currentTime = '';
  StoreInfo? _storeInfo;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _startClock();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadStoreInfo() async {
    try {
      final storeInfo = await DatabaseHelper.instance.getStoreInfo();
      if (mounted) {
        setState(() => _storeInfo = storeInfo);
      }
    } catch (e) {
      // Ignore errors for store info loading
    }
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _onNavigate(String route) {
    if (route == '/login') {
      Navigator.of(context).pushReplacementNamed(route);
    } else if (route == '/users' && widget.currentUser.role?.toLowerCase() != 'admin') {
      // Empêcher l'accès aux utilisateurs pour les non-admins
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès refusé: Réservé aux administrateurs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  Widget _buildContent() {
    switch (_currentRoute) {
      case '/dashboard':
        return DashboardContent(currentUser: widget.currentUser);
      case '/products':
        return ProductsContent(currentUser: widget.currentUser);
      case '/clients':
        return ClientsContent(currentUser: widget.currentUser);
      case '/suppliers':
        return SuppliersContent(currentUser: widget.currentUser);
      case '/sales':
        return SalesContent(currentUser: widget.currentUser);
      case '/purchases':
        return PurchasesContent(currentUser: widget.currentUser);
      case '/inventory':
        return InventoryContent(currentUser: widget.currentUser);
      case '/reports':
        return ReportsContent(currentUser: widget.currentUser);
      case '/store':
        return StoreContent(currentUser: widget.currentUser);
      case '/users':
        // Vérifier les permissions admin
        if (widget.currentUser.role?.toLowerCase() == 'admin') {
          return UsersContent(currentUser: widget.currentUser);
        } else {
          return _buildAccessDenied();
        }
      default:
        return DashboardContent(currentUser: widget.currentUser);
    }
  }

  @override
  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Accès Refusé',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette section est réservée aux administrateurs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar animée
          AnimatedSidebar(
            currentRoute: _currentRoute,
            onNavigate: _onNavigate,
            currentTime: _currentTime,
            controller: _sidebarController,
            storeInfo: _storeInfo,
            currentUser: widget.currentUser,
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Header fixe
                AppHeader(
                  userName: widget.currentUser.fullName ?? widget.currentUser.username,
                  isDarkMode: widget.isDarkMode,
                  onThemeToggle: widget.onThemeToggle,
                ),
                
                // Contenu dynamique
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_currentRoute),
                      child: _buildContent(),
                    ),
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