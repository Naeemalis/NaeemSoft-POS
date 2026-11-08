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

  test('60-day shop ledger: purchases, weighted cost, split sales and credit', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد الخضار'});
    final customer = await shop.db.insert('customers', {'name': 'زبون آجل'});
    final onion = await shop.addProduct('بصل اختبار', 'جوان', 50000, 250);

    await shop.savePurchase(
      supplierId: supplier,
      transactionDate: DateTime(2026, 9, 1),
      paid: 10000,
      items: [
        {'product_id': onion, 'unit': 'جوان', 'packages': 2, 'weight_grams': 50000, 'package_cost': 25000},
      ],
    );
    var product = (await shop.db.query('products', where: 'id=?', whereArgs: [onion])).single;
    expect(product['stock_grams'], 100000);
    expect(product['inventory_value_djf'], 50000);

    await shop.saveSale(
      customerId: customer,
      transactionDate: DateTime(2026, 9, 15),
      paid: 500,
      items: [{'product_id': onion, 'grams': 10000, 'price_per_kg': 200}],
    );
    product = (await shop.db.query('products', where: 'id=?', whereArgs: [onion])).single;
    expect(product['stock_grams'], 90000);
    expect(product['inventory_value_djf'], 45000);

    await shop.savePurchase(
      supplierId: supplier,
      transactionDate: DateTime(2026, 10, 10),
      paid: 0,
      items: [
        {'product_id': onion, 'unit': 'جوان', 'packages': 1, 'weight_grams': 50000, 'package_cost': 30000},
      ],
    );

    // Two separate cart lines for the same product must each retain their own COGS.
    await shop.saveSale(
      customerId: customer,
      transactionDate: DateTime(2026, 10, 30),
      paid: 1000,
      items: [
        {'product_id': onion, 'grams': 10000, 'price_per_kg': 250},
        {'product_id': onion, 'grams': 10000, 'price_per_kg': 250},
      ],
    );

    product = (await shop.db.query('products', where: 'id=?', whereArgs: [onion])).single;
    expect(product['stock_grams'], 120000);
    final items = await shop.db.rawQuery(
      'SELECT SUM(cost_total_djf) AS c FROM sale_items',
    );
    expect(items.single['c'], 15720);

    final sales = await shop.db.rawQuery(
      'SELECT SUM(total-paid) AS due FROM sales WHERE customer_id=?',
      [customer],
    );
    expect(sales.single['due'], 5500);

    final purchases = await shop.db.rawQuery(
      'SELECT SUM(total-paid) AS due FROM purchases WHERE supplier_id=?',
      [supplier],
    );
    expect(purchases.single['due'], 70000);

    final movements = await shop.db.rawQuery(
      'SELECT SUM(quantity_grams) AS q, SUM(value_delta_djf) AS v FROM stock_movements WHERE product_id=?',
      [onion],
    );
    expect(movements.single['q'], 120000);
    expect(movements.single['v'], 64280);

    // Aggregate validation must reject two individually valid lines whose sum exceeds stock.
    await expectLater(
      shop.saveSale(
        customerId: customer,
        paid: 0,
        items: [
          {'product_id': onion, 'grams': 70000, 'price_per_kg': 250},
          {'product_id': onion, 'grams': 70000, 'price_per_kg': 250},
        ],
      ),
      throwsA(isA<Exception>()),
    );
    product = (await shop.db.query('products', where: 'id=?', whereArgs: [onion])).single;
    expect(product['stock_grams'], 120000);
  });

  test('posting the same saved draft twice creates only one invoice and one stock movement set', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد اختبار التكرار'});
    final productId = await shop.addProduct('طماطم اختبار التكرار', 'صندوق', 10000, 200);
    final purchaseItems = [
      {'product_id': productId, 'unit': 'صندوق', 'packages': 2, 'weight_grams': 10000, 'package_cost': 1000},
    ];
    final purchaseDraftId = await shop.saveDraft(
      type: 'purchase',
      items: purchaseItems,
      total: 2000,
    );

    final firstPurchaseId = await shop.savePurchase(
      supplierId: supplier,
      items: purchaseItems,
      paid: 0,
      draftId: purchaseDraftId,
    );
    final repeatedPurchaseId = await shop.savePurchase(
      supplierId: supplier,
      items: purchaseItems,
      paid: 0,
      draftId: purchaseDraftId,
    );

    expect(repeatedPurchaseId, firstPurchaseId);
    expect(await shop.db.rawQuery('SELECT id FROM purchases WHERE source_draft_id=?', [purchaseDraftId]), hasLength(1));
    expect(await shop.db.rawQuery('SELECT id FROM invoice_drafts WHERE id=?', [purchaseDraftId]), isEmpty);

    var product = (await shop.db.query('products', where: 'id=?', whereArgs: [productId])).single;
    expect(product['stock_grams'], 20000);

    final saleItems = [
      {'product_id': productId, 'grams': 1000, 'price_per_kg': 200},
    ];
    final saleDraftId = await shop.saveDraft(
      type: 'sale',
      items: saleItems,
      total: 200,
      paid: 200,
    );
    final firstSaleId = await shop.saveSale(
      customerId: null,
      items: saleItems,
      paid: 200,
      draftId: saleDraftId,
    );
    final repeatedSaleId = await shop.saveSale(
      customerId: null,
      items: saleItems,
      paid: 200,
      draftId: saleDraftId,
    );

    expect(repeatedSaleId, firstSaleId);
    expect(await shop.db.rawQuery('SELECT id FROM sales WHERE source_draft_id=?', [saleDraftId]), hasLength(1));
    expect(await shop.db.rawQuery('SELECT id FROM invoice_drafts WHERE id=?', [saleDraftId]), isEmpty);
    product = (await shop.db.query('products', where: 'id=?', whereArgs: [productId])).single;
    expect(product['stock_grams'], 19000);

    final movementCount = await shop.db.rawQuery('SELECT COUNT(*) n FROM stock_movements WHERE product_id=?', [productId]);
    expect(movementCount.single['n'], 2);
  });

}
