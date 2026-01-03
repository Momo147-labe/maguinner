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
import 'database_path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _db;

  /// ✅ Getter principal pour accéder à la DB
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  /// ✅ Initialisation avec chemin AppData
  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    // Table sales
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN payment_type TEXT DEFAULT "direct"');
      await db.execute('ALTER TABLE sales ADD COLUMN discount REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE sales ADD COLUMN discount_rate REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE sales ADD COLUMN user_id INTEGER');
      await db.execute('ALTER TABLE purchases ADD COLUMN user_id INTEGER');
      await db.execute('ALTER TABLE purchases ADD COLUMN payment_type TEXT DEFAULT "direct"');
      await db.execute('ALTER TABLE purchases ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE purchases ADD COLUMN discount REAL');
      await db.execute('ALTER TABLE suppliers ADD COLUMN balance REAL DEFAULT 0');
    }
    if (oldVersion < 4) {
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
      
      final settingsCount = await db.rawQuery('SELECT COUNT(*) as count FROM app_settings');
      if ((settingsCount.first['count'] as int) == 0) {
        await db.insert('app_settings', {'first_launch_done': 0});
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN secret_code TEXT');
      } catch (e) {
        // Ignorer si la colonne existe déjà
      }
    }
  }

  // ================= USERS CRUD =================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<User?> getUserByUsernameOrEmail(String identifier) async {
    final db = await database;
    final maps = await db.query(
      'users', 
      where: 'username = ? OR full_name = ?', 
      whereArgs: [identifier, identifier]
    );
    return maps.isNotEmpty ? User.fromMap(maps.first) : null;
  }

  Future<int> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      'users', 
      {'password': newPassword}, 
      where: 'id = ?', 
      whereArgs: [userId]
    );
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PRODUCTS CRUD =================
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CUSTOMERS CRUD =================
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Customer.fromMap(maps.first) : null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SUPPLIERS CRUD =================
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier?> getSupplier(int id) async {
    final db = await database;
    final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Supplier.fromMap(maps.first) : null;
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SALES CRUD =================
  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final maps = await db.query('sales');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSale(int id) async {
    final db = await database;
    final maps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Sale.fromMap(maps.first) : null;
  }

  Future<int> updateSale(Sale sale) async {
    final db = await database;
    return await db.update('sales', sale.toMap(), where: 'id = ?', whereArgs: [sale.id]);
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SALE LINES CRUD =================
  Future<int> insertSaleLine(SaleLine saleLine) async {
    final db = await database;
    return await db.insert('sale_lines', saleLine.toMap());
  }

  Future<List<SaleLine>> getSaleLines(int saleId) async {
    final db = await database;
    final maps = await db.query('sale_lines', where: 'sale_id = ?', whereArgs: [saleId]);
    return maps.map((map) => SaleLine.fromMap(map)).toList();
  }

  Future<int> deleteSaleLine(int id) async {
    final db = await database;
    return await db.delete('sale_lines', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PURCHASES CRUD =================
  Future<int> insertPurchase(Purchase purchase) async {
    final db = await database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await database;
    final maps = await db.query('purchases');
    return maps.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<Purchase?> getPurchase(int id) async {
    final db = await database;
    final maps = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Purchase.fromMap(maps.first) : null;
  }

  Future<int> updatePurchase(Purchase purchase) async {
    final db = await database;
    return await db.update('purchases', purchase.toMap(), where: 'id = ?', whereArgs: [purchase.id]);
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return await db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PURCHASE LINES CRUD =================
  Future<int> insertPurchaseLine(PurchaseLine purchaseLine) async {
    final db = await database;
    return await db.insert('purchase_lines', purchaseLine.toMap());
  }

  Future<List<PurchaseLine>> getPurchaseLines(int purchaseId) async {
    final db = await database;
    final maps = await db.query('purchase_lines', where: 'purchase_id = ?', whereArgs: [purchaseId]);
    return maps.map((map) => PurchaseLine.fromMap(map)).toList();
  }

  Future<int> deletePurchaseLine(int id) async {
    final db = await database;
    return await db.delete('purchase_lines', where: 'id = ?', whereArgs: [id]);
  }

  // ================= APP SETTINGS CRUD =================
  Future<AppSettings?> getAppSettings() async {
    final db = await database;
    final maps = await db.query('app_settings', limit: 1);
    return maps.isNotEmpty ? AppSettings.fromMap(maps.first) : null;
  }

  Future<int> updateAppSettings(AppSettings settings) async {
    final db = await database;
    final existing = await getAppSettings();
    if (existing != null) {
      final updateMap = <String, dynamic>{
        'first_launch_done': settings.firstLaunchDone ? 1 : 0,
        'updated_at': settings.updatedAt ?? DateTime.now().toIso8601String(),
      };
      
      return await db.update('app_settings', updateMap, where: 'id = ?', whereArgs: [existing.id]);
    } else {
      return await db.insert('app_settings', settings.toMap());
    }
  }

  Future<void> markFirstLaunchDone() async {
    final db = await database;
    final existing = await getAppSettings();
    if (existing != null) {
      await db.update(
        'app_settings', 
        {
          'first_launch_done': 1,
          'updated_at': DateTime.now().toIso8601String(),
        }, 
        where: 'id = ?', 
        whereArgs: [existing.id]
      );
    } else {
      await db.insert('app_settings', {
        'first_launch_done': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ================= STORE INFO CRUD =================
  Future<int> insertStoreInfo(StoreInfo storeInfo) async {
    final db = await database;
    final storeMap = storeInfo.toMap();
    storeMap['id'] = 1;
    return await db.rawInsert('''
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
    final db = await database;
    final maps = await db.query('store_info', where: 'id = ?', whereArgs: [1]);
    return maps.isNotEmpty ? StoreInfo.fromMap(maps.first) : null;
  }

  Future<int> updateStoreInfo(StoreInfo storeInfo) async {
    final db = await database;
    final storeMap = storeInfo.toMap();
    storeMap['id'] = 1;
    storeMap['updated_at'] = DateTime.now().toIso8601String();
    return await db.rawInsert('''
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

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}