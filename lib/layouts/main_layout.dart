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
import '../screens/invoices_screen.dart';
import '../models/user.dart';
import '../models/store_info.dart';
import '../core/database/database_helper.dart';
import '../widgets/alerts_widget.dart';
import '../widgets/calculator_dialog.dart';

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
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _onNavigate(String route) {
    if (route == '/login') {
      Navigator.of(context).pushReplacementNamed(route);
    } else if (route == '/users' &&
        widget.currentUser.role?.toLowerCase() != 'admin') {
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
      case '/invoices':
        return InvoicesScreen(currentUser: widget.currentUser);
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
          Icon(Icons.lock, size: 64, color: Colors.red.shade400),
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: isMobile ? _buildMobileAppBar() : null,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(_getPageTitle(_currentRoute)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        const AlertsWidget(iconColor: Colors.white),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CalculatorDialog(),
            );
          },
          icon: const Icon(Icons.calculate),
          tooltip: 'Calculatrice',
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
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
                userName:
                    widget.currentUser.fullName ?? widget.currentUser.username,
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
    );
  }

  Widget _buildMobileLayout() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentRoute),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).cardTheme.color,
      child: Column(
        children: [
          // Header du drawer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        (widget.currentUser.fullName ??
                                widget.currentUser.username)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentUser.fullName ??
                                widget.currentUser.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.currentUser.role ?? 'Utilisateur',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_storeInfo?.name != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _storeInfo!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildMobileMenuItem(
                  Icons.dashboard,
                  'Dashboard',
                  '/dashboard',
                ),
                _buildMobileMenuItem(Icons.inventory, 'Produits', '/products'),
                _buildMobileMenuItem(
                  Icons.people_outline,
                  'Clients',
                  '/clients',
                ),
                _buildMobileMenuItem(
                  Icons.business,
                  'Fournisseurs',
                  '/suppliers',
                ),
                _buildMobileMenuItem(Icons.shopping_cart, 'Ventes', '/sales'),
                _buildMobileMenuItem(
                  Icons.shopping_bag,
                  'Achats',
                  '/purchases',
                ),
                _buildMobileMenuItem(
                  Icons.warehouse,
                  'Inventaire',
                  '/inventory',
                ),
                _buildMobileMenuItem(Icons.assessment, 'Rapports', '/reports'),
                _buildMobileMenuItem(Icons.receipt_long, 'Factures', '/invoices'),
                _buildMobileMenuItem(
                  Icons.store_mall_directory,
                  'Mon magasin',
                  '/store',
                ),
                if (widget.currentUser.role?.toLowerCase() == 'admin')
                  _buildMobileMenuItem(Icons.people, 'Utilisateurs', '/users'),
                const Divider(height: 32),
                _buildMobileMenuItem(
                  Icons.logout,
                  'Déconnexion',
                  '/login',
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuItem(
    IconData icon,
    String title,
    String route, {
    bool isLogout = false,
  }) {
    final isSelected = _currentRoute == route;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : isLogout
              ? Colors.red
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? colorScheme.primary
                : isLogout
                ? Colors.red
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.of(context).pop(); // Fermer le drawer
          _onNavigate(route);
        },
      ),
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case '/dashboard':
        return 'Dashboard';
      case '/products':
        return 'Produits';
      case '/clients':
        return 'Clients';
      case '/suppliers':
        return 'Fournisseurs';
      case '/sales':
        return 'Ventes';
      case '/purchases':
        return 'Achats';
      case '/inventory':
        return 'Inventaire';
      case '/reports':
        return 'Rapports';
      case '/invoices':
        return 'Factures';
      case '/store':
        return 'Mon magasin';
      case '/users':
        return 'Utilisateurs';
      default:
        return 'Gestion Magasin';
    }
  }
}
