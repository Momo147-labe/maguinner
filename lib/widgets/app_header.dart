import 'package:flutter/material.dart';
import 'alerts_widget.dart';
import 'calculator_dialog.dart';

/// Header amélioré avec design professionnel
class AppHeader extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AppHeader({
    Key? key,
    required this.userName,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Titre de la page
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Gestion de Magasin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Système de gestion intégré',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Actions à droite
          Row(
            children: [
              // Informations utilisateur
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bienvenue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Alertes du magasin
              const AlertsWidget(),
              
              const SizedBox(width: 8),
              
              // Toggle theme avec animation
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onThemeToggle,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDarkMode),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Calculatrice
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CalculatorDialog(),
                    );
                  },
                  icon: Icon(
                    Icons.calculate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Calculatrice',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}