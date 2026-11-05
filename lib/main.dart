import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NaeemSoftApp());

class NaeemSoftApp extends StatelessWidget {
  const NaeemSoftApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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

class Product {
  Product({required this.name, this.price = 0});
  String name;
  double price;

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );
}

class Invoice {
  Invoice({required this.number, required this.date, required this.items, required this.total});
  final int number;
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final double total;

  Map<String, dynamic> toJson() => {
    'number': number, 'date': date.toIso8601String(), 'items': items, 'total': total,
  };
  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    number: (json['number'] as num).toInt(),
    date: DateTime.parse(json['date'] as String),
    items: (json['items'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    total: (json['total'] as num).toDouble(),
  );
}

class CartLine {
  CartLine({required this.name, required this.quantity, required this.unitPrice});
  final String name;
  final double quantity;
  final double unitPrice;
  double get total => quantity * unitPrice;
}

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});
  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  static const _productsKey = 'naeemsoft_products_v1';
  static const _invoicesKey = 'naeemsoft_invoices_v1';
  final List<Product> _products = [
    Product(name: 'بصل'), Product(name: 'بطاط'), Product(name: 'ليمون'), Product(name: 'ثوم'),
  ];
  final List<Invoice> _invoices = [];
  final List<CartLine> _cart = [];
  String _quantityText = '1';
  bool _quantityTouched = false;
  bool _loading = true;

  double get _selectedQuantity => double.tryParse(_quantityText) ?? 1;
  double get _total => _cart.fold(0, (sum, line) => sum + line.total);
  String _money(double value) => '${value.toStringAsFixed(0)} DJF';
  String _quantityLabel(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\\.$'), '');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProducts = prefs.getString(_productsKey);
    final rawInvoices = prefs.getString(_invoicesKey);
    if (rawProducts != null) {
      try {
        final decoded = jsonDecode(rawProducts) as List<dynamic>;
        _products
          ..clear()
          ..addAll(decoded.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    if (rawInvoices != null) {
      try {
        final decoded = jsonDecode(rawInvoices) as List<dynamic>;
        _invoices.addAll(decoded.map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey, jsonEncode(_products.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_invoicesKey, jsonEncode(_invoices.map((i) => i.toJson()).toList()));
  }

  void _pressDigit(String digit) {
    setState(() {
      if (!_quantityTouched) {
        _quantityText = digit == '0' ? '0' : digit;
        _quantityTouched = true;
      } else if (_quantityText.length < 6) {
        _quantityText += digit;
      }
    });
  }

  void _pressFraction(double fraction) {
    setState(() {
      final whole = _quantityTouched ? (double.tryParse(_quantityText) ?? 0) : 0;
      final base = whole.floorToDouble();
      _quantityText = _quantityLabel(base + fraction);
      _quantityTouched = true;
    });
  }

  void _clearQuantity() {
    setState(() {
      _quantityText = '1';
      _quantityTouched = false;
    });
  }

  void _addToCart(Product product) {
    final quantity = _selectedQuantity;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر كمية أكبر من صفر')),
      );
      return;
    }
    if (product.price <= 0) {
      _editProduct(product);
      return;
    }
    setState(() {
      _cart.add(CartLine(name: product.name, quantity: quantity, unitPrice: product.price));
      _quantityText = '1';
      _quantityTouched = false;
    });
  }

  Future<void> _editProduct(Product? product) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product == null || product.price == 0 ? '' : product.price.toStringAsFixed(0),
    );
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(product == null ? 'إضافة صنف' : 'تعديل الصنف والسعر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصنف')),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'سعر الكيلو بالفرنك الجيبوتي'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim().replaceAll(',', '.'));
                if (name.isNotEmpty && price != null && price >= 0) {
                  Navigator.pop(dialogContext, {'name': name, 'price': price.toString()});
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    priceController.dispose();
    if (result == null) return;
    final name = result['name']!;
    final price = double.parse(result['price']!);
    setState(() {
      if (product == null) {
        if (!_products.any((p) => p.name == name)) _products.add(Product(name: name, price: price));
      } else {
        product.name = name;
        product.price = price;
      }
    });
    await _saveProducts();
  }

  void _removeCartLine(int index) => setState(() => _cart.removeAt(index));

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الأصناف أولاً لإضافتها إلى الفاتورة')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: Text('إجمالي الفاتورة: ${_money(_total)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ الفاتورة')),
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
      items: _cart.map((line) => {
        'name': line.name,
        'quantity': line.quantity,
        'unitPrice': line.unitPrice,
        'lineTotal': line.total,
      }).toList(),
      total: _total,
    );
    setState(() {
      _invoices.add(invoice);
      _cart.clear();
      _quantityText = '1';
      _quantityTouched = false;
    });
    await _saveInvoices();
    if (mounted) await _showInvoice(invoice);
  }

  Widget _key(String label, {VoidCallback? onTap, bool accent = false}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 52,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: accent ? Theme.of(context).colorScheme.primaryContainer : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );

  Widget _buildKeypad() => Card(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              const Text('الكمية المطلوبة', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_quantityLabel(_selectedQuantity),
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 8),
              IconButton(tooltip: 'إعادة ضبط الكمية', onPressed: _clearQuantity,
                icon: const Icon(Icons.backspace_outlined)),
            ],
          ),
          Row(children: [
            _key('7', onTap: () => _pressDigit('7')),
            _key('8', onTap: () => _pressDigit('8')),
            _key('9', onTap: () => _pressDigit('9')),
          ]),
          Row(children: [
            _key('4', onTap: () => _pressDigit('4')),
            _key('5', onTap: () => _pressDigit('5')),
            _key('6', onTap: () => _pressDigit('6')),
          ]),
          Row(children: [
            _key('1', onTap: () => _pressDigit('1')),
            _key('2', onTap: () => _pressDigit('2')),
            _key('3', onTap: () => _pressDigit('3')),
          ]),
          Row(children: [
            _key('½', onTap: () => _pressFraction(0.5), accent: true),
            _key('0', onTap: () => _pressDigit('0')),
            _key('¼', onTap: () => _pressFraction(0.25), accent: true),
          ]),
        ],
      ),
    ),
  );

  Widget _buildProductGallery() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('اختر الصنف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton.icon(onPressed: () => _editProduct(null),
            icon: const Icon(Icons.add), label: const Text('إضافة صنف')),
        ]),
        SizedBox(
          height: 118,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, mainAxisSpacing: 8, childAspectRatio: 0.82,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _addToCart(product),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Center(child: Icon(Icons.eco_outlined,
                          size: 34, color: Theme.of(context).colorScheme.primary))),
                        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(product.price > 0 ? '${_money(product.price)} / كيلو' : 'حدد السعر',
                          style: const TextStyle(fontSize: 11)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _editProduct(product),
                            child: const Icon(Icons.edit, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildCart() => Expanded(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            const Text('الفاتورة الحالية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_cart.length} أصناف'),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(children: [
            Expanded(flex: 4, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('الكمية', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('إجمالي السعر', textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 30),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: _cart.isEmpty
            ? const Center(child: Text('اختر الكمية ثم اضغط على الصنف لإضافته'))
            : ListView.separated(
                itemCount: _cart.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final line = _cart[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(flex: 4, child: Text(line.name)),
                      Expanded(flex: 2, child: Text('${_quantityLabel(line.quantity)} كيلو',
                        textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text(_money(line.total), textAlign: TextAlign.end)),
                      SizedBox(width: 30, child: IconButton(
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        onPressed: () => _removeCartLine(index),
                        icon: const Icon(Icons.close, size: 18),
                      )),
                    ]),
                  );
                },
              ),
        ),
      ],
    ),
  );

  Future<void> _showInvoice(Invoice invoice) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('فاتورة رقم ${invoice.number}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('NaeemSoft POS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('فاتورة مبيعات'),
                const Divider(),
                Text('التاريخ: ${invoice.date.toLocal()}'),
                const SizedBox(height: 12),
                const Row(children: [
                  Expanded(flex: 4, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('الكمية', textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('إجمالي السعر', textAlign: TextAlign.end,
                    style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
                const Divider(),
                ...invoice.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(flex: 4, child: Text(item['name'] as String)),
                    Expanded(flex: 2, child: Text('${_quantityLabel((item['quantity'] as num).toDouble())} كيلو',
                      textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text(_money((item['lineTotal'] as num).toDouble()),
                      textAlign: TextAlign.end)),
                  ]),
                )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_money(invoice.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                const Text('شكراً لتعاملكم معنا'),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      ),
    );
  }

  Future<void> _showHistory() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سجل الفواتير'),
          content: SizedBox(
            width: double.maxFinite,
            child: _invoices.isEmpty
              ? const Text('لا توجد فواتير محفوظة')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = _invoices[_invoices.length - 1 - index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('فاتورة رقم ${invoice.number}'),
                      subtitle: Text(invoice.date.toLocal().toString()),
                      trailing: Text(_money(invoice.total)),
                      onTap: () => _showInvoice(invoice),
                    );
                  },
                ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NaeemSoft POS', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(tooltip: 'سجل الفواتير', onPressed: _showHistory, icon: const Icon(Icons.receipt_long)),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : Column(children: [
          _buildKeypad(),
          _buildProductGallery(),
          _buildCart(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('الإجمالي الكلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_money(_total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _completeSale,
                    icon: const Icon(Icons.point_of_sale),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('إتمام البيع', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
  );
}
