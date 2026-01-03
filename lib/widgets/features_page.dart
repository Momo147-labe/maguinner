import 'package:flutter/material.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Fonctionnalités Principales',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureItem(
            Icons.inventory_2,
            'Gestion des Produits',
            'Stock, prix, catégories et alertes',
            Colors.green,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.shopping_cart,
            'Ventes & Achats',
            'Transactions complètes avec historique',
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.people,
            'Clients & Fournisseurs',
            'Gestion des contacts et relations',
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.analytics,
            'Rapports & Statistiques',
            'Analyses détaillées et tableaux de bord',
            Colors.red,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.warehouse,
            'Inventaire',
            'Suivi en temps réel des stocks',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
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