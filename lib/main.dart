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

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  static const _storageKey = 'naeemsoft_products_v1';
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

  Future<void> _completeSale() async {
    if (_products.every((p) => p.quantity == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كمية صنف واحد على الأقل')),
      );
      return;
    }
    final total = _total;
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
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        for (final product in _products) {
          product.quantity = 0;
          _quantityControllers[product.name]?.clear();
        }
      });
      await _save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تسجيل البيع بقيمة ${_money(total)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NaeemSoft POS',
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
