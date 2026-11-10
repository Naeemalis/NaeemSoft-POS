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

  test('supplier invoice increases stock of its linked sales product', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد'});
    final saleProduct = await shop.addProduct('بصل', 'كيلو', 1000, 250);
    final purchaseProduct = await shop.addProduct('بصل توريد', 'جوان', 50000, 0,
      productType: 'purchase', cost: 25000, pairedSaleProductId: saleProduct);
    final id = await shop.savePurchase(supplierId: supplier, paid: 10000, items: [
      {'product_id': purchaseProduct, 'unit': 'جوان', 'packages': 2,
       'weight_grams': 50000, 'package_cost': 25000},
    ]);
    expect(id, greaterThan(0));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [saleProduct]);
    expect(stock.single['stock_grams'], 100000);
    expect(stock.single['inventory_value_djf'], 50000);
    expect(await shop.db.query('stock_movements'), hasLength(1));
    final invoice = await shop.db.query('purchases', where: 'id=?', whereArgs: [id]);
    expect(invoice.single['total'], 50000);
    expect(invoice.single['paid'], 10000);
  });

  test('sales cashier checks and deducts linked inventory at weighted average cost', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد'});
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final saleProduct = await shop.addProduct('طماطم', 'كيلو', 1000, 200);
    final purchaseProduct = await shop.addProduct('طماطم توريد', 'صندوق', 10000, 0,
      productType: 'purchase', pairedSaleProductId: saleProduct);
    await shop.savePurchase(supplierId: supplier, paid: 0, items: [
      {'product_id': purchaseProduct, 'unit': 'صندوق', 'packages': 1,
       'weight_grams': 10000, 'package_cost': 2000},
    ]);
    final id = await shop.saveSale(customerId: customer, paid: 500,
      items: [{'product_id': saleProduct, 'grams': 5000, 'price_per_kg': 200}]);
    expect(id, greaterThan(0));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [saleProduct]);
    expect(stock.single['stock_grams'], 5000);
    expect(stock.single['inventory_value_djf'], 1000);
    expect(await shop.db.query('stock_movements'), hasLength(2));
    final invoice = await shop.db.query('sales', where: 'id=?', whereArgs: [id]);
    expect(invoice.single['total'], 1000);
    expect(invoice.single['paid'], 500);
    expect((await shop.db.query('sale_items')).single['cost_total_djf'], 1000);
  });

  test('supplier and customer balances remain separate while stock is shared', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد'});
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final saleProduct = await shop.addProduct('ليمون', 'كيلو', 1000, 500);
    final purchaseProduct = await shop.addProduct('ليمون توريد', 'جوان', 3000, 0,
      productType: 'purchase', pairedSaleProductId: saleProduct);
    await shop.savePurchase(supplierId: supplier, paid: 0, items: [
      {'product_id': purchaseProduct, 'unit': 'جوان', 'packages': 1,
       'weight_grams': 3000, 'package_cost': 900},
    ]);
    await shop.saveSale(customerId: customer, paid: 0,
      items: [{'product_id': saleProduct, 'grams': 3000, 'price_per_kg': 500}]);
    final supplierDue = await shop.db.rawQuery(
      'SELECT COALESCE(SUM(total-paid),0) due FROM purchases WHERE supplier_id=?', [supplier]);
    final customerDue = await shop.db.rawQuery(
      'SELECT COALESCE(SUM(total-paid),0) due FROM sales WHERE customer_id=?', [customer]);
    expect(supplierDue.single['due'], 900);
    expect(customerDue.single['due'], 1500);
    expect(await shop.db.query('stock_movements'), hasLength(2));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [saleProduct]);
    expect(stock.single['stock_grams'], 0);
  });

  test('posting the same draft twice does not duplicate invoice or stock movement', () async {
    final supplier = await shop.db.insert('suppliers', {'name': 'مورد'});
    final customer = await shop.db.insert('customers', {'name': 'زبون'});
    final saleProduct = await shop.addProduct('خيار', 'كيلو', 1000, 200);
    final purchaseProduct = await shop.addProduct('خيار توريد', 'صندوق', 10000, 0,
      productType: 'purchase', pairedSaleProductId: saleProduct);
    await shop.savePurchase(supplierId: supplier, paid: 0, items: [
      {'product_id': purchaseProduct, 'unit': 'صندوق', 'packages': 1,
       'weight_grams': 10000, 'package_cost': 1000},
    ]);
    final items = [{'product_id': saleProduct, 'grams': 1000, 'price_per_kg': 200}];
    final draft = await shop.saveDraft(type: 'sale', items: items, total: 200, paid: 200);
    final first = await shop.saveSale(customerId: customer, items: items, paid: 200, draftId: draft);
    final second = await shop.saveSale(customerId: customer, items: items, paid: 200, draftId: draft);
    expect(second, first);
    expect(await shop.db.query('sales', where: 'source_draft_id=?', whereArgs: [draft]), hasLength(1));
    expect(await shop.db.query('stock_movements'), hasLength(2));
    final stock = await shop.db.query('products', where: 'id=?', whereArgs: [saleProduct]);
    expect(stock.single['stock_grams'], 9000);
  });
}
