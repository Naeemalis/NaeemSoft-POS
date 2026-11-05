import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  Product({required this.name, this.price = 0, this.stock = 0, List<Map<String, dynamic>>? units})
      : units = units ?? [{'name': 'كيلو', 'factor': 1.0, 'price': price}];
  String name;
  double price;
  double stock;
  List<Map<String, dynamic>> units;
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'stock': stock, 'units': units};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toDouble() ?? 0,
    units: json['units'] is List ? (json['units'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList() : null,
  );
}

class Invoice {
  Invoice({required this.number, required this.date, required this.items, required this.total, this.customerName, this.paidAmount = 0});
  final int number;
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final double total;
  final String? customerName;
  double paidAmount;

  Map<String, dynamic> toJson() => {
    'number': number, 'date': date.toIso8601String(), 'items': items, 'total': total, 'customerName': customerName, 'paidAmount': paidAmount,
  };
  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    number: (json['number'] as num).toInt(),
    date: DateTime.parse(json['date'] as String),
    items: (json['items'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    total: (json['total'] as num).toDouble(),
    customerName: json['customerName'] as String?,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? ((json['customerName'] == null) ? (json['total'] as num).toDouble() : 0),
  );
}

class CartLine {
  CartLine({required this.name, required this.quantity, required this.unitPrice, this.unitName = 'كيلو', this.baseQuantity});
  final String name;
  final double quantity;
  final double unitPrice;
  final String unitName;
  final double? baseQuantity;
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
  static const _receiptsKey = 'naeemsoft_receipts_v1';
  static const _returnsKey = 'naeemsoft_returns_v1';
  static const _languageKey = 'naeemsoft_language_v1';
  final List<Map<String, dynamic>> _receipts = [];
  final List<Map<String, dynamic>> _returns = [];
  String _language = 'ar';
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
    final rawCustomers = prefs.getString(_customersKey);
    final rawSuppliers = prefs.getString(_suppliersKey);
    final rawPurchases = prefs.getString(_purchasesKey);
    final rawReceipts = prefs.getString(_receiptsKey);
    final rawReturns = prefs.getString(_returnsKey);
    _language = prefs.getString(_languageKey) ?? 'ar';
    if (rawProducts != null) {
      try {
        final decoded = jsonDecode(rawProducts) as List<dynamic>;
        _products
          ..clear()
          ..addAll(decoded.map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    if (rawCustomers != null) { try { _customers.addAll((jsonDecode(rawCustomers) as List).map((e) => Map<String,dynamic>.from(e))); } catch (_) {} }
    if (rawSuppliers != null) { try { _suppliers.addAll((jsonDecode(rawSuppliers) as List).map((e) => Map<String,dynamic>.from(e))); } catch (_) {} }
    if (rawPurchases != null) { try { _purchases.addAll((jsonDecode(rawPurchases) as List).map((e) => Map<String,dynamic>.from(e))); } catch (_) {} }
    if (rawReceipts != null) { try { _receipts.addAll((jsonDecode(rawReceipts) as List).map((e) => Map<String,dynamic>.from(e))); } catch (_) {} }
    if (rawReturns != null) { try { _returns.addAll((jsonDecode(rawReturns) as List).map((e) => Map<String,dynamic>.from(e))); } catch (_) {} }
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

  Future<void> _addToCart(Product product) async {
    final quantity = _selectedQuantity;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر كمية أكبر من صفر')));
      return;
    }
    final unit = await _selectUnit(product, 'اختر وحدة البيع');
    if (unit == null) return;
    final factor = (unit['factor'] as num).toDouble();
    final price = (unit['price'] as num).toDouble();
    final baseQty = quantity * factor;
    final alreadyInCart = _cart.where((x) => x.name == product.name).fold(0.0, (v, x) => v + (x.baseQuantity ?? x.quantity));
    if (baseQty + alreadyInCart > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('المخزون غير كافٍ. المتاح: ' + _quantityLabel(product.stock))));
      return;
    }
    if (price <= 0) {
      await _editProduct(product);
      return;
    }
    setState(() {
      _cart.add(CartLine(name: product.name, quantity: quantity, unitPrice: price, unitName: unit['name'].toString(), baseQuantity: baseQty));
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
            if (product != null) TextButton(onPressed: () => Navigator.pop(dialogContext, {'delete': 'yes'}), child: const Text('حذف الصنف')),
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
    if (result['delete'] == 'yes') { setState(() => _products.remove(product)); await _saveProducts(); return; }
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
    final targetProduct = _products.firstWhere((p) => p.name == name);
    if (mounted) {
      final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('إعداد وحدات المنتج'),
        content: const Text('هل تريد تعريف وحدات البيع والتوريد الآن؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لاحقاً')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إعداد الوحدات')),
        ],
      ));
      if (yes == true) await _configureUnits(targetProduct);
    }
  }

  void _removeCartLine(int index) => setState(() => _cart.removeAt(index));


  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الأصناف أولاً لإضافتها إلى الفاتورة')));
      return;
    }
    final mode = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('نوع البيع'),
      content: const Text('اختر طريقة تسجيل هذه الفاتورة'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, 'cash'), child: const Text('نقدي')),
        FilledButton(onPressed: () => Navigator.pop(ctx, 'credit'), child: const Text('آجل')),
      ],
    ));
    if (mode == null) return;
    String? customer;
    double paid = _total;
    if (mode == 'credit') {
      if (_customers.isEmpty) {
        final add = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('لا يوجد زبائن مسجلون'),
          content: const Text('يجب إضافة الزبون قبل تسجيل البيع الآجل.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة زبون')),
          ],
        ));
        if (add == true) await _manageCustomers();
      }
      if (_customers.isEmpty) return;
      customer = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
        title: const Text('اختر الزبون'),
        children: _customers.map((c) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, c['name'] as String), child: Text(c['name'] as String))).toList(),
      ));
      if (customer == null) return;
      paid = await _askAmount('المبلغ المدفوع الآن', 'اكتب 0 إذا لم يدفع شيئاً') ?? 0;
      if (paid > _total) paid = _total;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد البيع'),
      content: Text('الإجمالي: ${_money(_total)}\nالمدفوع: ${_money(paid)}\nالمتبقي: ${_money(_total-paid)}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ الفاتورة')),
      ],
    ));
    if (confirmed != true) return;
    final nextNumber = _invoices.isEmpty ? 1 : _invoices.map((i) => i.number).reduce((a,b) => a>b?a:b)+1;
    final invoice = Invoice(
      number: nextNumber, date: DateTime.now(),
      items: _cart.map((line) => {'name': line.name, 'quantity': line.quantity, 'unit': line.unitName, 'baseQuantity': line.baseQuantity ?? line.quantity, 'unitPrice': line.unitPrice, 'lineTotal': line.total}).toList(),
      total: _total, customerName: customer, paidAmount: paid,
    );
    setState(() {
      for (final line in _cart) {
        Product? p;
        for (final candidate in _products) { if (candidate.name == line.name) { p = candidate; break; } }
        if (p != null) p.stock -= line.baseQuantity ?? line.quantity;
      }
      _invoices.add(invoice); _cart.clear(); _quantityText = '1'; _quantityTouched = false;
    });
    await _saveProducts();
    await _saveInvoices();
    if (mounted) {
      await _showInvoice(invoice);
      if (mounted) await _shareInvoice(invoice);
    }
  }

  Widget _key(String label, {VoidCallback? onTap, bool accent = false}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        height: 39,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: accent ? Theme.of(context).colorScheme.primaryContainer : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );

  Widget _buildKeypad() => Card(
    margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Row(
            children: [
              const Text('الكمية المطلوبة', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_quantityLabel(_selectedQuantity),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
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
          height: 150,
          child: GridView.builder(
            scrollDirection: Axis.vertical,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, crossAxisSpacing: 4, mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _addToCart(product),
                  onLongPress: () => _editProduct(product),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(product.price > 0 ? '${_money(product.price)} / كيلو' : 'حدد السعر',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
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
                      Expanded(flex: 2, child: Text('${_quantityLabel(line.quantity)} ${line.unitName}',
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
                    Expanded(flex: 2, child: Text('${_quantityLabel((item['quantity'] as num).toDouble())} ${item['unit'] ?? 'كيلو'}',
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
                const SizedBox(height: 8),
                Text('المدفوع: ${_money(invoice.paidAmount)}'),
                Text('المتبقي: ${_money(invoice.total-invoice.paidAmount)}'),
                const SizedBox(height: 12),
                const Text('شكراً لتعاملكم معنا'),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => _shareInvoice(invoice), child: const Text('مشاركة الفاتورة')), TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
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


  static const _customersKey = 'naeemsoft_customers_v1';
  static const _suppliersKey = 'naeemsoft_suppliers_v1';
  static const _purchasesKey = 'naeemsoft_purchases_v1';
  final List<Map<String, dynamic>> _customers = [];
  final List<Map<String, dynamic>> _suppliers = [];
  final List<Map<String, dynamic>> _purchases = [];

  Future<void> _saveExtra() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_customersKey, jsonEncode(_customers));
    await p.setString(_suppliersKey, jsonEncode(_suppliers));
    await p.setString(_purchasesKey, jsonEncode(_purchases));
    await p.setString(_receiptsKey, jsonEncode(_receipts));
    await p.setString(_returnsKey, jsonEncode(_returns));
    await p.setString(_languageKey, _language);
  }

  Future<String?> _askText(String title, String label, {String initial = ''}) async {
    final c = TextEditingController(text: initial);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim()); }, child: const Text('حفظ')),
      ],
    ));
    c.dispose();
    return result;
  }

  Future<double?> _askAmount(String title, String label) async {
    final c = TextEditingController();
    final result = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
          if (v != null && v > 0) Navigator.pop(ctx, v);
        }, child: const Text('حفظ')),
      ],
    ));
    c.dispose();
    return result;
  }

  Future<void> _manageCustomers() async {
    while (mounted) {
      final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl, child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('إدارة الزبائن', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.person_add), title: const Text('إضافة زبون'), onTap: () => Navigator.pop(ctx, 'add')),
          ..._customers.map((c) => ListTile(leading: const Icon(Icons.person), title: Text(c['name']),
            subtitle: Text('الرصيد: ${_money(_customerBalance(c['name']))}'),
            trailing: IconButton(icon: const Icon(Icons.account_balance_wallet), onPressed: () => Navigator.pop(ctx, 'pay:${c['name']}')),
            onTap: () => Navigator.pop(ctx, 'statement:${c['name']}'))),
        ]))));
      if (action == null) break;
      if (action == 'add') {
        final name = await _askText('إضافة زبون', 'اسم الزبون');
        if (name != null && !_customers.any((c) => c['name'] == name)) {
          final phone = await _askText('رقم الهاتف', 'رقم الهاتف (اختياري)') ?? '';
          _customers.add({'name': name, 'phone': phone});
          await _saveExtra();
        }
      } else if (action.startsWith('pay:')) {
        await _recordCustomerPayment(action.substring(4));
      } else if (action.startsWith('statement:')) {
        await _showCustomerStatement(action.substring(10));
      }
    }
  }

  double _customerBalance(String name) => _invoices.where((i) => (i.customerName ?? '') == name)
    .fold(0.0, (v, i) => v + i.total - i.paidAmount);
  double _supplierBalance(String name) => _purchases.where((p) => p['supplier'] == name)
    .fold(0.0, (v, p) => v + (p['total'] as num).toDouble() - (p['paid'] as num).toDouble());

  Future<void> _recordCustomerPayment(String name) async {
    final amount = await _askAmount('استلام دفعة من $name', 'مبلغ الدفعة');
    if (amount == null) return;
    var remaining = amount;
    for (final i in _invoices.where((x) => x.customerName == name && x.paidAmount < x.total).toList()) {
      final due = i.total - i.paidAmount;
      final add = remaining < due ? remaining : due;
      i.paidAmount += add;
      remaining -= add;
      if (remaining <= 0) break;
    }
    await _saveInvoices();
    if (mounted) setState(() {});
  }

  Future<void> _manageSuppliers() async {
    while (mounted) {
      final action = await showModalBottomSheet<String>(context: context, builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl, child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('الموردون والمشتريات', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.person_add), title: const Text('إضافة مورد'), onTap: () => Navigator.pop(ctx, 'add')),
          ListTile(leading: const Icon(Icons.add_shopping_cart), title: const Text('تسجيل مشتريات من مورد'), onTap: () => Navigator.pop(ctx, 'purchase')),
          ..._suppliers.map((v) => ListTile(leading: const Icon(Icons.local_shipping), title: Text(v['name']),
            subtitle: Text('المستحق: ${_money(_supplierBalance(v['name']))}'),
            trailing: IconButton(icon: const Icon(Icons.payment), onPressed: () => Navigator.pop(ctx, 'pay:${v['name']}')),
            onTap: () => Navigator.pop(ctx, 'statement:${v['name']}'))),
        ]))));
      if (action == null) break;
      if (action == 'add') {
        final name = await _askText('إضافة مورد', 'اسم المورد');
        if (name != null && !_suppliers.any((v) => v['name'] == name)) {
          final phone = await _askText('رقم الهاتف', 'رقم الهاتف (اختياري)') ?? '';
          _suppliers.add({'name': name, 'phone': phone});
          await _saveExtra();
        }
      } else if (action == 'purchase') {
        if (_suppliers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مورداً أولاً')));
        } else {
          final supplier = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
            title: const Text('اختر المورد'),
            children: _suppliers.map((v) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, v['name']), child: Text(v['name']))).toList(),
          ));
          if (supplier != null) {
            final total = await _askAmount('مشتريات من $supplier', 'إجمالي قيمة المشتريات');
            if (total != null) {
              final paid = await _askAmount('المبلغ المدفوع الآن', 'اكتب 0 إذا كانت آجلة') ?? 0;
              _purchases.add({'supplier': supplier, 'date': DateTime.now().toIso8601String(),
                'total': total, 'paid': paid > total ? total : paid});
              await _saveExtra();
              if (mounted) setState(() {});
            }
          }
        }
      } else if (action.startsWith('pay:')) {
        final name = action.substring(4);
        final amount = await _askAmount('سداد للمورد $name', 'مبلغ السداد');
        if (amount != null) {
          var left = amount;
          for (final p in _purchases.where((x) => x['supplier'] == name).toList()) {
            final due = (p['total'] as num).toDouble() - (p['paid'] as num).toDouble();
            final add = left < due ? left : due;
            p['paid'] = (p['paid'] as num).toDouble() + add;
            left -= add;
            if (left <= 0) break;
          }
          await _saveExtra();
          if (mounted) setState(() {});
        }
      } else if (action.startsWith('statement:')) {
        await _showSupplierStatement(action.substring(10));
      }
    }
  }

  Future<void> _showCustomerStatement(String name) async {
    final rows = _invoices.where((i) => i.customerName == name).toList();
    final body = rows.map((i) => 'فاتورة ${i.number} | ${i.date.toLocal()} | ${_money(i.total)} | مدفوع ${_money(i.paidAmount)} | متبقي ${_money(i.total-i.paidAmount)}').join('\n');
    await _showTextReport('كشف حساب الزبون: $name', '$body\nالرصيد المتبقي: ${_money(_customerBalance(name))}');
  }

  Future<void> _showSupplierStatement(String name) async {
    final rows = _purchases.where((p) => p['supplier'] == name).toList();
    final body = rows.map((p) => 'شراء | ${p['date']} | ${_money((p['total'] as num).toDouble())} | مدفوع ${_money((p['paid'] as num).toDouble())}').join('\n');
    await _showTextReport('كشف حساب المورد: $name', '$body\nالمستحق: ${_money(_supplierBalance(name))}');
  }

  Future<void> _showTextReport(String title, String body) async {
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: SelectableText(body)),
      actions: [
        TextButton(onPressed: () => _shareReport(title, body), child: const Text('مشاركة PDF')),
        TextButton(onPressed: () => _printReport(title, body), child: const Text('طباعة / PDF')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
      ],
    ));
  }

  Future<void> _printReport(String title, String body) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(title, textDirection: pw.TextDirection.rtl, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text(body, textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(fontSize: 11)),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _shareReport(String title, String body) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(title, textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text(body, textDirection: pw.TextDirection.rtl,
          style: const pw.TextStyle(fontSize: 11)),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'naeemsoft-report.pdf');
  }

  Future<void> _showReports() async {
    final now = DateTime.now();
    final today = _invoices.where((i) => i.date.year == now.year && i.date.month == now.month && i.date.day == now.day).toList();
    final sales = today.fold(0.0, (v, i) => v + i.total);
    final cash = today.where((i) => i.customerName == null).fold(0.0, (v, i) => v + i.total);
    final credit = today.where((i) => i.customerName != null).fold(0.0, (v, i) => v + i.total);
    final collected = today.fold(0.0, (v, i) => v + i.paidAmount);
    final daily = 'التاريخ: ${now.toLocal()}\nعدد الفواتير: ${today.length}\nالنقدي: ${_money(cash)}\nالآجل: ${_money(credit)}\nالمقبوض: ${_money(collected)}\nالمتبقي: ${_money(sales-collected)}\nإجمالي المبيعات: ${_money(sales)}\n\n' +
      today.map((i) => 'فاتورة ${i.number} | ${i.date.hour}:${i.date.minute.toString().padLeft(2,'0')} | ${_money(i.total)}').join('\n');
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl, child: SafeArea(child: Wrap(children: [
        const ListTile(title: Text('التقارير', style: TextStyle(fontWeight: FontWeight.bold))),
        ListTile(leading: const Icon(Icons.today), title: const Text('تقرير مبيعات اليوم'), subtitle: Text('الإجمالي: ${_money(sales)}'),
          onTap: () { Navigator.pop(ctx); _showTextReport('تقرير مبيعات اليوم', daily); }),
        ListTile(leading: const Icon(Icons.receipt_long), title: const Text('تقرير جميع المبيعات'),
          onTap: () { Navigator.pop(ctx); final b = _invoices.map((i) => 'فاتورة ${i.number} | ${i.date.toLocal()} | ${_money(i.total)}').join('\n'); _showTextReport('تقرير المبيعات', b); }),
        ListTile(leading: const Icon(Icons.people), title: const Text('أرصدة الزبائن'),
          onTap: () { Navigator.pop(ctx); final b = _customers.map((c) => '${c['name']}: ${_money(_customerBalance(c['name']))}').join('\n'); _showTextReport('أرصدة الزبائن', b); }),
        ListTile(leading: const Icon(Icons.local_shipping), title: const Text('أرصدة الموردين والمشتريات'),
          onTap: () { Navigator.pop(ctx); final b = _suppliers.map((v) => '${v['name']}: ${_money(_supplierBalance(v['name']))}').join('\n') + '\nإجمالي المشتريات: ${_money(_purchases.fold(0.0,(v,p)=>v+(p['total'] as num).toDouble()))}'; _showTextReport('تقرير الموردين والمشتريات', b); }),
        ListTile(leading: const Icon(Icons.account_balance), title: const Text('تقرير الديون المستحقة'),
          onTap: () { Navigator.pop(ctx); final b = 'ديون الزبائن: ${_money(_customers.fold(0.0,(v,c)=>v+_customerBalance(c['name'])))}\nمستحقات الموردين: ${_money(_suppliers.fold(0.0,(v,s)=>v+_supplierBalance(s['name'])))}'; _showTextReport('تقرير الديون', b); }),
      ]))));
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    final lines = invoice.items.map((item) => '${item['name']} | ${_quantityLabel((item['quantity'] as num).toDouble())} ${item['unit'] ?? 'كيلو'} | ${_money((item['lineTotal'] as num).toDouble())}').join('\n');
    final customer = invoice.customerName == null ? 'نقدي' : 'آجل - ${invoice.customerName}';
    final body = 'NaeemSoft POS\nفاتورة رقم ${invoice.number}\n${invoice.date.toLocal()}\nنوع البيع: $customer\n$lines\nالإجمالي: ${_money(invoice.total)}\nالمدفوع: ${_money(invoice.paidAmount)}\nالمتبقي: ${_money(invoice.total-invoice.paidAmount)}\nشكراً لتعاملكم معنا';
    await Share.share(body, subject: 'فاتورة رقم ${invoice.number}');
  }


  Future<void> _chooseLanguage() async {
    final v = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Language / Langue / اللغة'),
      children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'ar'), child: const Text('العربية')),
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'fr'), child: const Text('Français')),
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'en'), child: const Text('English')),
      ],
    ));
    if (v != null) {
      setState(() => _language = v);
      final p = await SharedPreferences.getInstance();
      await p.setString(_languageKey, v);
    }
  }

  Future<void> _configureUnits(Product product) async {
    final names = TextEditingController(text: product.units.map((e) => e['name']).join(','));
    final factors = TextEditingController(text: product.units.map((e) => e['factor'].toString()).join(','));
    final prices = TextEditingController(text: product.units.map((e) => e['price'].toString()).join(','));
    final values = await showDialog<List<List<String>>>(context: context, builder: (ctx) => AlertDialog(
      title: Text('وحدات المنتج: ' + product.name),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('اكتب الوحدات من الأصغر إلى الأكبر، وافصل بينها بفاصلة. المعامل هو عدد الوحدات الأساسية داخل الوحدة.'),
        TextField(controller: names, decoration: const InputDecoration(labelText: 'الوحدات: عبوة, باكت, كرتون')),
        TextField(controller: factors, decoration: const InputDecoration(labelText: 'المعاملات: 1, 6, 72')),
        TextField(controller: prices, decoration: const InputDecoration(labelText: 'أسعار البيع: 100, 550, 6000')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final a = names.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          final b = factors.text.split(',').map((e) => e.trim()).toList();
          final c = prices.text.split(',').map((e) => e.trim()).toList();
          if (a.isNotEmpty && a.length == b.length && a.length == c.length) Navigator.pop(ctx, [a,b,c]);
        }, child: const Text('حفظ')),
      ],
    ));
    names.dispose(); factors.dispose(); prices.dispose();
    if (values == null) return;
    final parsed = <Map<String, dynamic>>[];
    for (var i=0; i<values[0].length; i++) {
      final f = double.tryParse(values[1][i]);
      final p = double.tryParse(values[2][i]);
      if (f == null || f <= 0 || p == null || p < 0 || (i > 0 && f <= (parsed.last['factor'] as num).toDouble())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المعاملات يجب أن تكون موجبة ومتزايدة والأسعار صحيحة.')));
        return;
      }
      parsed.add({'name': values[0][i], 'factor': f, 'price': p});
    }
    setState(() { product.units = parsed; product.price = (parsed.first['price'] as num).toDouble(); });
    await _saveProducts();
  }

  Future<void> _inventoryMenu() async {
    final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      const ListTile(title: Text('المخزون والتوريد والمرتجعات')),
      ListTile(leading: const Icon(Icons.inventory), title: const Text('رصيد المخزون'), onTap: () => Navigator.pop(ctx, 'stock')),
      ListTile(leading: const Icon(Icons.local_shipping), title: const Text('استلام توريد'), onTap: () => Navigator.pop(ctx, 'receive')),
      ListTile(leading: const Icon(Icons.assignment_return), title: const Text('مرتجع عميل'), onTap: () => Navigator.pop(ctx, 'customer')),
      ListTile(leading: const Icon(Icons.keyboard_return), title: const Text('مرتجع إلى المورد'), onTap: () => Navigator.pop(ctx, 'supplier')),
    ])));
    if (choice == 'stock') {
      final body = _products.map((p) => p.name + ': ' + _quantityLabel(p.stock) + ' وحدة أساسية | ' + p.units.map((x) => (p.stock / (x['factor'] as num).toDouble()).toStringAsFixed(2) + ' ' + x['name'].toString()).join(' / ')).join('\n');
      await _showTextReport('رصيد المخزون', body.isEmpty ? 'لا توجد منتجات' : body);
    } else if (choice == 'receive') {
      await _receiveStock();
    } else if (choice == 'customer' || choice == 'supplier') {
      await _processReturn(choice == 'customer');
    }
  }

  Future<Product?> _selectProduct(String title) => showDialog<Product>(context: context, builder: (ctx) => SimpleDialog(
    title: Text(title),
    children: _products.map((p) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, p), child: Text(p.name))).toList(),
  ));

  Future<Map<String, dynamic>?> _selectUnit(Product p, String title) => showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => SimpleDialog(
    title: Text(title),
    children: p.units.map((u) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, u), child: Text(u['name'].toString() + '  × ' + u['factor'].toString()))).toList(),
  ));

  Future<void> _receiveStock() async {
    if (_suppliers.isEmpty || _products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مورداً ومنتجاً أولاً.')));
      return;
    }
    final supplier = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('اختر المورد'),
      children: _suppliers.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s['name'] as String), child: Text(s['name'] as String))).toList(),
    ));
    if (supplier == null) return;
    final product = await _selectProduct('اختر المنتج المستلم');
    if (product == null) return;
    final unit = await _selectUnit(product, 'وحدة التوريد');
    if (unit == null) return;
    final qty = await _askAmount('كمية الاستلام', 'الكمية');
    if (qty == null) return;
    final cost = await _askAmount('قيمة فاتورة الشراء', 'الإجمالي');
    if (cost == null) return;
    final paid = await _askAmount('المبلغ المدفوع', 'اتركه فارغاً إن لم تدفع') ?? 0;
    final base = qty * (unit['factor'] as num).toDouble();
    setState(() {
      product.stock += base;
      _receipts.add({'supplier': supplier, 'product': product.name, 'quantity': qty, 'unit': unit['name'], 'baseQuantity': base, 'cost': cost, 'date': DateTime.now().toIso8601String()});
    });
    await _saveExtra();
    await _saveProducts();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الاستلام وإضافة ' + _quantityLabel(base) + ' إلى المخزون.')));
  }

  Future<void> _processReturn(bool customerReturn) async {
    final p = await _selectProduct('اختر المنتج');
    if (p == null) return;
    final u = await _selectUnit(p, 'اختر وحدة المرتجع');
    if (u == null) return;
    final q = await _askAmount('كمية المرتجع', 'الكمية');
    if (q == null) return;
    final base = q * (u['factor'] as num).toDouble();
    if (!customerReturn && base > p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ لإرجاع هذه الكمية.')));
      return;
    }
    final reason = await _askText('سبب المرتجع', 'السبب') ?? 'غير محدد';
    setState(() {
      p.stock += customerReturn ? base : -base;
      _returns.add({'type': customerReturn ? 'customer' : 'supplier', 'product': p.name, 'quantity': q, 'unit': u['name'], 'baseQuantity': base, 'reason': reason, 'date': DateTime.now().toIso8601String()});
    });
    await _saveProducts();
    await _saveExtra();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(customerReturn ? 'أعيدت الكمية إلى المخزون.' : 'تم خصم الكمية المرتجعة من المخزون.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NaeemSoft POS', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        PopupMenuButton<String>(onSelected: (v) { if (v == 'reports') _showReports(); if (v == 'customers') _manageCustomers(); if (v == 'suppliers') _manageSuppliers(); if (v == 'history') _showHistory(); if (v == 'inventory') _inventoryMenu(); if (v == 'language') _chooseLanguage(); }, itemBuilder: (_) => const [
          PopupMenuItem(value: 'reports', child: Text('التقارير')),
          PopupMenuItem(value: 'customers', child: Text('الزبائن وكشوف الحساب')),
          PopupMenuItem(value: 'suppliers', child: Text('الموردون والمشتريات')),
          PopupMenuItem(value: 'history', child: Text('سجل الفواتير')),
          PopupMenuItem(value: 'inventory', child: Text('المخزون والتوريد والمرتجعات')),
          PopupMenuItem(value: 'language', child: Text('Language / Langue / اللغة')),
        ]),
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
