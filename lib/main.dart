import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NaeemSoftApp());

class NaeemSoftApp extends StatelessWidget {
  const NaeemSoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NaeemSoft POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF287A50)),
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: PosHomePage(),
      ),
    );
  }
}

class Product {
  Product({required this.name, this.price = 0, this.quantity = 0});
  String name;
  double price;
  double quantity;

  Map<String, dynamic> toJson() => {
    'name': name, 'price': price, 'quantity': quantity,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
  );
}

class Invoice {
  Invoice({
    required this.number,
    required this.date,
    required this.items,
    required this.total,
  });

  final int number;
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final double total;

  Map<String, dynamic> toJson() => {
    'number': number,
    'date': date.toIso8601String(),
    'items': items,
    'total': total,
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    number: (json['number'] as num).toInt(),
    date: DateTime.parse(json['date'] as String),
    items: (json['items'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    total: (json['total'] as num).toDouble(),
  );
}

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  static const _storageKey = 'naeemsoft_products_v1';
  static const _invoiceStorageKey = 'naeemsoft_invoices_v1';
  final List<Invoice> _invoices = [];
  final List<Product> _products = [
    Product(name: 'بصل'),
    Product(name: 'بطاط'),
    Product(name: 'ليمون'),
    Product(name: 'ثوم'),
  ];
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final savedInvoices = prefs.getString(_invoiceStorageKey);
    if (savedInvoices != null) {
      try {
        final decodedInvoices = jsonDecode(savedInvoices) as List<dynamic>;
        _invoices.addAll(decodedInvoices.map((e) => Invoice.fromJson(
          Map<String, dynamic>.from(e as Map),
        )));
      } catch (_) {
        // Preserve product data even if old invoice data is unreadable.
      }
    }
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _products
          ..clear()
          ..addAll(decoded.map((e) => Product.fromJson(
            Map<String, dynamic>.from(e as Map),
          )));
      } catch (_) {
        // Keep the safe starter catalog if saved data is invalid.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_products.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _invoiceStorageKey,
      jsonEncode(_invoices.map((invoice) => invoice.toJson()).toList()),
    );
  }

  double get _total => _products.fold(
    0, (sum, p) => sum + p.price * p.quantity,
  );

  String _money(double value) => '${value.toStringAsFixed(0)} DJF';

  double _parseQuantity(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return 0;
    // Quantities are entered in whole, half, or quarter units.
    return (value * 4).round() / 4;
  }

  Future<void> _editPrice(Product product) async {
    final controller = TextEditingController(
      text: product.price == 0 ? '' : product.price.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سعر ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'السعر بالفرنك الجيبوتي',
            suffixText: 'DJF',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (price != null && price >= 0) Navigator.pop(context, price);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      setState(() => product.price = value);
      await _save();
    }
  }

  Future<void> _addProduct() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة صنف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الخضار'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && !_products.any((p) => p.name == name)) {
      setState(() => _products.add(Product(name: name)));
      await _save();
    }
  }

  Future<void> _showInvoiceHistory() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سجل الفواتير'),
          content: SizedBox(
            width: double.maxFinite,
            child: _invoices.isEmpty
                ? const Text('لا توجد فواتير محفوظة حتى الآن')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final invoice = _invoices[_invoices.length - 1 - index];
                      final date = invoice.date.toLocal();
                      final dateText =
                          '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}  '
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('فاتورة #${invoice.number}'),
                        subtitle: Text('$dateText • ${invoice.items.length} أصناف'),
                        trailing: Text(_money(invoice.total)),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: Text('تفاصيل الفاتورة #${invoice.number}'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...invoice.items.map((item) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item['name'] as String),
                                      subtitle: Text(
                                        '${item['quantity']} × ${_money((item['unitPrice'] as num).toDouble())}',
                                      ),
                                      trailing: Text(_money(
                                        (item['lineTotal'] as num).toDouble(),
                                      )),
                                    )),
                                    const Divider(),
                                    ListTile(
                                      title: const Text('الإجمالي',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                      trailing: Text(_money(invoice.total),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إغلاق'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSale() async {
    final saleItems = _products.where((p) => p.quantity > 0).toList();
    if (saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كمية صنف واحد على الأقل')),
      );
      return;
    }

    final total = saleItems.fold<double>(
      0, (sum, p) => sum + p.price * p.quantity,
    );
    if (saleItems.any((p) => p.price <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدد أسعار جميع الأصناف قبل إتمام البيع')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: Text('إجمالي الفاتورة: ${_money(total)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ الفاتورة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final nextNumber = _invoices.isEmpty
        ? 1
        : _invoices.map((i) => i.number).reduce((a, b) => a > b ? a : b) + 1;
    final invoice = Invoice(
      number: nextNumber,
      date: DateTime.now(),
      items: saleItems.map((p) => {
        'name': p.name,
        'quantity': p.quantity,
        'unitPrice': p.price,
        'lineTotal': p.price * p.quantity,
      }).toList(),
      total: total,
    );

    setState(() {
      _invoices.add(invoice);
      for (final product in _products) {
        product.quantity = 0;
        _quantityControllers[product.name]?.clear();
      }
    });
    await _saveInvoices();
    await _save();

    if (!mounted) return;
    await _showInvoicePreview(invoice);
  }

  Future<void> _showInvoicePreview(Invoice invoice) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('فاتورة رقم ${invoice.number}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NaeemSoft POS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('فاتورة مبيعات'),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('التاريخ: ${invoice.date.toLocal()}',
                      style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(flex: 3, child: Text('الصنف',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('العدد',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('سعر الوحدة',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('الإجمالي',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(),
                  ...invoice.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item['name'] as String)),
                        Expanded(flex: 2, child: Text(
                          (item['quantity'] as num).toString(),
                          textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(
                          (item['unitPrice'] as num).toStringAsFixed(0),
                          textAlign: TextAlign.end)),
                        Expanded(flex: 2, child: Text(
                          (item['lineTotal'] as num).toStringAsFixed(0),
                          textAlign: TextAlign.end)),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_money(invoice.total),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('شكراً لتعاملكم معنا',
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NaeemSoft POS',
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'سجل الفواتير',
            onPressed: _showInvoiceHistory,
            icon: const Icon(Icons.receipt_long),
          ),
          IconButton(
            tooltip: 'إضافة صنف',
            onPressed: _addProduct,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إجمالي المبيعات الحالية'),
                      const SizedBox(height: 6),
                      Text(_money(_total),
                        style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('الصنف')),
                      Expanded(flex: 2, child: Text('الكمية')),
                      Expanded(flex: 2, child: Text('السعر')),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final controller = _quantityControllers.putIfAbsent(
                        product.name, () => TextEditingController(),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(product.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: '0 / 0.5 / 0.25',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() => product.quantity = _parseQuantity(value));
                                  _save();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _editPrice(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    product.price == 0 ? 'تحديد السعر' : _money(product.price),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: product.price == 0
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _completeSale,
                        icon: const Icon(Icons.point_of_sale),
                        label: const Padding(
                          padding: EdgeInsets.all(13),
                          child: Text('إتمام البيع'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
