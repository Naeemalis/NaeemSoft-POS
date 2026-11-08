import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ShopDb {
  ShopDb._();
  static final ShopDb instance = ShopDb._();
  late Database db;

  Future<void> open({String? databasePath}) async {
    final dir = databasePath == null ? await getDatabasesPath() : null;
    db = await openDatabase(
      databasePath ?? p.join(dir!, 'naeemsoft_shop.db'),
      version: 6,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (d, v) async {
        await _createBase(d);
        await _createExtended(d);
        await _createDrafts(d);
        await _createReturns(d);
        await _createIdempotency(d);
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
        if (oldVersion < 4) {
          await _createReturns(d);
        }
        if (oldVersion < 5) {
          if (!await _hasColumn(d, 'products', 'inventory_value_djf')) {
            await d.execute('ALTER TABLE products ADD COLUMN inventory_value_djf INTEGER NOT NULL DEFAULT 0');
          }
          if (!await _hasColumn(d, 'sale_items', 'cost_total_djf')) {
            await d.execute('ALTER TABLE sale_items ADD COLUMN cost_total_djf INTEGER NOT NULL DEFAULT 0');
          }
          if (!await _hasColumn(d, 'sale_items', 'cost_per_kg_snapshot')) {
            await d.execute('ALTER TABLE sale_items ADD COLUMN cost_per_kg_snapshot INTEGER NOT NULL DEFAULT 0');
          }
          if (!await _hasColumn(d, 'stock_movements', 'value_delta_djf')) {
            await d.execute('ALTER TABLE stock_movements ADD COLUMN value_delta_djf INTEGER NOT NULL DEFAULT 0');
          }
          await d.execute('UPDATE products SET inventory_value_djf = CAST(ROUND(stock_grams * COALESCE(cost,0) / 1000.0) AS INTEGER) WHERE inventory_value_djf=0 AND stock_grams>0');
        }
        if (oldVersion < 6) {
          if (!await _hasColumn(d, 'purchases', 'source_draft_id')) {
            await d.execute('ALTER TABLE purchases ADD COLUMN source_draft_id INTEGER');
          }
          if (!await _hasColumn(d, 'sales', 'source_draft_id')) {
            await d.execute('ALTER TABLE sales ADD COLUMN source_draft_id INTEGER');
          }
          await _createIdempotency(d);
        }
      },
    );
  }

  Future<void> close() async { if (db.isOpen) await db.close(); }

  Future<bool> _hasColumn(DatabaseExecutor d, String table, String column) async {
    final columns = await d.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name'] == column);
  }

  Future<void> _createBase(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
      purchase_unit TEXT NOT NULL DEFAULT 'جوان', base_unit TEXT NOT NULL DEFAULT 'كجم',
      default_weight REAL NOT NULL DEFAULT 1, cost REAL NOT NULL DEFAULT 0,
      sale_price REAL NOT NULL DEFAULT 0, stock REAL NOT NULL DEFAULT 0,
      stock_grams INTEGER NOT NULL DEFAULT 0, inventory_value_djf INTEGER NOT NULL DEFAULT 0, active INTEGER NOT NULL DEFAULT 1)''');
    await d.execute('CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, opening_balance INTEGER NOT NULL DEFAULT 0, notes TEXT)');
    await d.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, payment_term TEXT NOT NULL DEFAULT "نقدي", opening_balance INTEGER NOT NULL DEFAULT 0, notes TEXT)');
    await d.execute('''CREATE TABLE purchases(
      id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, date TEXT NOT NULL,
      total REAL NOT NULL, paid REAL NOT NULL, note TEXT, due_date TEXT,
      status TEXT NOT NULL DEFAULT 'posted', source_draft_id INTEGER,
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id))''');
    await d.execute('''CREATE TABLE purchase_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
      unit TEXT NOT NULL, packages REAL NOT NULL, weight_each REAL NOT NULL, quantity REAL NOT NULL,
      unit_cost REAL NOT NULL, line_total REAL NOT NULL, package_cost REAL NOT NULL DEFAULT 0,
      kg_cost REAL NOT NULL DEFAULT 0,
      FOREIGN KEY(purchase_id) REFERENCES purchases(id), FOREIGN KEY(product_id) REFERENCES products(id))''');
    await d.execute('''CREATE TABLE sales(
      id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, date TEXT NOT NULL,
      total REAL NOT NULL, paid REAL NOT NULL, due_date TEXT, status TEXT NOT NULL DEFAULT 'posted', source_draft_id INTEGER,
      FOREIGN KEY(customer_id) REFERENCES customers(id))''');
    await d.execute('''CREATE TABLE sale_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
      quantity REAL NOT NULL, unit_price REAL NOT NULL, line_total REAL NOT NULL,
      quantity_grams INTEGER NOT NULL DEFAULT 0, price_per_kg REAL NOT NULL DEFAULT 0,
      cost_total_djf INTEGER NOT NULL DEFAULT 0, cost_per_kg_snapshot INTEGER NOT NULL DEFAULT 0,
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
      unit_cost_per_kg INTEGER NOT NULL DEFAULT 0, value_delta_djf INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, note TEXT,
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


  Future<void> _createIdempotency(DatabaseExecutor d) async {
    await d.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_purchases_source_draft ON purchases(source_draft_id) WHERE source_draft_id IS NOT NULL');
    await d.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_sales_source_draft ON sales(source_draft_id) WHERE source_draft_id IS NOT NULL');
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


  Future<void> _createReturns(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS returns(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      return_type TEXT NOT NULL CHECK(return_type IN ('customer','supplier')),
      sale_id INTEGER,
      purchase_id INTEGER,
      customer_id INTEGER,
      supplier_id INTEGER,
      date TEXT NOT NULL,
      total INTEGER NOT NULL CHECK(total >= 0),
      cash_paid INTEGER NOT NULL DEFAULT 0 CHECK(cash_paid >= 0),
      note TEXT,
      CHECK((return_type='customer' AND sale_id IS NOT NULL AND purchase_id IS NULL) OR
            (return_type='supplier' AND purchase_id IS NOT NULL AND sale_id IS NULL)),
      FOREIGN KEY(sale_id) REFERENCES sales(id),
      FOREIGN KEY(purchase_id) REFERENCES purchases(id),
      FOREIGN KEY(customer_id) REFERENCES customers(id),
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id)
    )''');
    await d.execute('''CREATE TABLE IF NOT EXISTS return_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      return_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      sale_item_id INTEGER,
      purchase_item_id INTEGER,
      quantity_grams INTEGER NOT NULL CHECK(quantity_grams > 0),
      unit_price INTEGER NOT NULL CHECK(unit_price >= 0),
      line_total INTEGER NOT NULL CHECK(line_total >= 0),
      cost_per_kg INTEGER NOT NULL DEFAULT 0,
      CHECK((sale_item_id IS NOT NULL AND purchase_item_id IS NULL) OR
            (purchase_item_id IS NOT NULL AND sale_item_id IS NULL)),
      FOREIGN KEY(return_id) REFERENCES returns(id),
      FOREIGN KEY(product_id) REFERENCES products(id),
      FOREIGN KEY(sale_item_id) REFERENCES sale_items(id),
      FOREIGN KEY(purchase_item_id) REFERENCES purchase_items(id)
    )''');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_returns_sale ON returns(sale_id)');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_returns_purchase ON returns(purchase_id)');
  }

  Future<List<Map<String,Object?>>> returnableInvoices(String type) async {
    if (type == 'customer') {
      return db.rawQuery("SELECT s.id,s.date,s.total,c.name party_name FROM sales s LEFT JOIN customers c ON c.id=s.customer_id WHERE s.status='posted' ORDER BY s.id DESC");
    }
    return db.rawQuery("SELECT p.id,p.date,p.total,s.name party_name FROM purchases p LEFT JOIN suppliers s ON s.id=p.supplier_id WHERE p.status='posted' ORDER BY p.id DESC");
  }

  Future<List<Map<String,Object?>>> returnableItems(String type, int invoiceId) async {
    if (type == 'customer') {
      return db.rawQuery("""
        SELECT si.id source_item_id,si.product_id,pr.name product_name,
          si.quantity_grams - COALESCE((SELECT SUM(ri.quantity_grams) FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE ri.sale_item_id=si.id AND r.return_type='customer'),0) remaining_grams,
          si.price_per_kg unit_price
        FROM sale_items si JOIN products pr ON pr.id=si.product_id
        WHERE si.sale_id=? AND si.quantity_grams > COALESCE((SELECT SUM(ri.quantity_grams) FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE ri.sale_item_id=si.id AND r.return_type='customer'),0)
      """,[invoiceId]);
    }
    return db.rawQuery("""
      SELECT pi.id source_item_id,pi.product_id,pr.name product_name,
        CAST(ROUND(pi.quantity*1000) AS INTEGER) - COALESCE((SELECT SUM(ri.quantity_grams) FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE ri.purchase_item_id=pi.id AND r.return_type='supplier'),0) remaining_grams,
        CASE WHEN pi.quantity>0 THEN CAST(ROUND(pi.line_total/pi.quantity) AS INTEGER) ELSE 0 END unit_price
      FROM purchase_items pi JOIN products pr ON pr.id=pi.product_id
      WHERE pi.purchase_id=? AND CAST(ROUND(pi.quantity*1000) AS INTEGER) > COALESCE((SELECT SUM(ri.quantity_grams) FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE ri.purchase_item_id=pi.id AND r.return_type='supplier'),0)
    """,[invoiceId]);
  }

  Future<int> saveReturn({
    required String type,
    required int invoiceId,
    required List<Map<String,dynamic>> items,
    int cashPaid = 0,
    String? note,
  }) async {
    if (type != 'customer' && type != 'supplier') throw Exception('نوع المرتجع غير صحيح');
    if (items.isEmpty) throw Exception('أضف صنفاً للمرتجع');
    return db.transaction((tx) async {
      final invoiceTable = type == 'customer' ? 'sales' : 'purchases';
      final invoice = await tx.query(invoiceTable, where:'id=?', whereArgs:[invoiceId], limit:1);
      if (invoice.isEmpty) throw Exception('الفاتورة الأصلية غير موجودة');
      final customerId = type == 'customer' ? invoice.first['customer_id'] as int? : null;
      final supplierId = type == 'supplier' ? invoice.first['supplier_id'] as int? : null;
      int total = 0;
      final supplierReturnByProduct=<int,int>{};
      for (final item in items) {
        final grams=(item['grams'] as num).toInt();
        final sourceId=(item['source_item_id'] as num).toInt();
        if (grams<=0) throw Exception('الكمية المرتجعة غير صحيحة');
        final sourceTable=type=='customer'?'sale_items':'purchase_items';
        final source=await tx.query(sourceTable,where:'id=? AND ${type=='customer'?'sale_id':'purchase_id'}=?',whereArgs:[sourceId,invoiceId],limit:1);
        if(source.isEmpty) throw Exception('صنف الفاتورة الأصلية غير موجود');
        final key=type=='customer'?'sale_item_id':'purchase_item_id';
        final already=await tx.rawQuery('SELECT COALESCE(SUM(ri.quantity_grams),0) q FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE ri.$key=? AND r.return_type=?',[sourceId,type]);
        final originalGrams=type=='customer'?(source.first['quantity_grams'] as num).toInt():((source.first['quantity'] as num)*1000).round();
        final remaining=originalGrams-(already.first['q'] as num).toInt();
        if(grams>remaining) throw Exception('الكمية أكبر من المتبقي القابل للإرجاع');
        final productId=(source.first['product_id'] as num).toInt();
        final price=type=='customer'?(source.first['price_per_kg'] as num).toInt():((source.first['quantity'] as num)>0?((source.first['line_total'] as num)/(source.first['quantity'] as num)).round():0);
        total += ((grams*price)/1000).round();
        if(type=='supplier') supplierReturnByProduct[productId]=(supplierReturnByProduct[productId]??0)+grams;
      }
      if(type=='supplier'){
        for(final entry in supplierReturnByProduct.entries){
          final stock=await tx.query('products',columns:['stock_grams'],where:'id=?',whereArgs:[entry.key],limit:1);
          if(stock.isEmpty || (stock.first['stock_grams'] as num).toInt()<entry.value) throw Exception('المخزون لا يكفي لإرجاع الكمية الإجمالية لهذا الصنف للمورد');
        }
      }
      if(cashPaid<0 || cashPaid>total || (type=='supplier' && cashPaid!=0)) throw Exception('قيمة التسوية غير صحيحة');
      final returnId=await tx.insert('returns',{
        'return_type':type,'sale_id':type=='customer'?invoiceId:null,
        'purchase_id':type=='supplier'?invoiceId:null,
        'customer_id':customerId,'supplier_id':supplierId,
        'date':DateTime.now().toIso8601String(),'total':total,'cash_paid':cashPaid,'note':note,
      });
      for(final item in items){
        final grams=(item['grams'] as num).toInt();
        final sourceId=(item['source_item_id'] as num).toInt();
        final sourceTable=type=='customer'?'sale_items':'purchase_items';
        final source=(await tx.query(sourceTable,where:'id=?',whereArgs:[sourceId],limit:1)).first;
        final productId=(source['product_id'] as num).toInt();
        final price=type=='customer'?(source['price_per_kg'] as num).toInt():((source['quantity'] as num)>0?((source['line_total'] as num)/(source['quantity'] as num)).round():0);
        final line=((grams*price)/1000).round();
        await tx.insert('return_items',{
          'return_id':returnId,'product_id':productId,
          'sale_item_id':type=='customer'?sourceId:null,
          'purchase_item_id':type=='supplier'?sourceId:null,
          'quantity_grams':grams,'unit_price':price,'line_total':line,
          'cost_per_kg':type=='customer'?((source['cost_per_kg_snapshot'] as num?)?.toInt()??0):((source['kg_cost'] as num?)?.toInt()??0),
        });
        final delta=type=='customer'?grams:-grams;
        final productRows=await tx.query('products',columns:['stock_grams','inventory_value_djf'],where:'id=?',whereArgs:[productId],limit:1);
        final currentGrams=(productRows.first['stock_grams'] as num).toInt();
        final currentValue=(productRows.first['inventory_value_djf'] as num).toInt();
        int valueDelta;
        int movementCost;
        if(type=='customer'){
          final originalGrams=(source['quantity_grams'] as num).toInt();
          final originalCost=(source['cost_total_djf'] as num?)?.toInt()??0;
          valueDelta=originalGrams>0?((originalCost*grams)/originalGrams).round():0;
          movementCost=(source['cost_per_kg_snapshot'] as num?)?.toInt()??0;
        }else{
          movementCost=currentGrams>0?((currentValue*1000)/currentGrams).round():0;
          valueDelta=-((grams*movementCost)/1000).round();
        }
        if(type=='supplier' && currentGrams<grams) throw Exception('المخزون لا يكفي لمرتجع المورد');
        await tx.rawUpdate('UPDATE products SET stock_grams=stock_grams+?, stock=(stock_grams+?)/1000.0, inventory_value_djf=MAX(0,inventory_value_djf+?) WHERE id=?',[delta,delta,valueDelta,productId]);
        await tx.insert('stock_movements',{
          'product_id':productId,'movement_type':'adjustment',
          'source_type':type=='customer'?'customer_return':'supplier_return',
          'source_id':returnId,'quantity_grams':delta,
          'unit_cost_per_kg':movementCost,'value_delta_djf':valueDelta,
          'created_at':DateTime.now().toIso8601String(),'note':type=='customer'?'مرتجع زبون':'مرتجع مورد',
        });
      }
      return returnId;
    });
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

  Future<int> savePurchase({
    required int supplierId, required List<Map<String, dynamic>> items,
    required int paid, String? dueDate, String? note, DateTime? transactionDate,
    int? draftId,
  }) async {
    if (items.isEmpty) throw Exception('أضف صنفاً واحداً على الأقل');
    final txDate = (transactionDate ?? DateTime.now()).toIso8601String();
    return db.transaction((tx) async {
      if (draftId != null) {
        final posted = await tx.query('purchases', columns: ['id'], where: 'source_draft_id = ?', whereArgs: [draftId], limit: 1);
        if (posted.isNotEmpty) {
          await tx.delete('invoice_drafts', where: 'id = ? AND invoice_type = ?', whereArgs: [draftId, 'purchase']);
          return (posted.first['id'] as num).toInt();
        }
        final draft = await tx.query('invoice_drafts', where: 'id = ? AND invoice_type = ?', whereArgs: [draftId, 'purchase'], limit: 1);
        if (draft.isEmpty) throw Exception('مسودة التوريد غير موجودة أو سبق ترحيلها');
      }
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
        'supplier_id': supplierId, 'date': txDate,
        'total': total, 'paid': paid, 'due_date': dueDate, 'note': note, 'status': 'posted',
        'source_draft_id': draftId,
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
        final currentRows = await tx.query('products', columns: ['stock_grams','inventory_value_djf'], where: 'id = ?', whereArgs: [x['product_id']], limit: 1);
        if (currentRows.isEmpty) throw Exception('الصنف غير موجود');
        final addedValue = lineTotal;
        await tx.rawUpdate('UPDATE products SET stock_grams = stock_grams + ?, stock = (stock_grams + ?) / 1000.0, inventory_value_djf = inventory_value_djf + ? WHERE id = ?',
            [grams, grams, addedValue, x['product_id']]);
        await tx.insert('stock_movements', {
          'product_id': x['product_id'], 'movement_type': 'purchase',
          'source_type': 'purchase', 'source_id': purchaseId, 'quantity_grams': grams,
          'unit_cost_per_kg': kgCost, 'value_delta_djf': addedValue, 'created_at': txDate,
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
          'date': txDate, 'amount': paid, 'note': 'دفعة عند التوريد',
        });
        await tx.insert('payment_allocations', {
          'payment_id': paymentId, 'invoice_type': 'purchase',
          'invoice_id': purchaseId, 'amount': paid,
        });
      }
      if (draftId != null) await tx.delete('invoice_drafts', where: 'id = ?', whereArgs: [draftId]);
      return purchaseId;
    });
  }

  Future<int> saveSale({
    required int? customerId, required List<Map<String, dynamic>> items,
    required int paid, String? dueDate, DateTime? transactionDate, int? draftId,
  }) async {
    if (items.isEmpty) throw Exception('السلة فارغة');
    final txDate = (transactionDate ?? DateTime.now()).toIso8601String();
    return db.transaction((tx) async {
      if (draftId != null) {
        final posted = await tx.query('sales', columns: ['id'], where: 'source_draft_id = ?', whereArgs: [draftId], limit: 1);
        if (posted.isNotEmpty) {
          await tx.delete('invoice_drafts', where: 'id = ? AND invoice_type = ?', whereArgs: [draftId, 'sale']);
          return (posted.first['id'] as num).toInt();
        }
        final draft = await tx.query('invoice_drafts', where: 'id = ? AND invoice_type = ?', whereArgs: [draftId, 'sale'], limit: 1);
        if (draft.isEmpty) throw Exception('مسودة البيع غير موجودة أو سبق ترحيلها');
      }
      int total = 0;
      final itemCosts = <Map<String,int>>[];
      final requestedByProduct = <int,int>{};
      for (final x in items) {
        final grams = (x['grams'] as num).toInt();
        final price = (x['price_per_kg'] as num).toInt();
        final product = await tx.query('products', where: 'id = ?', whereArgs: [x['product_id']], limit: 1);
        if (product.isEmpty) throw Exception('الصنف غير موجود');
        if (grams <= 0 || price < 0) throw Exception('راجع كمية وسعر الصنف');
        final productId = (x['product_id'] as num).toInt();
        requestedByProduct[productId] = (requestedByProduct[productId] ?? 0) + grams;
        total += ((grams * price) / 1000).round();
        final stockGrams = (product.first['stock_grams'] as num).toInt();
        final stockValue = (product.first['inventory_value_djf'] as num).toInt();
        final costPerKg = stockGrams > 0 ? ((stockValue * 1000) / stockGrams).round() : 0;
        itemCosts.add({'cost': ((grams * costPerKg) / 1000).round(), 'costPerKg': costPerKg});
      }
      for (final entry in requestedByProduct.entries) {
        final stock = await tx.query('products', columns: ['stock_grams','name'], where: 'id = ?', whereArgs: [entry.key], limit: 1);
        if (stock.isEmpty || (stock.first['stock_grams'] as num).toInt() < entry.value) {
          throw Exception('الكمية الإجمالية غير كافية: ${stock.isEmpty ? entry.key : stock.first['name']}');
        }
      }
      if (paid < 0 || paid > total) throw Exception('قيمة المدفوع غير صحيحة');
      if (customerId == null && paid != total) throw Exception('البيع الآجل يتطلب اختيار زبون مسجل');
      final saleId = await tx.insert('sales', {
        'customer_id': customerId, 'date': txDate,
        'total': total, 'paid': paid, 'due_date': dueDate, 'status': 'posted',
        'source_draft_id': draftId,
      });
      for (var i = 0; i < items.length; i++) {
        final x = items[i];
        final grams = (x['grams'] as num).toInt();
        final price = (x['price_per_kg'] as num).toInt();
        final line = ((grams * price) / 1000).round();
        final cost = itemCosts[i];
        await tx.insert('sale_items', {
          'sale_id': saleId, 'product_id': x['product_id'],
          'quantity': grams / 1000, 'unit_price': price,
          'line_total': line, 'quantity_grams': grams, 'price_per_kg': price,
          'cost_total_djf': cost['cost'],
          'cost_per_kg_snapshot': cost['costPerKg'],
        });
        final costValue = cost['cost']!;
        await tx.rawUpdate('UPDATE products SET stock_grams = stock_grams - ?, stock = (stock_grams - ?) / 1000.0, inventory_value_djf = MAX(0, inventory_value_djf - ?) WHERE id = ?',
            [grams, grams, costValue, x['product_id']]);
        await tx.insert('stock_movements', {
          'product_id': x['product_id'], 'movement_type': 'sale',
          'source_type': 'sale', 'source_id': saleId, 'quantity_grams': -grams,
          'unit_cost_per_kg': cost['costPerKg'],
          'value_delta_djf': -costValue, 'created_at': txDate,
        });
      }
      if (customerId != null && paid > 0) {
        final paymentId = await tx.insert('payments', {
          'party_type': 'customer', 'party_id': customerId,
          'date': txDate, 'amount': paid, 'note': 'دفعة عند البيع',
        });
        await tx.insert('payment_allocations', {
          'payment_id': paymentId, 'invoice_type': 'sale', 'invoice_id': saleId, 'amount': paid,
        });
      }
      if (draftId != null) await tx.delete('invoice_drafts', where: 'id = ?', whereArgs: [draftId]);
      return saleId;
    });
  }

  Future<void> addParty(String type, String name, String phone) async {
    await db.insert(type == 'supplier' ? 'suppliers' : 'customers', {'name': name.trim(), 'phone': phone.trim()});
  }
}
