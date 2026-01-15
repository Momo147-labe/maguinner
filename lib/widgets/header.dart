import 'package:flutter/material.dart';
import 'calculator_dialog.dart';

/// Widget de l'en-tête de l'application
class Header extends StatelessWidget {
  final String userName;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const Header({
    Key? key,
    required this.userName,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Titre de la page (peut être dynamique)
          Text(
            'Gestion de Magasin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Informations utilisateur
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Bienvenue, $userName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 20),
              
              // Toggle theme
              IconButton(
                onPressed: onThemeToggle,
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
              ),
              
              // Calculatrice
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
          ),
        ],
      ),
    );
  }
}