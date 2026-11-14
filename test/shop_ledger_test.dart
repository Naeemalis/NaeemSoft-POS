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

  test('stock count adjustment records positive and negative movements', () async {
    final product = await shop.addProduct('بطاطس', 'كيلو', 1000, 300, cost: 200);
    await shop.setCountedStock(productId: product, countedGrams: 10000, note: 'جرد أولي');
    var row = (await shop.db.query('products', where: 'id=?', whereArgs: [product])).single;
    expect(row['stock_grams'], 10000);
    expect(row['inventory_value_djf'], 2000);

    await shop.setCountedStock(productId: product, countedGrams: 8500, note: 'نقص بالجرد');
    row = (await shop.db.query('products', where: 'id=?', whereArgs: [product])).single;
    expect(row['stock_grams'], 8500);
    expect(row['inventory_value_djf'], 1700);

    final movements = await shop.db.query('stock_movements', where: 'product_id=?', whereArgs: [product], orderBy: 'id');
    expect(movements, hasLength(2));
    expect(movements[0]['quantity_grams'], 10000);
    expect(movements[1]['quantity_grams'], -1500);
    expect(movements[1]['value_delta_djf'], -300);
  });

  test('stock count does not create a movement when quantity is unchanged', () async {
    final product = await shop.addProduct('جزر', 'كيلو', 1000, 250);
    await shop.setCountedStock(productId: product, countedGrams: 0);
    expect(await shop.db.query('stock_movements'), isEmpty);
  });


  test('product categories and supplier-specific package weights are stored independently', () async {
    final categoryId = await shop.addCategory('خضروات');
    final productId = await shop.addProduct(
      'بطاطس', 'جوان', 30000, 250,
      categoryId: categoryId,
    );
    final supplierA = await shop.db.insert('suppliers', {'name': 'مورد أ'});
    final supplierB = await shop.db.insert('suppliers', {'name': 'مورد ب'});

    await shop.saveSupplierProductUnit(
      supplierId: supplierA, productId: productId,
      unitName: 'جوان', weightGrams: 30000,
    );
    await shop.saveSupplierProductUnit(
      supplierId: supplierB, productId: productId,
      unitName: 'جوان', weightGrams: 45000,
    );

    final product = (await shop.db.query('products', where: 'id=?', whereArgs: [productId])).single;
    expect(product['category_id'], categoryId);

    final units = await shop.getSupplierProductUnits(productId);
    expect(units, hasLength(2));
    expect(units.map((x) => x['weight_grams']).toSet(), {30000, 45000});

    await shop.deleteCategory(categoryId);
    final updatedProduct = (await shop.db.query('products', where: 'id=?', whereArgs: [productId])).single;
    expect(updatedProduct['category_id'], isNull);
    expect(await shop.getSupplierProductUnits(productId), hasLength(2));
  });

}
