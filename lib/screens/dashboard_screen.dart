import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../models/user.dart';

/// Écran du tableau de bord
class DashboardScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const DashboardScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _onNavigate(String route) {
    if (route == '/login') {
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushNamed(route, arguments: widget.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            currentRoute: '/dashboard',
            onNavigate: _onNavigate,
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Header
                Header(
                  userName: widget.currentUser.fullName ?? widget.currentUser.username,
                  isDarkMode: widget.isDarkMode,
                  onThemeToggle: widget.onThemeToggle,
                ),
                
                // Contenu du dashboard
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau de Bord',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Cartes de statistiques
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              _buildStatCard(
                                context,
                                'Produits',
                                '0',
                                Icons.inventory,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                context,
                                'Ventes du jour',
                                '0 €',
                                Icons.shopping_cart,
                                Colors.green,
                              ),
                              _buildStatCard(
                                context,
                                'Clients',
                                '0',
                                Icons.people,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                context,
                                'Stock faible',
                                '0',
                                Icons.warning,
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}