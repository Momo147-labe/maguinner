/// Définitions des tables SQL pour la base de données
class DatabaseTables {
  
  /// Table des utilisateurs
  static const String createUsersTable = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      full_name TEXT,
      role TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Table des produits
  static const String createProductsTable = '''
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
  ''';

  /// Table des fournisseurs
  static const String createSuppliersTable = '''
    CREATE TABLE suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      address TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Table des clients
  static const String createCustomersTable = '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      address TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  /// Table des achats
  static const String createPurchasesTable = '''
    CREATE TABLE purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INTEGER NOT NULL,
      purchase_date TEXT DEFAULT CURRENT_TIMESTAMP,
      total_amount REAL,
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    )
  ''';

  /// Table des lignes d'achats
  static const String createPurchaseLinesTable = '''
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
  ''';

  /// Table des ventes
  static const String createSalesTable = '''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      sale_date TEXT DEFAULT CURRENT_TIMESTAMP,
      total_amount REAL,
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    )
  ''';

  /// Table des lignes de ventes
  static const String createSaleLinesTable = '''
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
  ''';

  /// Liste de toutes les tables à créer
  static const List<String> allTables = [
    createUsersTable,
    createProductsTable,
    createSuppliersTable,
    createCustomersTable,
    createPurchasesTable,
    createPurchaseLinesTable,
    createSalesTable,
    createSaleLinesTable,
  ];

  /// Données d'exemple pour initialiser la base
  static const Map<String, List<Map<String, dynamic>>> sampleData = {
    'users': [
      {
        'username': 'admin',
        'password': 'admin123',
        'full_name': 'Administrateur',
        'role': 'admin'
      },
    ],
    'products': [
      {
        'name': 'Café Grand Arôme',
        'barcode': '325054001',
        'category': 'Épicerie',
        'purchase_price': 3.5,
        'sale_price': 5.0,
        'stock_quantity': 24,
        'stock_alert_threshold': 5,
      },
      {
        'name': 'Pain de mie',
        'barcode': '325054002',
        'category': 'Boulangerie',
        'purchase_price': 1.2,
        'sale_price': 2.0,
        'stock_quantity': 15,
        'stock_alert_threshold': 3,
      },
    ],
    'suppliers': [
      {
        'name': 'Fournisseur Alimentaire SA',
        'email': 'contact@fournisseur-alim.com',
        'phone': '01 23 45 67 89',
        'address': '123 Rue du Commerce, 75001 Paris',
      },
    ],
    'customers': [
      {
        'name': 'Client Particulier',
        'email': 'client@example.com',
        'phone': '06 12 34 56 78',
        'address': '456 Avenue des Clients, 75002 Paris',
      },
    ],
  };
}