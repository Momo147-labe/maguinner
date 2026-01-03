import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_moderne_magasin/core/database/database_helper.dart';
import 'package:gestion_moderne_magasin/models/product.dart';
import 'package:gestion_moderne_magasin/models/user.dart';
import 'package:gestion_moderne_magasin/models/customer.dart';
import 'package:gestion_moderne_magasin/models/supplier.dart';

void main() {
  group('Database Tests', () {
    late DatabaseHelper dbHelper;

    setUpAll(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initDatabase();
    });

    test('Insert and retrieve product', () async {
      // Créer un produit de test
      final product = Product(
        name: 'Test Product',
        barcode: 'TEST123',
        category: 'Test Category',
        purchasePrice: 10.0,
        salePrice: 15.0,
        stockQuantity: 100,
        stockAlertThreshold: 10,
      );

      // Insérer le produit
      final id = await dbHelper.insertProduct(product);
      expect(id, greaterThan(0));

      // Récupérer le produit
      final retrievedProduct = await dbHelper.getProduct(id);
      expect(retrievedProduct, isNotNull);
      expect(retrievedProduct!.name, equals('Test Product'));
      expect(retrievedProduct.barcode, equals('TEST123'));
    });

    test('User authentication', () async {
      // Créer un utilisateur de test
      final user = User(
        username: 'testuser',
        password: 'testpass',
        fullName: 'Test User',
        role: 'user',
      );

      // Insérer l'utilisateur
      final id = await dbHelper.insertUser(user);
      expect(id, greaterThan(0));

      // Tester l'authentification
      final authenticatedUser = await dbHelper.getUserByUsername('testuser');
      expect(authenticatedUser, isNotNull);
      expect(authenticatedUser!.password, equals('testpass'));
    });

    test('Customer CRUD operations', () async {
      // Créer un client
      final customer = Customer(
        name: 'Test Customer',
        email: 'test@customer.com',
        phone: '0123456789',
        address: 'Test Address',
      );

      // Insérer
      final id = await dbHelper.insertCustomer(customer);
      expect(id, greaterThan(0));

      // Lire
      final retrievedCustomer = await dbHelper.getCustomer(id);
      expect(retrievedCustomer, isNotNull);
      expect(retrievedCustomer!.name, equals('Test Customer'));

      // Mettre à jour
      final updatedCustomer = retrievedCustomer.copyWith(
        name: 'Updated Customer',
      );
      final updateResult = await dbHelper.updateCustomer(updatedCustomer);
      expect(updateResult, greaterThan(0));

      // Vérifier la mise à jour
      final finalCustomer = await dbHelper.getCustomer(id);
      expect(finalCustomer!.name, equals('Updated Customer'));

      // Supprimer
      final deleteResult = await dbHelper.deleteCustomer(id);
      expect(deleteResult, greaterThan(0));
    });

    test('Supplier CRUD operations', () async {
      // Créer un fournisseur
      final supplier = Supplier(
        name: 'Test Supplier',
        email: 'test@supplier.com',
        phone: '0987654321',
        address: 'Supplier Address',
      );

      // Insérer
      final id = await dbHelper.insertSupplier(supplier);
      expect(id, greaterThan(0));

      // Lire
      final retrievedSupplier = await dbHelper.getSupplier(id);
      expect(retrievedSupplier, isNotNull);
      expect(retrievedSupplier!.name, equals('Test Supplier'));

      // Lister tous les fournisseurs
      final allSuppliers = await dbHelper.getSuppliers();
      expect(allSuppliers.length, greaterThan(0));
    });

    test('Product low stock detection', () {
      // Créer un produit avec stock faible
      final lowStockProduct = Product(
        name: 'Low Stock Product',
        stockQuantity: 2,
        stockAlertThreshold: 5,
      );

      // Vérifier la détection de stock faible
      expect(lowStockProduct.isLowStock, isTrue);

      // Créer un produit avec stock normal
      final normalStockProduct = Product(
        name: 'Normal Stock Product',
        stockQuantity: 10,
        stockAlertThreshold: 5,
      );

      // Vérifier que le stock n'est pas faible
      expect(normalStockProduct.isLowStock, isFalse);
    });
  });

  group('Model Tests', () {
    test('Product model serialization', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        barcode: 'TEST123',
        category: 'Test',
        purchasePrice: 10.0,
        salePrice: 15.0,
        stockQuantity: 100,
        stockAlertThreshold: 10,
      );

      // Test toMap
      final map = product.toMap();
      expect(map['name'], equals('Test Product'));
      expect(map['purchase_price'], equals(10.0));

      // Test fromMap
      final productFromMap = Product.fromMap(map);
      expect(productFromMap.name, equals(product.name));
      expect(productFromMap.purchasePrice, equals(product.purchasePrice));
    });

    test('User model serialization', () {
      final user = User(
        id: 1,
        username: 'testuser',
        password: 'testpass',
        fullName: 'Test User',
        role: 'admin',
      );

      // Test toMap
      final map = user.toMap();
      expect(map['username'], equals('testuser'));
      expect(map['full_name'], equals('Test User'));

      // Test fromMap
      final userFromMap = User.fromMap(map);
      expect(userFromMap.username, equals(user.username));
      expect(userFromMap.fullName, equals(user.fullName));
    });

    test('Product copyWith method', () {
      final originalProduct = Product(
        id: 1,
        name: 'Original Product',
        stockQuantity: 10,
      );

      final copiedProduct = originalProduct.copyWith(
        name: 'Updated Product',
        stockQuantity: 20,
      );

      expect(copiedProduct.id, equals(originalProduct.id));
      expect(copiedProduct.name, equals('Updated Product'));
      expect(copiedProduct.stockQuantity, equals(20));
    });
  });
}