import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShopDb.instance.open();
  runApp(const NaeemSoftApp());
}

class ShopDb {
  ShopDb._();
  static final instance = ShopDb._();
  late Database db;

  Future<void> open() async {
    final base = await getDatabasesPath();
    db = await openDatabase(
      p.join(base, 'naeemsoft_shop.db'),
      version: 1,
      onCreate: (d, v) async {
        await d.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, purchase_unit TEXT NOT NULL DEFAULT "جوان", base_unit TEXT NOT NULL DEFAULT "كجم", default_weight REAL NOT NULL DEFAULT 1, cost REAL NOT NULL DEFAULT 0, sale_price REAL NOT NULL DEFAULT 0, stock REAL NOT NULL DEFAULT 0)');
        await d.execute('CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT)');
        await d.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, payment_term TEXT NOT NULL DEFAULT "نقدي")');
        await d.execute('CREATE TABLE purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER, date TEXT NOT NULL, total REAL NOT NULL, paid REAL NOT NULL, note TEXT)');
        await d.execute('CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL, product_id INTEGER NOT NULL, unit TEXT NOT NULL, packages REAL NOT NULL, weight_each REAL NOT NULL, quantity REAL NOT NULL, unit_cost REAL NOT NULL, line_total REAL NOT NULL)');
        await d.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, date TEXT NOT NULL, total REAL NOT NULL, paid REAL NOT NULL)');
        await d.execute('CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity REAL NOT NULL, unit_price REAL NOT NULL, line_total REAL NOT NULL)');
        await d.execute('CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, party_type TEXT NOT NULL, party_id INTEGER NOT NULL, date TEXT NOT NULL, amount REAL NOT NULL, note TEXT)');
      },
    );
  }

  Future<List<Map<String, Object?>>> rows(String table) => db.query(table, orderBy: 'id DESC');

  Future<int> addProduct(String name, String unit, double weight, double cost, double price) =>
      db.insert('products', {'name': name, 'purchase_unit': unit, 'default_weight': weight, 'cost': cost, 'sale_price': price});

  Future<void> savePurchase({required int? supplierId, required List<Map<String, dynamic>> items, required double paid}) async {
    await db.transaction((tx) async {
      double total = 0;
      for (final item in items) { total += (item['quantity'] as num).toDouble() * (item['cost'] as num).toDouble(); }
      final id = await tx.insert('purchases', {'supplier_id': supplierId, 'date': DateTime.now().toIso8601String(), 'total': total, 'paid': paid});
      for (final item in items) {
        final qty = (item['quantity'] as num).toDouble();
        final cost = (item['cost'] as num).toDouble();
        await tx.insert('purchase_items', {'purchase_id': id, 'product_id': item['id'], 'unit': item['unit'], 'packages': item['packages'], 'weight_each': item['weight'], 'quantity': qty, 'unit_cost': cost, 'line_total': qty * cost});
        await tx.rawUpdate('UPDATE products SET stock = stock + ?, cost = ? WHERE id = ?', [qty, cost, item['id']]);
      }
    });
  }

  Future<void> saveSale({required int? customerId, required List<Map<String, dynamic>> items, required double paid}) async {
    await db.transaction((tx) async {
      double total = 0;
      for (final item in items) {
        final qty = (item['quantity'] as num).toDouble();
        final price = (item['price'] as num).toDouble();
        final product = (await tx.query('products', where: 'id = ?', whereArgs: [item['id']], limit: 1)).first;
        if ((product['stock'] as num).toDouble() < qty) throw Exception('الكمية غير كافية للصنف ' + (product['name'] as String));
        total += qty * price;
      }
      final id = await tx.insert('sales', {'customer_id': customerId, 'date': DateTime.now().toIso8601String(), 'total': total, 'paid': paid});
      for (final item in items) {
        final qty = (item['quantity'] as num).toDouble();
        final price = (item['price'] as num).toDouble();
        await tx.insert('sale_items', {'sale_id': id, 'product_id': item['id'], 'quantity': qty, 'unit_price': price, 'line_total': qty * price});
        await tx.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [qty, item['id']]);
      }
    });
  }

  Future<void> addPayment(String type, int partyId, double amount, String note) async {
    await db.insert('payments', {'party_type': type, 'party_id': partyId, 'date': DateTime.now().toIso8601String(), 'amount': amount, 'note': note});
  }
}

class NaeemSoftApp extends StatelessWidget {
  const NaeemSoftApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NaeemSoft POS',
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff218653)), scaffoldBackgroundColor: const Color(0xfff6f8f6)),
    home: const Directionality(textDirection: TextDirection.rtl, child: MainShell()),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final titles = const ['الرئيسية', 'المبيعات', 'التوريد', 'مخزون المحل', 'الأصناف'];
  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardPage(), const SalePage(), const PurchasePage(), const StockPage(), const ProductsPage()];
    return Scaffold(
      appBar: AppBar(title: Text('NaeemSoft POS • ' + titles[index]), centerTitle: false),
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'بيع'),
        NavigationDestination(icon: Icon(Icons.add_shopping_cart), label: 'توريد'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'المخزون'),
        NavigationDestination(icon: Icon(Icons.category_outlined), label: 'الأصناف'),
      ]),
    );
  }
}

String money(num v) => NumberFormat('#,##0.##', 'en').format(v) + ' DJF';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  Future<Map<String, num>> load() async {
    final db = ShopDb.instance.db;
    final stock = await db.rawQuery('SELECT COUNT(*) c, COALESCE(SUM(stock * cost),0) v FROM products');
    final sales = await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM sales WHERE date LIKE ?", [DateTime.now().toIso8601String().substring(0,10) + '%']);
    final purchases = await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM purchases WHERE date LIKE ?", [DateTime.now().toIso8601String().substring(0,10) + '%']);
    return {'count': (stock.first['c'] as num), 'value': (stock.first['v'] as num), 'sales': (sales.first['v'] as num), 'purchases': (purchases.first['v'] as num)};
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String,num>>(future: load(), builder: (context,s) {
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final d=s.data!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('مبيعات اليوم'), const SizedBox(height: 8), Text(money(d['sales']!), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))]))),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: metric('عدد الأصناف', d['count']!.toStringAsFixed(0), Icons.category)), const SizedBox(width: 10), Expanded(child: metric('قيمة المخزون', money(d['value']!), Icons.inventory))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: metric('مشتريات اليوم', money(d['purchases']!), Icons.local_shipping)), const SizedBox(width: 10), Expanded(child: metric('حالة النظام', 'يعمل محلياً', Icons.offline_bolt))]),
      const Padding(padding: EdgeInsets.only(top: 20), child: Text('ابدأ من شريط التنقل بالأسفل. كل توريد يضيف إلى مخزون المحل وكل بيع يخصم منه تلقائياً.', style: TextStyle(height: 1.7))),
    ]);
  });
  Widget metric(String title,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Colors.green),const SizedBox(height:8),Text(title),const SizedBox(height:4),Text(value,style:const TextStyle(fontWeight:FontWeight.bold))])));
}

class ProductsPage extends StatefulWidget { const ProductsPage({super.key}); @override State<ProductsPage> createState()=>_ProductsPageState(); }
class _ProductsPageState extends State<ProductsPage> {
  Future<void> add() async {
    final name=TextEditingController(), unit=TextEditingController(text:'جوان'), weight=TextEditingController(text:'1'), cost=TextEditingController(text:'0'), price=TextEditingController(text:'0');
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('صنف جديد'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[field(name,'اسم الصنف'),field(unit,'وحدة الشراء'),field(weight,'الوزن الافتراضي للوحدة'),field(cost,'تكلفة الكيلو'),field(price,'سعر بيع الكيلو')])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
    if(ok==true && name.text.trim().isNotEmpty){await ShopDb.instance.addProduct(name.text.trim(),unit.text.trim(),double.tryParse(weight.text)??1,double.tryParse(cost.text)??0,double.tryParse(price.text)??0); if(mounted)setState((){});}
  }
  @override Widget build(BuildContext context)=>Scaffold(body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.rows('products'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:[...s.data!.map((p)=>ListTile(title:Text(p['name'] as String),subtitle:Text('وحدة الشراء: '+(p['purchase_unit'] as String)+' • سعر البيع: '+money(p['sale_price'] as num)),trailing:Text((p['stock'] as num).toString()+' كجم')))]);}),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة صنف')));
}

class SalePage extends StatefulWidget { const SalePage({super.key}); @override State<SalePage> createState()=>_SalePageState(); }
class _SalePageState extends State<SalePage> {
  final Map<int,Map<String,dynamic>> cart={};
  Future<void> add(Map<String,Object?> p) async {
    final q=TextEditingController(text:'1');
    final result=await showDialog<double>(context:context,builder:(c)=>AlertDialog(title:Text('بيع '+(p['name'] as String)),content:field(q,'الكمية بالكيلو'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,double.tryParse(q.text)),child:const Text('إضافة للسلة'))]));
    if(result!=null && result>0){setState(()=>cart[p['id'] as int]={'id':p['id'],'name':p['name'],'quantity':result,'price':p['sale_price']});}
  }
  double get total=>cart.values.fold(0,(v,e)=>v+(e['quantity'] as double)*(e['price'] as num).toDouble());
  Future<void> checkout() async {
    if(cart.isEmpty)return;
    final paid=TextEditingController(text:total.toStringAsFixed(0));
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('إنهاء البيع'),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('الإجمالي: '+money(total)),field(paid,'المبلغ المدفوع')]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('تأكيد البيع'))]));
    if(ok==true){try{await ShopDb.instance.saveSale(customerId:null,items:cart.values.toList(),paid:double.tryParse(paid.text)??0);cart.clear();if(mounted)setState((){}); }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  }
  @override Widget build(BuildContext context)=>Column(children:[Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.rows('products'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return GridView.builder(padding:const EdgeInsets.all(10),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:2.2,crossAxisSpacing:8,mainAxisSpacing:8),itemCount:s.data!.length,itemBuilder:(c,i){final p=s.data![i];return Card(child:InkWell(onTap:()=>add(p),borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.all(10),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(p['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),Text(money(p['sale_price'] as num)),Text('المتاح: '+(p['stock'] as num).toString()+' كجم',style:Theme.of(context).textTheme.bodySmall)]))));});})),Container(padding:const EdgeInsets.all(12),color:Theme.of(context).colorScheme.surface,child:Column(children:[Text('أصناف السلة: '+cart.length.toString()+'   الإجمالي: '+money(total),style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:checkout,icon:const Icon(Icons.check),label:const Text('إتمام البيع')))]))]);
}

class PurchasePage extends StatefulWidget { const PurchasePage({super.key}); @override State<PurchasePage> createState()=>_PurchasePageState(); }
class _PurchasePageState extends State<PurchasePage> {
  final cart=<Map<String,dynamic>>[];
  Future<void> add(Map<String,Object?> p) async {
    final packs=TextEditingController(text:'1'), weight=TextEditingController(text:(p['default_weight'] as num).toString()), cost=TextEditingController(text:(p['cost'] as num).toString());
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('توريد '+(p['name'] as String)),content:Column(mainAxisSize:MainAxisSize.min,children:[field(packs,'عدد الوحدات'),field(weight,'وزن الوحدة بالكيلو'),field(cost,'تكلفة الكيلو')]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إضافة'))]));
    if(ok==true){final n=double.tryParse(packs.text)??0,w=double.tryParse(weight.text)??0,k=double.tryParse(cost.text)??0;if(n>0&&w>0){setState(()=>cart.add({'id':p['id'],'name':p['name'],'unit':p['purchase_unit'],'packages':n,'weight':w,'quantity':n*w,'cost':k}));}}
  }
  double get total=>cart.fold(0,(v,e)=>v+(e['quantity'] as double)*(e['cost'] as double));
  Future<void> save() async {if(cart.isEmpty)return;try{await ShopDb.instance.savePurchase(supplierId:null,items:cart,paid:0);cart.clear();if(mounted)setState((){});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  @override Widget build(BuildContext context)=>Column(children:[Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.rows('products'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.map((p)=>ListTile(title:Text(p['name'] as String),subtitle:Text('وحدة الشراء: '+(p['purchase_unit'] as String)),trailing:const Icon(Icons.add_circle_outline),onTap:()=>add(p)).toList());})),Container(padding:const EdgeInsets.all(12),child:Column(children:[Text('أصناف الفاتورة: '+cart.length.toString()+' • الإجمالي: '+money(total)),const SizedBox(height:8),SizedBox(width:double.infinity,child:FilledButton(onPressed:save,child:const Text('ترحيل التوريد إلى مخزون المحل')))]))]);
}

class StockPage extends StatelessWidget { const StockPage({super.key}); @override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.rows('products'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.map((p)=>ListTile(title:Text(p['name'] as String),subtitle:Text('التكلفة: '+money(p['cost'] as num)+' • البيع: '+money(p['sale_price'] as num)),trailing:Text((p['stock'] as num).toString()+' كجم'))).toList());}); }

Widget field(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),isDense:true)));
