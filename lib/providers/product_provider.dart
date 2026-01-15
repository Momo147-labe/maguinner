// import 'package:flutter/material.dart';
// import 'package:gestion_moderne_magasin/core/database/database_helper.dart';
// import 'package:gestion_moderne_magasin/models/product_model.dart';
// import 'package:sqflite/sqflite.dart';

// class ProductProvider extends ChangeNotifier {
//   List<Product> _products = [];
//   List<Product> get products => _products;

  

//   ProductProvider() {
//     _init();
//   }

//   Future<void> _init() async {
//     await _loadProducts();
//     if (_products.isEmpty) {
//       await _insertDummyData();
//       await _loadProducts();
//     }
//   }

//   Future<void> _loadProducts() async {
//     final db = await DatabaseHelper.database;
//     final result = await db.query('products');
//     _products = result.map((e) => Product.fromMap(e)).toList();
//     notifyListeners();
//   }

//   Future<void> addProduct(Product product) async {
//     final db = await DatabaseHelper.database;
//     product.id = await db.insert('products', product.toMap());
//     _products.add(product);
//     notifyListeners();
//   }

//   Future<void> updateProduct(Product product) async {
//     final db = await DatabaseHelper.database;
//     await db.update(
//       'products',
//       product.toMap(),
//       where: 'id = ?',
//       whereArgs: [product.id],
//     );
//     int index = _products.indexWhere((p) => p.id == product.id);
//     if (index != -1) {
//       _products[index] = product;
//       notifyListeners();
//     }
//   }

//   Future<void> deleteProduct(int id) async {
//     final db = await DatabaseHelper.database;
//     await db.delete('products', where: 'id = ?', whereArgs: [id]);
//     _products.removeWhere((p) => p.id == id);
//     notifyListeners();
//   }

//   /// Insère 20 produits de test
//   Future<void> _insertDummyData() async {
//     final db = await DatabaseHelper.database;
//     List<Product> dummyProducts = List.generate(
//       20,
//       (i) => Product(
//         name: 'Produit ${i + 1}',
//         price: (10 + i * 5).toDouble(),
//         stock: 5 + i,
//       ),
//     );

//     for (var p in dummyProducts) {
//       await db.insert('products', p.toMap());
//     }
//   }
// }
