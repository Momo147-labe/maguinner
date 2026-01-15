import 'package:flutter/material.dart';
import '../models/store_info.dart';
import '../models/user.dart';
import '../services/license_service.dart';

/// Sidebar animée avec logo et horloge temps réel
class AnimatedSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final String currentTime;
  final AnimationController controller;
  final StoreInfo? storeInfo;
  final User currentUser;

  const AnimatedSidebar({
    Key? key,
    required this.currentRoute,
    required this.onNavigate,
    required this.currentTime,
    required this.controller,
    this.storeInfo,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<AnimatedSidebar> createState() => _AnimatedSidebarState();
}

class _AnimatedSidebarState extends State<AnimatedSidebar>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  String? _hoveredItem;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec logo et horloge
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Nom du magasin
                Text(
                  widget.storeInfo?.name ?? 'Gestion Magasin',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.storeInfo?.ownerName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.storeInfo!.ownerName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),

                // Horloge temps réel - Style badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.currentTime,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildMenuItem(
                  icon: Icons.inventory,
                  title: 'Produits',
                  route: '/products',
                ),
                _buildMenuItem(
                  icon: Icons.people_outline,
                  title: 'Clients',
                  route: '/clients',
                ),
                _buildMenuItem(
                  icon: Icons.business,
                  title: 'Fournisseurs',
                  route: '/suppliers',
                ),
                _buildMenuItem(
                  icon: Icons.shopping_cart,
                  title: 'Ventes',
                  route: '/sales',
                ),
                _buildMenuItem(
                  icon: Icons.shopping_bag,
                  title: 'Achats',
                  route: '/purchases',
                ),
                _buildMenuItem(
                  icon: Icons.warehouse,
                  title: 'Inventaire',
                  route: '/inventory',
                ),
                _buildMenuItem(
                  icon: Icons.assessment,
                  title: 'Rapports',
                  route: '/reports',
                ),
                _buildMenuItem(
                  icon: Icons.store_mall_directory,
                  title: 'Mon magasin',
                  route: '/store',
                ),
                // Utilisateurs - Réservé aux admins uniquement
                if (widget.currentUser.role?.toLowerCase() == 'admin')
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Utilisateurs',
                    route: '/users',
                  ),
                const Divider(height: 32),
                // Désactivation licence - Réservé aux admins
                if (widget.currentUser.role?.toLowerCase() == 'adminjhhj')
                  _buildMenuItem(
                    icon: Icons.security,
                    title: 'Désactiver licence',
                    route: '/deactivate-license',
                    isDeactivate: true,
                  ),
                _buildMenuItem(
                  icon: Icons.logout,
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
    bool isDeactivate = false,
  }) {
    final isSelected = widget.currentRoute == route;
    final isHovered = _hoveredItem == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hoveredItem = route);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _hoveredItem = null);
          _hoverController.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : isHovered
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected || isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isLogout || isDeactivate)
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isLogout || isDeactivate)
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            onTap: () {
              if (isDeactivate) {
                _showDeactivateDialog();
              } else {
                widget.onNavigate(route);
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Désactiver la licence'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir désactiver la licence ?\n\n'
          'Cette action vous redirigera vers l\'écran d\'activation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deactivateLicense();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateLicense() async {
    try {
      // 🔒 Désactivation stricte
      await LicenseService.deactivate();

      if (mounted) {
        // ❌ Redirection OBLIGATOIRE vers écran licence
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/license', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la désactivation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
