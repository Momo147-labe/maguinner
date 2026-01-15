// import '../core/database/database_helper.dart';
// import '../models/supplier.dart';
// import '../models/product.dart';

// /// Classe pour initialiser des données d'exemple
// class SampleDataInitializer {
//   static Future<void> initializeSampleData() async {
//     try {
//       // Vérifier si des données existent déjà
//       final existingSuppliers = await DatabaseHelper.instance.getSuppliers();
//       final existingProducts = await DatabaseHelper.instance.getProducts();
      
//       if (existingSuppliers.isEmpty) {
//         await _createSampleSuppliers();
//       }
      
//       if (existingProducts.isEmpty) {
//         await _createSampleProducts();
//       }
      
//       print('Données d\'exemple initialisées avec succès');
//     } catch (e) {
//       print('Erreur lors de l\'initialisation des données d\'exemple: $e');
//     }
//   }
  
//   static Future<void> _createSampleSuppliers() async {
//     final suppliers = [
//       Supplier(
//         name: 'Fournisseur Alimentaire Conakry',
//         email: 'contact@fac-conakry.gn',
//         phone: '+224 622 123 456',
//         address: 'Kaloum, Conakry',
//         balance: 0,
//       ),
//       Supplier(
//         name: 'Distributeur Électronique Guinée',
//         email: 'info@deg-guinee.com',
//         phone: '+224 664 789 012',
//         address: 'Matam, Conakry',
//         balance: 0,
//       ),
//       Supplier(
//         name: 'Grossiste Textile Mamou',
//         email: 'vente@gtm-mamou.gn',
//         phone: '+224 655 345 678',
//         address: 'Centre-ville, Mamou',
//         balance: 0,
//       ),
//     ];
    
//     for (final supplier in suppliers) {
//       await DatabaseHelper.instance.insertSupplier(supplier);
//     }
//   }
  
//   static Future<void> _createSampleProducts() async {
//     final products = [
//       Product(
//         name: 'Riz Local 25kg',
//         category: 'Alimentaire',
//         purchasePrice: 180000,
//         salePrice: 220000,
//         stockQuantity: 50,
//         stockAlertThreshold: 10,
//       ),
//       Product(
//         name: 'Huile de Palme 5L',
//         category: 'Alimentaire',
//         purchasePrice: 45000,
//         salePrice: 55000,
//         stockQuantity: 30,
//         stockAlertThreshold: 5,
//       ),
//       Product(
//         name: 'Smartphone Samsung A54',
//         category: 'Électronique',
//         purchasePrice: 2500000,
//         salePrice: 3200000,
//         stockQuantity: 15,
//         stockAlertThreshold: 3,
//       ),
//       Product(
//         name: 'Écouteurs Bluetooth',
//         category: 'Électronique',
//         purchasePrice: 85000,
//         salePrice: 120000,
//         stockQuantity: 25,
//         stockAlertThreshold: 5,
//       ),
//       Product(
//         name: 'Tissu Wax Premium',
//         category: 'Textile',
//         purchasePrice: 35000,
//         salePrice: 50000,
//         stockQuantity: 40,
//         stockAlertThreshold: 8,
//       ),
//       Product(
//         name: 'Chaussures Sport Nike',
//         category: 'Textile',
//         purchasePrice: 450000,
//         salePrice: 650000,
//         stockQuantity: 12,
//         stockAlertThreshold: 3,
//       ),
//     ];
//     }