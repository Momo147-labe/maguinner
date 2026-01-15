import 'package:flutter/material.dart';
import 'dart:async';
import 'calculator_dialog.dart';

/// Widget de la barre latérale de navigation avec design professionnel
class Sidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const Sidebar({
    Key? key,
    required this.currentRoute,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  late Timer _timer;
  String _currentTime = '';
  String? _hoveredItem;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _hoverController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header avec logo et horloge
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Nom du magasin
                const Text(
                  'Gestion moderne de magasin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestion de Magasin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Horloge temps réel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.inventory_2_rounded,
                  title: 'Produits',
                  route: '/products',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Clients',
                  route: '/clients',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.business_rounded,
                  title: 'Fournisseurs',
                  route: '/suppliers',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Ventes',
                  route: '/sales',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.shopping_bag_rounded,
                  title: 'Achats',
                  route: '/purchases',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.warehouse_rounded,
                  title: 'Inventaire',
                  route: '/inventory',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.assessment_rounded,
                  title: 'Rapports',
                  route: '/reports',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Factures',
                  route: '/invoices',
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  title: 'Utilisateurs',
                  route: '/users',
                ),
                
                // Séparateur
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Theme.of(context).dividerColor.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Déconnexion',
                  route: '/login',
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    bool isLogout = false,
  }) {
    final isSelected = widget.currentRoute == route;
    final isHovered = _hoveredItem == route;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredItem = route);
      },
      onExit: (_) {
        setState(() => _hoveredItem = null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                )
              : isHovered
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        Theme.of(context).colorScheme.primary.withOpacity(0.02),
                      ],
                    )
                  : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : isHovered
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isLogout
                      ? Colors.red.shade600
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isLogout
                      ? Colors.red.shade600
                      : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
          onTap: () => widget.onNavigate(route),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}