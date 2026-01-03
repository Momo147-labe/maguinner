import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../models/user.dart';

/// Écran des rapports
class ReportsScreen extends StatefulWidget {
  final User currentUser;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const ReportsScreen({
    Key? key,
    required this.currentUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
          Sidebar(
            currentRoute: '/reports',
            onNavigate: _onNavigate,
          ),
          Expanded(
            child: Column(
              children: [
                Header(
                  userName: widget.currentUser.fullName ?? widget.currentUser.username,
                  isDarkMode: widget.isDarkMode,
                  onThemeToggle: widget.onThemeToggle,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapports',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Cartes de rapports
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              _buildReportCard(
                                context,
                                'Rapport des Ventes',
                                'Analyse des ventes par période',
                                Icons.trending_up,
                                Colors.green,
                              ),
                              _buildReportCard(
                                context,
                                'Rapport des Achats',
                                'Suivi des achats et fournisseurs',
                                Icons.shopping_bag,
                                Colors.blue,
                              ),
                              _buildReportCard(
                                context,
                                'Rapport d\'Inventaire',
                                'État du stock et alertes',
                                Icons.inventory,
                                Colors.orange,
                              ),
                              _buildReportCard(
                                context,
                                'Rapport Financier',
                                'Bénéfices et pertes',
                                Icons.account_balance,
                                Colors.purple,
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

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Génération du rapport: $title')),
          );
        },
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
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}