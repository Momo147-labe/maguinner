
import 'package:gestion_moderne_magasin/models/customer.dart';
import 'package:gestion_moderne_magasin/models/product.dart';
import 'package:gestion_moderne_magasin/models/purchase.dart';
import 'package:gestion_moderne_magasin/models/purchase_line.dart';
import 'package:gestion_moderne_magasin/models/sale.dart';
import 'package:gestion_moderne_magasin/models/sale_line.dart';
import 'package:gestion_moderne_magasin/models/supplier.dart';
import 'package:gestion_moderne_magasin/models/user.dart';
import 'package:gestion_moderne_magasin/models/app_settings.dart';
import 'package:gestion_moderne_magasin/models/store_info.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  late Database _db;
  bool _isInitialized = false;

  DatabaseHelper._internal();

  Future<void> initDatabase({bool isDev = false}) async {
    if (_isInitialized) return;

    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    final dbPath = join(
      isDev ? '.' : await databaseFactory.getDatabasesPath(),
      'magasin.db',
    );

    _db = await databaseFactory.openDatabase(dbPath, options: OpenDatabaseOptions(
      version: 5,
      onCreate: (db, version) async {
        // Table users
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            full_name TEXT,
            role TEXT,
            secret_code TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Table products
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT,
            category TEXT,
            purchase_price REAL,
            sale_price REAL,
            stock_quantity INTEGER,
            stock_alert_threshold INTEGER,
            image_path TEXT
          )
        ''');

        // Table suppliers
        await db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            address TEXT,
            balance REAL DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Table customers
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            address TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Table purchases
        await db.execute('''
          CREATE TABLE purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id INTEGER,
            user_id INTEGER,
            purchase_date TEXT DEFAULT CURRENT_TIMESTAMP,
            total_amount REAL,
            payment_type TEXT DEFAULT 'direct',
            due_date TEXT,
            discount REAL,
            FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        // Table purchase_lines
        await db.execute('''
          CREATE TABLE purchase_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purchase_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            purchase_price REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (purchase_id) REFERENCES purchases(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        // Table sales avec user_id
        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            user_id INTEGER,
            sale_date TEXT DEFAULT CURRENT_TIMESTAMP,
            total_amount REAL,
            payment_type TEXT DEFAULT 'direct',
            discount REAL,
            due_date TEXT,
            discount_rate REAL,
            FOREIGN KEY (customer_id) REFERENCES customers(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        // Table sale_lines
        await db.execute('''
          CREATE TABLE sale_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            sale_price REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        // Table app_settings
        await db.execute('''
          CREATE TABLE app_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_launch_done INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Table store_info
        await db.execute('''
          CREATE TABLE store_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            location TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Ajouter les nouvelles colonnes à la table sales
          await db.execute('ALTER TABLE sales ADD COLUMN payment_type TEXT DEFAULT "direct"');
          await db.execute('ALTER TABLE sales ADD COLUMN discount REAL');
          await db.execute('ALTER TABLE sales ADD COLUMN due_date TEXT');
          await db.execute('ALTER TABLE sales ADD COLUMN discount_rate REAL');
        }
        if (oldVersion < 3) {
          // Ajouter la colonne user_id à la table sales
          await db.execute('ALTER TABLE sales ADD COLUMN user_id INTEGER');
          // Ajouter les nouvelles colonnes pour les achats
          await db.execute('ALTER TABLE purchases ADD COLUMN user_id INTEGER');
          await db.execute('ALTER TABLE purchases ADD COLUMN payment_type TEXT DEFAULT "direct"');
          await db.execute('ALTER TABLE purchases ADD COLUMN due_date TEXT');
          await db.execute('ALTER TABLE purchases ADD COLUMN discount REAL');
          // Ajouter le solde aux fournisseurs
          await db.execute('ALTER TABLE suppliers ADD COLUMN balance REAL DEFAULT 0');
        }
        if (oldVersion < 4) {
          // Ajouter les nouvelles tables pour la version 4
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_settings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_launch_done INTEGER DEFAULT 0,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS store_info (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              owner_name TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT NOT NULL,
              location TEXT NOT NULL,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          
          // Insérer les paramètres par défaut si pas encore fait
          final settingsCount = await db.rawQuery('SELECT COUNT(*) as count FROM app_settings');
          if ((settingsCount.first['count'] as int) == 0) {
            await db.insert('app_settings', {'first_launch_done': 0});
          }
        }
        if (oldVersion < 5) {
          // Ajouter le champ secret_code aux utilisateurs
          try {
            await db.execute('ALTER TABLE users ADD COLUMN secret_code TEXT');
          } catch (e) {
            // Ignorer si la colonne existe déjà
          }
        }
      },
    ));

    _isInitialized = true;
    print('Database ready at: $dbPath');
  }

  bool get isInitialized => _isInitialized;

  // ================= USERS CRUD =================
  Future<int> insertUser(User user) async {
    return await _db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final maps = await _db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUser(int id) async {
    final maps = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<User?> getUserByUsername(String username) async {
    final maps = await _db.query('users', where: 'username = ?', whereArgs: [username]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<User?> getUserByUsernameOrEmail(String identifier) async {
    final maps = await _db.query(
      'users', 
      where: 'username = ? OR full_name = ?', 
      whereArgs: [identifier, identifier]
    );
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    return await _db.update(
      'users', 
      {'password': newPassword}, 
      where: 'id = ?', 
      whereArgs: [userId]
    );
  }

  Future<int> updateUser(User user) async {
    return await _db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    return await _db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PRODUCTS CRUD =================
  Future<int> insertProduct(Product product) async {
    return await _db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final maps = await _db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProduct(int id) async {
    final maps = await _db.query('products', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  Future<int> updateProduct(Product product) async {
    return await _db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    return await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CUSTOMERS CRUD =================
  Future<int> insertCustomer(Customer customer) async {
    return await _db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final maps = await _db.query('customers');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final maps = await _db.query('customers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  Future<int> updateCustomer(Customer customer) async {
    return await _db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    return await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SUPPLIERS CRUD =================
  Future<int> insertSupplier(Supplier supplier) async {
    return await _db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getSuppliers() async {
    final maps = await _db.query('suppliers');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier?> getSupplier(int id) async {
    final maps = await _db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Supplier.fromMap(maps.first) : null;
  }

  Future<int> updateSupplier(Supplier supplier) async {
    return await _db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> deleteSupplier(int id) async {
    return await _db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SALES CRUD =================
  Future<int> insertSale(Sale sale) async {
    return await _db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSales() async {
    final maps = await _db.query('sales');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSale(int id) async {
    final maps = await _db.query('sales', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Sale.fromMap(maps.first) : null;
  }

  Future<int> updateSale(Sale sale) async {
    return await _db.update('sales', sale.toMap(), where: 'id = ?', whereArgs: [sale.id]);
  }

  Future<int> deleteSale(int id) async {
    return await _db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SALE LINES CRUD =================
  Future<int> insertSaleLine(SaleLine saleLine) async {
    return await _db.insert('sale_lines', saleLine.toMap());
  }

  Future<List<SaleLine>> getSaleLines(int saleId) async {
    final maps = await _db.query('sale_lines', where: 'sale_id = ?', whereArgs: [saleId]);
    return maps.map((map) => SaleLine.fromMap(map)).toList();
  }

  Future<int> deleteSaleLine(int id) async {
    return await _db.delete('sale_lines', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PURCHASES CRUD =================
  Future<int> insertPurchase(Purchase purchase) async {
    return await _db.insert('purchases', purchase.toMap());
  }

  Future<List<Purchase>> getPurchases() async {
    final maps = await _db.query('purchases');
    return maps.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<Purchase?> getPurchase(int id) async {
    final maps = await _db.query('purchases', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Purchase.fromMap(maps.first) : null;
  }

  Future<int> updatePurchase(Purchase purchase) async {
    return await _db.update('purchases', purchase.toMap(), where: 'id = ?', whereArgs: [purchase.id]);
  }

  Future<int> deletePurchase(int id) async {
    return await _db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PURCHASE LINES CRUD =================
  Future<int> insertPurchaseLine(PurchaseLine purchaseLine) async {
    return await _db.insert('purchase_lines', purchaseLine.toMap());
  }

  Future<List<PurchaseLine>> getPurchaseLines(int purchaseId) async {
    final maps = await _db.query('purchase_lines', where: 'purchase_id = ?', whereArgs: [purchaseId]);
    return maps.map((map) => PurchaseLine.fromMap(map)).toList();
  }

  Future<int> deletePurchaseLine(int id) async {
    return await _db.delete('purchase_lines', where: 'id = ?', whereArgs: [id]);
  }

  // ================= APP SETTINGS CRUD =================
  Future<AppSettings?> getAppSettings() async {
    final maps = await _db.query('app_settings', limit: 1);
    return maps.isNotEmpty ? AppSettings.fromMap(maps.first) : null;
  }

  Future<int> updateAppSettings(AppSettings settings) async {
    final existing = await getAppSettings();
    if (existing != null) {
      final updateMap = <String, dynamic>{
        'first_launch_done': settings.firstLaunchDone ? 1 : 0,
        'updated_at': settings.updatedAt ?? DateTime.now().toIso8601String(),
      };
      
      return await _db.update('app_settings', updateMap, where: 'id = ?', whereArgs: [existing.id]);
    } else {
      return await _db.insert('app_settings', settings.toMap());
    }
  }

  /// Marque le premier lancement comme terminé
  Future<void> markFirstLaunchDone() async {
    final existing = await getAppSettings();
    if (existing != null) {
      await _db.update(
        'app_settings', 
        {
          'first_launch_done': 1,
          'updated_at': DateTime.now().toIso8601String(),
        }, 
        where: 'id = ?', 
        whereArgs: [existing.id]
      );
    } else {
      await _db.insert('app_settings', {
        'first_launch_done': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ================= STORE INFO CRUD =================
  Future<int> insertStoreInfo(StoreInfo storeInfo) async {
    // Toujours utiliser id = 1 et remplacer automatiquement
    final storeMap = storeInfo.toMap();
    storeMap['id'] = 1; // Force id = 1
    return await _db.rawInsert('''
      INSERT OR REPLACE INTO store_info (
        id, name, owner_name, phone, email, location, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      1,
      storeMap['name'],
      storeMap['owner_name'],
      storeMap['phone'],
      storeMap['email'],
      storeMap['location'],
      storeMap['created_at'] ?? DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
    ]);
  }

  Future<StoreInfo?> getStoreInfo() async {
    final maps = await _db.query('store_info', where: 'id = ?', whereArgs: [1]);
    return maps.isNotEmpty ? StoreInfo.fromMap(maps.first) : null;
  }

  Future<int> updateStoreInfo(StoreInfo storeInfo) async {
    // Utiliser INSERT OR REPLACE pour garantir id = 1
    final storeMap = storeInfo.toMap();
    storeMap['id'] = 1;
    storeMap['updated_at'] = DateTime.now().toIso8601String();
    return await _db.rawInsert('''
      INSERT OR REPLACE INTO store_info (
        id, name, owner_name, phone, email, location, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      1,
      storeMap['name'],
      storeMap['owner_name'],
      storeMap['phone'],
      storeMap['email'],
      storeMap['location'],
      storeMap['created_at'] ?? DateTime.now().toIso8601String(),
      storeMap['updated_at'],
    ]);
  }

  Future<void> close() async => await _db.close();
}
