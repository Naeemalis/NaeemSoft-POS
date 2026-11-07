import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ShopDb {
  ShopDb._();
  static final ShopDb instance = ShopDb._();
  late Database db;

  Future<void> open() async {
    final dir = await getDatabasesPath();
    db = await openDatabase(
      p.join(dir, 'naeemsoft_shop.db'),
      version: 3,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (d, v) async {
        await _createBase(d);
        await _createExtended(d);
        await _createDrafts(d);
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await d.execute('ALTER TABLE products ADD COLUMN stock_grams INTEGER NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE products ADD COLUMN active INTEGER NOT NULL DEFAULT 1');
          await d.execute('UPDATE products SET stock_grams = CAST(ROUND(stock * 1000) AS INTEGER)');
          await d.execute('ALTER TABLE purchases ADD COLUMN due_date TEXT');
          await d.execute('ALTER TABLE purchases ADD COLUMN status TEXT NOT NULL DEFAULT "posted"');
          await d.execute('ALTER TABLE sales ADD COLUMN due_date TEXT');
          await d.execute('ALTER TABLE sales ADD COLUMN status TEXT NOT NULL DEFAULT "posted"');
          await d.execute('ALTER TABLE purchase_items ADD COLUMN package_cost REAL NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE purchase_items ADD COLUMN kg_cost REAL NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE sale_items ADD COLUMN quantity_grams INTEGER NOT NULL DEFAULT 0');
          await d.execute('ALTER TABLE sale_items ADD COLUMN price_per_kg REAL NOT NULL DEFAULT 0');
          await d.execute('UPDATE purchase_items SET kg_cost = unit_cost, package_cost = CASE WHEN packages > 0 THEN line_total / packages ELSE 0 END');
          await d.execute('UPDATE sale_items SET quantity_grams = CAST(ROUND(quantity * 1000) AS INTEGER), price_per_kg = unit_price');
          await _createExtended(d);
        }
        if (oldVersion < 3) {
          await _createDrafts(d);
        }
      },
    );
  }

  Future<void> _createBase(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
      purchase_unit TEXT NOT NULL DEFAULT 'جوان', base_unit TEXT NOT NULL DEFAULT 'كجم',
      default_weight REAL NOT NULL DEFAULT 1, cost REAL NOT NULL DEFAULT 0,
      sale_price REAL NOT NULL DEFAULT 0, stock REAL NOT NULL DEFAULT 0,
      stock_grams INTEGER NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1)''');
    await d.execute('CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, opening_balance INTEGER NOT NULL DEFAULT 0, notes TEXT)');
    await d.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, payment_term TEXT NOT NULL DEFAULT "نقدي", opening_balance INTEGER NOT NULL DEFAULT 0, notes TEXT)');
    await d.execute('''CREATE TABLE purchases(
      id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, date TEXT NOT NULL,
      total REAL NOT NULL, paid REAL NOT NULL, note TEXT, due_date TEXT,
      status TEXT NOT NULL DEFAULT 'posted',
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id))''');
    await d.execute('''CREATE TABLE purchase_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
      unit TEXT NOT NULL, packages REAL NOT NULL, weight_each REAL NOT NULL, quantity REAL NOT NULL,
      unit_cost REAL NOT NULL, line_total REAL NOT NULL, package_cost REAL NOT NULL DEFAULT 0,
      kg_cost REAL NOT NULL DEFAULT 0,
      FOREIGN KEY(purchase_id) REFERENCES purchases(id), FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE sales(
      id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, date TEXT NOT NULL,
      total REAL NOT NULL, paid REAL NOT NULL, due_date TEXT, status TEXT NOT NULL DEFAULT 'posted',
      FOREIGN KEY(customer_id) REFERENCES customers(id))''');
    await d.execute('''CREATE TABLE sale_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
      quantity REAL NOT NULL, unit_price REAL NOT NULL, line_total REAL NOT NULL,
      quantity_grams INTEGER NOT NULL DEFAULT 0, price_per_kg REAL NOT NULL DEFAULT 0,
      FOREIGN KEY(sale_id) REFERENCES sales(id), FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT, party_type TEXT NOT NULL CHECK(party_type IN ('customer','supplier')),
      party_id INTEGER NOT NULL, date TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0), note TEXT)''');
  }

  Future<void> _createExtended(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS product_units(
      id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL,
      unit_name TEXT NOT NULL, default_weight_grams INTEGER NOT NULL DEFAULT 1000,
      UNIQUE(product_id, unit_name), FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS customer_product_prices(
      id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
      price_per_kg INTEGER NOT NULL CHECK(price_per_kg >= 0), active INTEGER NOT NULL DEFAULT 1,
      UNIQUE(customer_id, product_id), FOREIGN KEY(customer_id) REFERENCES customers(id),
      FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS stock_movements(
      id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL,
      movement_type TEXT NOT NULL CHECK(movement_type IN ('purchase','sale','waste','adjustment','opening')),
      source_type TEXT, source_id INTEGER, quantity_grams INTEGER NOT NULL,
      unit_cost_per_kg INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, note TEXT,
      FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS payment_allocations(
      id INTEGER PRIMARY KEY AUTOINCREMENT, payment_id INTEGER NOT NULL,
      invoice_type TEXT NOT NULL CHECK(invoice_type IN ('sale','purchase')),
      invoice_id INTEGER NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0),
      FOREIGN KEY(payment_id) REFERENCES payments(id) ON DELETE CASCADE)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS purchase_batches(
      id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_item_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL, quantity_grams INTEGER NOT NULL,
      remaining_grams INTEGER NOT NULL, expiry_date TEXT,
      cost_per_kg INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(purchase_item_id) REFERENCES purchase_items(id),
      FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS waste_records(
      id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL,
      quantity_grams INTEGER NOT NULL CHECK(quantity_grams > 0),
      reason TEXT, created_at TEXT NOT NULL,
      FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS expenses(
      id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
      amount INTEGER NOT NULL CHECK(amount > 0), expense_date TEXT NOT NULL, note TEXT)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS party_opening_balances(
      id INTEGER PRIMARY KEY AUTOINCREMENT, party_type TEXT NOT NULL CHECK(party_type IN ('customer','supplier')),
      party_id INTEGER NOT NULL, amount INTEGER NOT NULL, created_at TEXT NOT NULL)''');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_purchase_supplier_date ON purchases(supplier_id, date)');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_sales_customer_date ON sales(customer_id, date)');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_stock_product_date ON stock_movements(product_id, created_at)');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_payments_party_date ON payments(party_type, party_id, date)');
  }


  Future<void> _createDrafts(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS invoice_drafts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_type TEXT NOT NULL CHECK(invoice_type IN ('sale','purchase')),
      party_id INTEGER,
      items_json TEXT NOT NULL,
      total INTEGER NOT NULL DEFAULT 0,
      paid INTEGER NOT NULL DEFAULT 0,
      due_date TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_drafts_type_updated ON invoice_drafts(invoice_type, updated_at)');
  }

  Future<int> saveDraft({
    required String type,
    required List<Map<String, dynamic>> items,
    int? partyId,
    int total = 0,
    int paid = 0,
    String? dueDate,
    int? draftId,
  }) async {
    if (type != 'sale' && type != 'purchase') throw Exception('نوع المسودة غير صحيح');
    if (items.isEmpty) throw Exception('لا يمكن حفظ فاتورة فارغة');
    final now = DateTime.now().toIso8601String();
    final values = <String, Object?>{
      'invoice_type': type, 'party_id': partyId, 'items_json': jsonEncode(items),
      'total': total, 'paid': paid, 'due_date': dueDate, 'updated_at': now,
    };
    if (draftId != null) {
      await db.update('invoice_drafts', values, where: 'id = ? AND invoice_type = ?', whereArgs: [draftId, type]);
      return draftId;
    }
    values['created_at'] = now;
    return db.insert('invoice_drafts', values);
  }

  Future<List<Map<String, Object?>>> getDrafts({String? type}) =>
      db.query('invoice_drafts', where: type == null ? null : 'invoice_type = ?',
        whereArgs: type == null ? null : [type], orderBy: 'updated_at DESC');

  Future<Map<String, Object?>> getDraft(int id) async {
    final result = await db.query('invoice_drafts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) throw Exception('المسودة غير موجودة');
    final draft = Map<String, Object?>.from(result.first);
    draft['items'] = (jsonDecode(draft['items_json'] as String) as List)
        .map((x) => Map<String, dynamic>.from(x as Map)).toList();
    return draft;
  }

  Future<void> deleteDraft(int id) async {
    await db.delete('invoice_drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> query(String table, {String? orderBy}) =>
      db.query(table, orderBy: orderBy ?? 'id DESC');

  Future<int> addProduct(String name, String unit, int defaultWeightGrams, int price) async {
    return db.transaction((tx) async {
      final id = await tx.insert('products', {
        'name': name.trim(), 'purchase_unit': unit, 'default_weight': defaultWeightGrams / 1000,
        'sale_price': price, 'stock': 0, 'stock_grams': 0,
      });
      await tx.insert('product_units', {
        'product_id': id, 'unit_name': unit, 'default_weight_grams': defaultWeightGrams,
      });
      return id;
    });
  }

  Future<void> savePurchase({
    required int supplierId, required List<Map<String, dynamic>> items,
    required int paid, String? dueDate, String? note,
  }) async {
    if (items.isEmpty) throw Exception('أضف صنفاً واحداً على الأقل');
    await db.transaction((tx) async {
      int total = 0;
      for (final x in items) {
        final packs = (x['packages'] as num).toInt();
        final weight = (x['weight_grams'] as num).toInt();
        final packageCost = (x['package_cost'] as num).toInt();
        if (packs <= 0 || weight <= 0 || packageCost < 0) throw Exception('راجع العدد والوزن والتكلفة');
        total += packs * packageCost;
      }
      if (paid < 0 || paid > total) throw Exception('قيمة المدفوع غير صحيحة');
      final purchaseId = await tx.insert('purchases', {
        'supplier_id': supplierId, 'date': DateTime.now().toIso8601String(),
        'total': total, 'paid': paid, 'due_date': dueDate, 'note': note, 'status': 'posted',
      });
      for (final x in items) {
        final packs = (x['packages'] as num).toInt();
        final weight = (x['weight_grams'] as num).toInt();
        final packageCost = (x['package_cost'] as num).toInt();
        final grams = packs * weight;
        final kgCost = grams == 0 ? 0 : (total == 0 ? 0 : ((packageCost * 1000) / weight).round());
        final lineTotal = packs * packageCost;
        final itemId = await tx.insert('purchase_items', {
          'purchase_id': purchaseId, 'product_id': x['product_id'], 'unit': x['unit'],
          'packages': packs, 'weight_each': weight / 1000, 'quantity': grams / 1000,
          'unit_cost': grams == 0 ? 0 : lineTotal / (grams / 1000),
          'line_total': lineTotal, 'package_cost': packageCost, 'kg_cost': kgCost,
        });
        await tx.rawUpdate('UPDATE products SET stock_grams = stock_grams + ?, stock = (stock_grams + ?) / 1000.0 WHERE id = ?',
            [grams, grams, x['product_id']]);
        await tx.insert('stock_movements', {
          'product_id': x['product_id'], 'movement_type': 'purchase',
          'source_type': 'purchase', 'source_id': purchaseId, 'quantity_grams': grams,
          'unit_cost_per_kg': kgCost, 'created_at': DateTime.now().toIso8601String(),
        });
        await tx.insert('purchase_batches', {
          'purchase_item_id': itemId, 'product_id': x['product_id'],
          'quantity_grams': grams, 'remaining_grams': grams, 'cost_per_kg': kgCost,
          'expiry_date': x['expiry_date'],
        });
      }
      if (paid > 0) {
        final paymentId = await tx.insert('payments', {
          'party_type': 'supplier', 'party_id': supplierId,
          'date': DateTime.now().toIso8601String(), 'amount': paid, 'note': 'دفعة عند التوريد',
        });
        await tx.insert('payment_allocations', {
          'payment_id': paymentId, 'invoice_type': 'purchase',
          'invoice_id': purchaseId, 'amount': paid,
        });
      }
    });
  }

  Future<void> saveSale({
    required int? customerId, required List<Map<String, dynamic>> items,
    required int paid, String? dueDate,
  }) async {
    if (items.isEmpty) throw Exception('السلة فارغة');
    await db.transaction((tx) async {
      int total = 0;
      for (final x in items) {
        final grams = (x['grams'] as num).toInt();
        final price = (x['price_per_kg'] as num).toInt();
        final product = await tx.query('products', where: 'id = ?', whereArgs: [x['product_id']], limit: 1);
        if (product.isEmpty) throw Exception('الصنف غير موجود');
        if ((product.first['stock_grams'] as num).toInt() < grams) {
          throw Exception('الكمية غير كافية: ${product.first['name']}');
        }
        total += ((grams * price) / 1000).round();
      }
      if (paid < 0 || paid > total) throw Exception('قيمة المدفوع غير صحيحة');
      if (customerId == null && paid != total) throw Exception('البيع الآجل يتطلب اختيار زبون مسجل');
      final saleId = await tx.insert('sales', {
        'customer_id': customerId, 'date': DateTime.now().toIso8601String(),
        'total': total, 'paid': paid, 'due_date': dueDate, 'status': 'posted',
      });
      for (final x in items) {
        final grams = (x['grams'] as num).toInt();
        final price = (x['price_per_kg'] as num).toInt();
        final line = ((grams * price) / 1000).round();
        await tx.insert('sale_items', {
          'sale_id': saleId, 'product_id': x['product_id'],
          'quantity': grams / 1000, 'unit_price': price,
          'line_total': line, 'quantity_grams': grams, 'price_per_kg': price,
        });
        await tx.rawUpdate('UPDATE products SET stock_grams = stock_grams - ?, stock = (stock_grams - ?) / 1000.0 WHERE id = ?',
            [grams, grams, x['product_id']]);
        await tx.insert('stock_movements', {
          'product_id': x['product_id'], 'movement_type': 'sale',
          'source_type': 'sale', 'source_id': saleId, 'quantity_grams': -grams,
          'unit_cost_per_kg': 0, 'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (customerId != null && paid > 0) {
        final paymentId = await tx.insert('payments', {
          'party_type': 'customer', 'party_id': customerId,
          'date': DateTime.now().toIso8601String(), 'amount': paid, 'note': 'دفعة عند البيع',
        });
        await tx.insert('payment_allocations', {
          'payment_id': paymentId, 'invoice_type': 'sale', 'invoice_id': saleId, 'amount': paid,
        });
      }
    });
  }

  Future<void> addParty(String type, String name, String phone) async {
    await db.insert(type == 'supplier' ? 'suppliers' : 'customers', {'name': name.trim(), 'phone': phone.trim()});
  }
}
