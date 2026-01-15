import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Écran du guide d'utilisation de l'application
class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedSection = 0;

  final List<GuideSection> _sections = [
    GuideSection(
      title: 'Introduction',
      icon: Icons.home,
      content: '''
Bienvenue dans Gestion moderne de magasin, votre solution complète de gestion de magasin.

Cette application vous permet de :
• Gérer votre inventaire en temps réel
• Suivre vos ventes et achats
• Gérer vos clients et fournisseurs
• Générer des rapports détaillés
• Contrôler les accès utilisateurs

Navigation : Utilisez la barre latérale pour accéder aux différentes sections.
''',
      tips: [
        'Commencez par configurer votre magasin dans l\'onglet "Mon Magasin"',
        'Ajoutez vos produits avant de commencer les ventes',
        'Sauvegardez régulièrement vos données',
      ],
    ),
    GuideSection(
      title: 'Inventaire',
      icon: Icons.inventory,
      content: '''
L'inventaire est le cœur de votre magasin. Ici vous pouvez :

1. Ajouter de nouveaux produits
2. Modifier les informations produits
3. Suivre les niveaux de stock
4. Définir des alertes de stock faible

Champs obligatoires :
• Nom du produit
• Prix d'achat
• Prix de vente
• Quantité en stock
''',
      tips: [
        'Utilisez des noms de produits clairs et descriptifs',
        'Définissez un seuil d\'alerte pour éviter les ruptures de stock',
        'Mettez à jour régulièrement les prix selon le marché',
        'Utilisez la fonction de recherche pour trouver rapidement un produit',
      ],
    ),
    GuideSection(
      title: 'Ventes',
      icon: Icons.point_of_sale,
      content: '''
La section ventes vous permet de :

1. Créer une nouvelle vente
2. Sélectionner les produits
3. Choisir le mode de paiement
4. Imprimer les reçus
5. Consulter l'historique des ventes

Modes de paiement disponibles :
• Paiement direct (espèces)
• Vente avec client enregistré
• Vente à crédit
''',
      tips: [
        'Vérifiez toujours le stock avant de valider une vente',
        'Pour les ventes à crédit, sélectionnez obligatoirement un client',
        'Utilisez l\'export pour analyser vos performances de vente',
        'Le stock se met à jour automatiquement après chaque vente',
      ],
    ),
    GuideSection(
      title: 'Achats',
      icon: Icons.shopping_cart,
      content: '''
Gérez vos achats auprès des fournisseurs :

1. Créer un nouvel achat
2. Sélectionner les produits à acheter
3. Définir les quantités
4. Choisir le fournisseur
5. Gérer les paiements et crédits

Le système met automatiquement à jour :
• Le stock des produits
• Les dettes fournisseurs
• L'historique des achats
''',
      tips: [
        'Sélectionnez toujours un fournisseur pour les achats à crédit',
        'Vérifiez les prix d\'achat pour maintenir vos marges',
        'Utilisez les dates d\'échéance pour suivre vos dettes',
        'Le solde fournisseur se met à jour automatiquement',
      ],
    ),
    GuideSection(
      title: 'Clients',
      icon: Icons.people,
      content: '''
Gérez votre base de données clients :

1. Ajouter de nouveaux clients
2. Modifier les informations client
3. Suivre l'historique des achats
4. Gérer les crédits clients
5. Exporter la liste des clients

Informations client :
• Nom (obligatoire)
• Téléphone
• Email
• Adresse
''',
      tips: [
        'Enregistrez les clients réguliers pour un suivi personnalisé',
        'Utilisez les détails client pour voir l\'historique complet',
        'Surveillez les dettes clients via les rapports',
        'Exportez la liste pour des campagnes marketing',
      ],
    ),
    GuideSection(
      title: 'Fournisseurs',
      icon: Icons.business,
      content: '''
Gérez vos relations fournisseurs :

1. Ajouter de nouveaux fournisseurs
2. Suivre les achats par fournisseur
3. Gérer les dettes fournisseurs
4. Consulter l'historique des transactions
5. Exporter les données fournisseurs

Le système calcule automatiquement :
• Total des achats par fournisseur
• Solde des dettes
• Historique des paiements
''',
      tips: [
        'Maintenez les coordonnées fournisseurs à jour',
        'Utilisez les détails pour négocier de meilleurs prix',
        'Surveillez vos dettes pour optimiser la trésorerie',
        'Exportez pour l\'analyse des performances fournisseurs',
      ],
    ),
    GuideSection(
      title: 'Rapports',
      icon: Icons.analytics,
      content: '''
Analysez vos performances avec les rapports :

Types de rapports disponibles :
• Rapport de ventes (par période, vendeur)
• Rapport d'achats (par fournisseur, période)
• Rapport utilisateurs (activité, performance)
• Tableaux de bord avec graphiques

Formats d'export :
• PDF pour impression
• Excel pour analyse approfondie
''',
      tips: [
        'Consultez les rapports régulièrement pour piloter votre activité',
        'Utilisez les filtres par date pour des analyses précises',
        'Exportez en Excel pour des calculs personnalisés',
        'Les graphiques aident à identifier les tendances',
      ],
    ),
    GuideSection(
      title: 'Utilisateurs',
      icon: Icons.admin_panel_settings,
      content: '''
Gérez les accès et permissions :

Rôles disponibles :
• Admin : Accès complet
• Gestionnaire : Gestion + rapports
• Caissier : Ventes uniquement
• Vendeur : Ventes + clients

Fonctionnalités :
• Création d'utilisateurs
• Attribution des rôles
• Génération de badges
• Réinitialisation des mots de passe
''',
      tips: [
        'Attribuez les rôles selon les responsabilités réelles',
        'Changez régulièrement les mots de passe',
        'Utilisez les codes secrets pour la récupération de mot de passe',
        'Générez des badges professionnels pour l\'identification',
      ],
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    setState(() => _selectedSection = index);
    _scrollController.animateTo(
      index * 600.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Guide d\'utilisation - Gestion moderne de magasin', 
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            ..._sections.map((section) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text(section.title, 
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text(section.content),
                pw.SizedBox(height: 10),
                pw.Text('Conseils :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...section.tips.map((tip) => pw.Bullet(text: tip)),
                pw.SizedBox(height: 20),
              ],
            )),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide d\'utilisation'),
        actions: [
          IconButton(
            onPressed: _exportToPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter en PDF',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation latérale
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = _selectedSection == index;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            section.icon,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            section.title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          onTap: () => _scrollToSection(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre de section
                            Row(
                              children: [
                                Icon(
                                  section.icon,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  section.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Contenu
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Text(
                                section.content,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.justify,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Conseils
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb,
                                        color: Colors.amber[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Conseils et bonnes pratiques',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...section.tips.map((tip) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe pour représenter une section du guide
class GuideSection {
  final String title;
  final IconData icon;
  final String content;
  final List<String> tips;

  GuideSection({
    required this.title,
    required this.icon,
    required this.content,
    required this.tips,
  });
}