import 'package:flutter/material.dart';
import 'shop_db.dart';

String _inventoryMoney(num value) => '${value.round()} DJF';
String _inventoryKg(num grams) => '${(grams / 1000).toStringAsFixed(3)} كجم';

class InventoryCenterPage extends StatefulWidget {
  final VoidCallback onManageProducts;
  const InventoryCenterPage({super.key, required this.onManageProducts});
  @override
  State<InventoryCenterPage> createState() => _InventoryCenterPageState();
}

class _InventoryCenterPageState extends State<InventoryCenterPage> {
  Future<List<Map<String, Object?>>> _loadProducts() => ShopDb.instance.db.query(
    'products',
    where: "active = 1 AND product_type = 'sale'",
    orderBy: 'name',
  );

  Future<void> _setCount(Map<String, Object?> product) async {
    final current = (product['stock_grams'] as num).toInt();
    final quantity = TextEditingController(text: (current / 1000).toStringAsFixed(3));
    final note = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('جرد ${product['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('الرصيد المسجل: ${_inventoryKg(current)}'),
          const SizedBox(height: 10),
          TextField(
            controller: quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'الكمية الفعلية بالكيلو', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'ملاحظة الجرد (اختياري)', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('اعتماد الجرد')),
        ],
      ),
    );
    if (accepted != true) return;
    final parsed = double.tryParse(quantity.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كمية صحيحة لا تقل عن صفر')),
      );
      return;
    }
    try {
      await ShopDb.instance.setCountedStock(
        productId: (product['id'] as num).toInt(),
        countedGrams: (parsed * 1000).round(),
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم اعتماد الجرد وتسجيل حركة التسوية')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اعتماد الجرد: $error')),
      );
    }
  }

  Future<void> _showMovements(Map<String, Object?> product) async {
    final id = (product['id'] as num).toInt();
    final movements = await ShopDb.instance.db.query(
      'stock_movements', where: 'product_id = ?', whereArgs: [id],
      orderBy: 'created_at DESC, id DESC',
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('حركة مخزون ${product['name']}', style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: movements.isEmpty
                ? const Center(child: Text('لا توجد حركات مسجلة لهذا الصنف'))
                : ListView.builder(
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final movement = movements[index];
                      final grams = (movement['quantity_grams'] as num).toInt();
                      final date = (movement['created_at'] ?? '').toString();
                      return ListTile(
                        leading: Icon(
                          grams >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                          color: grams >= 0 ? Colors.green : Colors.orange,
                        ),
                        title: Text('${grams >= 0 ? '+' : ''}${_inventoryKg(grams.abs())}'),
                        subtitle: Text('${movement['note'] ?? movement['movement_type']}\n$date'),
                        isThreeLine: true,
                        trailing: Text('${(movement['value_delta_djf'] as num?)?.toInt() ?? 0} DJF'),
                      );
                    },
                  ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مركز إدارة الأصناف والكميات'),
      actions: [IconButton(tooltip: 'تحديث', onPressed: () => setState(() {}), icon: const Icon(Icons.refresh))],
    ),
    body: FutureBuilder<List<Map<String, Object?>>>(
      future: _loadProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('تعذر تحميل المخزون: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        final totalGrams = products.fold<int>(0, (sum, p) => sum + (p['stock_grams'] as num).toInt());
        final totalValue = products.fold<int>(0, (sum, p) => sum + ((p['inventory_value_djf'] as num?)?.toInt() ?? 0));
        final noStock = products.where((p) => (p['stock_grams'] as num) <= 0).length;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: _summaryCard('عدد الأصناف', '${products.length}', Icons.category_outlined)),
              const SizedBox(width: 6),
              Expanded(child: _summaryCard('إجمالي الكمية', _inventoryKg(totalGrams), Icons.scale_outlined)),
              const SizedBox(width: 6),
              Expanded(child: _summaryCard('قيمة المخزون', _inventoryMoney(totalValue), Icons.account_balance_wallet_outlined)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(child: Text('الأصناف المتاحة: ${products.length - noStock} • بلا رصيد: $noStock')),
              FilledButton.tonalIcon(
                onPressed: widget.onManageProducts,
                icon: const Icon(Icons.tune),
                label: const Text('إدارة بيانات الأصناف'),
              ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: products.isEmpty
              ? const Center(child: Text('لا توجد أصناف مبيعات. أضف الأصناف أولاً.'))
              : ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final grams = (product['stock_grams'] as num).toInt();
                    final value = (product['inventory_value_djf'] as num?) ?? 0;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('سعر البيع: ${_inventoryMoney((product['sale_price'] as num?) ?? 0)} / كجم'
                        '\nقيمة المخزون: ${_inventoryMoney(value)}'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_inventoryKg(grams), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('الرصيد الحالي', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      onTap: () => _setCount(product),
                      onLongPress: () => _showMovements(product),
                    );
                  },
                ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Text(
              'اضغط على الصنف لاعتماد الجرد الفعلي، واضغط مطولاً لعرض سجل حركات المخزون.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ]);
      },
    ),
  );

  Widget _summaryCard(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      child: Column(children: [
        Icon(icon, size: 20),
        const SizedBox(height: 5),
        Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
      ]),
    ),
  );
}
