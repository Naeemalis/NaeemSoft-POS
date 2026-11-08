import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:naeemsoft_pos/shop_db.dart';

void main() {
  final shop = ShopDb.instance;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    await shop.open(databasePath: inMemoryDatabasePath);
  });
  tearDown(() async {
    await shop.close();
  });

  test('supplier invoice is independent and does not increase sales stock', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد مستقل'});
    final product = await shop.addProduct('بصل', 'جوان', 50000, 250);

    final id = await shop.savePurchase(
      supplierId: supplier,
      paid: 10000,
      items: [
        {'product_id': product, 'unit': 'جوان', 'packages': 2,
         'weight_grams': 50000, 'package_cost': 25000},
      ],
    );

    expect(id, greaterThan(0));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [product]);
    expect(stock.single['stock_grams'], 0);
    expect(await shop.db.query('stock_movements'), isEmpty);
    final invoice = await shop.db.query('purchases', where: 'id=?', whereArgs: [id]);
    expect(invoice.single['total'], 50000);
    expect(invoice.single['paid'], 10000);
  });

  test('cashier invoice sells without checking or changing stock', () async {
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final product = await shop.addProduct('طماطم', 'صندوق', 10000, 200);

    final id = await shop.saveSale(
      customerId: customer,
      paid: 500,
      items: [
        {'product_id': product, 'grams': 5000, 'price_per_kg': 200},
      ],
    );

    expect(id, greaterThan(0));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [product]);
    expect(stock.single['stock_grams'], 0);
    expect(await shop.db.query('stock_movements'), isEmpty);
    final invoice = await shop.db.query('sales', where: 'id=?', whereArgs: [id]);
    expect(invoice.single['total'], 1000);
    expect(invoice.single['paid'], 500);
  });

  test('supplier and customer invoices and balances remain separate', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد'});
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final product = await shop.addProduct('ليمون', 'جوان', 3000, 300);

    await shop.savePurchase(
      supplierId: supplier, paid: 0,
      items: [
        {'product_id': product, 'unit': 'جوان', 'packages': 1,
         'weight_grams': 3000, 'package_cost': 900},
      ],
    );
    await shop.saveSale(
      customerId: customer, paid: 0,
      items: [{'product_id': product, 'grams': 3000, 'price_per_kg': 500}],
    );

    final supplierDue = await shop.db.rawQuery(
      'SELECT COALESCE(SUM(total-paid),0) due FROM purchases WHERE supplier_id=?',
      [supplier],
    );
    final customerDue = await shop.db.rawQuery(
      'SELECT COALESCE(SUM(total-paid),0) due FROM sales WHERE customer_id=?',
      [customer],
    );
    expect(supplierDue.single['due'], 900);
    expect(customerDue.single['due'], 1500);
    expect(await shop.db.query('stock_movements'), isEmpty);
  });

  test('posting the same draft twice does not duplicate an invoice', () async {
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final product = await shop.addProduct('خيار', 'صندوق', 10000, 200);
    final items = [
      {'product_id': product, 'grams': 1000, 'price_per_kg': 200},
    ];
    final draft = await shop.saveDraft(
      type: 'sale', items: items, total: 200, paid: 200,
    );

    final first = await shop.saveSale(
      customerId: customer, items: items, paid: 200, draftId: draft,
    );
    final second = await shop.saveSale(
      customerId: customer, items: items, paid: 200, draftId: draft,
    );

    expect(second, first);
    expect(await shop.db.query('sales', where: 'source_draft_id=?', whereArgs: [draft]), hasLength(1));
    expect(await shop.db.query('stock_movements'), isEmpty);
  });
}
