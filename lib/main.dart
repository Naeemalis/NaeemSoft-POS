import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'shop_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShopDb.instance.open();
  runApp(const NaeemSoftApp());
}
String money(num n) => NumberFormat('#,##0', 'en').format(n) + ' DJF';
String kg(num g) => (g / 1000).toStringAsFixed(3) + ' كجم';
Future<List<Map<String,Object?>>> rows(String t) => ShopDb.instance.query(t);
Widget field(TextEditingController c, String label, {bool number=false}) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: TextField(controller:c, keyboardType:number ? const TextInputType.numberWithOptions(decimal:true) : TextInputType.text,
    decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),isDense:true)));

class NaeemSoftApp extends StatelessWidget {
 const NaeemSoftApp({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(
  title:'NaeemSoft POS',debugShowCheckedModeBanner:false,locale:const Locale('ar'),
  supportedLocales:const [Locale('ar'),Locale('en')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,
  theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff218653))),
  home:const Directionality(textDirection:ui.TextDirection.rtl,child:MainShell()));
}
class MainShell extends StatefulWidget {const MainShell({super.key});@override State<MainShell> createState()=>_MainShellState();}
class _MainShellState extends State<MainShell>{
 int tab=0;
 final labels=const ['الرئيسية','المبيعات','التوريد','المخزون','الإدارة'];
 final pages=const [DashboardPage(),SalePage(),PurchasePage(),StockPage(),AdminPage()];
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text('NaeemSoft POS • '+labels[tab])),body:pages[tab],
  bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
   NavigationDestination(icon:Icon(Icons.home_outlined),label:'الرئيسية'),
   NavigationDestination(icon:Icon(Icons.point_of_sale),label:'بيع'),
   NavigationDestination(icon:Icon(Icons.add_shopping_cart),label:'توريد'),
   NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'المخزون'),
   NavigationDestination(icon:Icon(Icons.settings_outlined),label:'الإدارة')]));
}
class DashboardPage extends StatelessWidget {
 const DashboardPage({super.key});
 Future<List<num>> load() async {
  final d=ShopDb.instance.db;
  final s=await d.rawQuery("SELECT COALESCE(SUM(total),0) v FROM sales WHERE date LIKE ?",[DateTime.now().toIso8601String().substring(0,10)+'%']);
  final p=await d.rawQuery("SELECT COALESCE(SUM(total),0) v FROM purchases WHERE date LIKE ?",[DateTime.now().toIso8601String().substring(0,10)+'%']);
  final q=await d.rawQuery("SELECT COUNT(*) n,COALESCE(SUM(stock_grams),0) g FROM products");
  return [s.first['v'] as num,p.first['v'] as num,q.first['n'] as num,q.first['g'] as num];
 }
 @override Widget build(BuildContext c)=>FutureBuilder<List<num>>(future:load(),builder:(c,s){
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  final x=s.data!;
  return ListView(padding:const EdgeInsets.all(12),children:[
   Card(color:Theme.of(c).colorScheme.primaryContainer,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('مبيعات اليوم'),Text(money(x[0]),style:Theme.of(c).textTheme.headlineMedium)]))),
   ListTile(title:const Text('مشتريات اليوم'),trailing:Text(money(x[1]))),
   ListTile(title:const Text('عدد الأصناف'),trailing:Text(x[2].toString())),
   ListTile(title:const Text('كمية المخزون'),trailing:Text(kg(x[3]))),
   const Padding(padding:EdgeInsets.all(12),child:Text('نظام محلي لمحل واحد. البيع بالكيلو أو حسب المبلغ، والتوريد بوحدات وأوزان متغيرة.',style:TextStyle(height:1.6)))
  ]);
 });
}
class SalePage extends StatefulWidget {const SalePage({super.key});@override State<SalePage> createState()=>_SalePageState();}
class _SalePageState extends State<SalePage>{
 final Map<int,Map<String,dynamic>> cart={};
 int? activeDraftId;
 bool posting=false;
 String keypadValue=''; String saleMode='weight';
 void key(String k){setState((){if(k=='مسح')keypadValue='';else if(k=='⌫'){if(keypadValue.isNotEmpty)keypadValue=keypadValue.substring(0,keypadValue.length-1);}else keypadValue+=k;});}
 Future<void> add(Map<String,Object?> p) async {
  final price=(p['sale_price'] as num).round();
  final value=double.tryParse(keypadValue.replaceAll(',', '.'))??0;
  final grams=saleMode=='weight'?(value*1000).round():(price>0?(value*1000/price).round():0);
  final id=p['id'] as int, old=cart[id]?['grams'] as int? ?? 0;
  final stock=(p['stock_grams'] as num).toInt()-old;
  if(grams<=0||grams>stock||price<=0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(grams>stock?'المخزون غير كافٍ':'أدخل الرقم أولاً')));return;}
  setState((){cart[id]={'product_id':id,'name':p['name'],'grams':old+grams,'price_per_kg':price};keypadValue='';});
 }
 int get total=>cart.values.fold(0,(v,x)=>v+(((x['grams'] as int)*(x['price_per_kg'] as int))/1000).round());
 Future<void> saveDraft() async {
  if(cart.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('السلة فارغة')));return;}
  try{final id=await ShopDb.instance.saveDraft(type:'sale',items:cart.values.toList(),total:total,draftId:activeDraftId);activeDraftId=null;cart.clear();if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حُفظت مسودة فاتورة البيع رقم '+id.toString())));}}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
 }
 Future<void> openDrafts() async {
  final draft=await Navigator.push<Map<String,Object?>>(context,MaterialPageRoute(builder:(_)=>const DraftsPage(type:'sale')));
  if(draft==null)return;
  final items=(draft['items'] as List).cast<Map<String,dynamic>>();
  setState((){activeDraftId=draft['id'] as int;cart.clear();for(final x in items){cart[x['product_id'] as int]=x;}});
 }
 Future<void> checkout() async {
  if(posting||cart.isEmpty)return;
  final customers=await rows('customers');int? customer;
  final paid=TextEditingController(text:total.toString()),due=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
   title:const Text('إتمام البيع'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('الإجمالي: '+money(total)),
    DropdownButtonFormField<int?>(value:null,decoration:const InputDecoration(labelText:'الزبون (اختياري)'),
     items:[const DropdownMenuItem<int?>(value:null,child:Text('نقدي / غير مسجل')),...customers.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],
     onChanged:(v)=>customer=v),
    field(paid,'المبلغ المدفوع',number:true),field(due,'موعد السداد YYYY-MM-DD')
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ترحيل الفاتورة'))])));
  if(ok!=true)return;
  setState(()=>posting=true);
  int? draftId=activeDraftId;
  final paidAmount=int.tryParse(paid.text)??0;
  final dueDate=due.text.trim().isEmpty?null:due.text.trim();
  try{
   if(draftId==null){
    draftId=await ShopDb.instance.saveDraft(type:'sale',items:cart.values.toList(),partyId:customer,total:total,paid:paidAmount,dueDate:dueDate);
   }else{
    await ShopDb.instance.saveDraft(type:'sale',items:cart.values.toList(),partyId:customer,total:total,paid:paidAmount,dueDate:dueDate,draftId:draftId);
   }
   activeDraftId=draftId;
   await ShopDb.instance.saveSale(customerId:customer,items:cart.values.toList(),paid:paidAmount,dueDate:dueDate,draftId:draftId);
   activeDraftId=null;cart.clear();if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }
 @override Widget build(BuildContext c)=>Column(children:[
  Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:rows('products'),builder:(c,s){
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.all(4),itemCount:s.data!.length,itemBuilder:(c,i){
     final p=s.data![i];return SizedBox(width:MediaQuery.of(c).size.width/7.2,child:Card(margin:const EdgeInsets.all(2),child:InkWell(onTap:posting?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(3),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(p['name'] as String,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(money(p['sale_price'] as num),style:const TextStyle(fontSize:11)),Text(kg(p['stock_grams'] as num),style:const TextStyle(fontSize:10))
     ])))));
    });
  })),
  Padding(padding:const EdgeInsets.fromLTRB(5,2,5,4),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Text('السلة: '+cart.length.toString()+' • '+money(total),style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),
   SegmentedButton<String>(segments:const[ButtonSegment(value:'weight',label:Text('وزن')),ButtonSegment(value:'cash',label:Text('نقد'))],selected:{saleMode},onSelectionChanged:(v)=>setState(()=>saleMode=v.first)),
   Text('المدخل: '+(keypadValue.isEmpty?'0':keypadValue)+(saleMode=='cash'?' فرنك':' كجم')),
   Wrap(spacing:3,runSpacing:2,children:[for(final k in ['7','8','9','4','5','6','1','2','3','0','.','⌫','مسح'])SizedBox(width:MediaQuery.of(c).size.width/7.5,height:29,child:OutlinedButton(onPressed:()=>key(k),style:OutlinedButton.styleFrom(padding:EdgeInsets.zero),child:Text(k)))]),

   SizedBox(height:cart.isEmpty?0:58,child:ListView(shrinkWrap:true,children:cart.values.map((x)=>ListTile(dense:true,visualDensity:VisualDensity.compact,contentPadding:EdgeInsets.zero,title:Text(x['name'] as String,style:const TextStyle(fontSize:11)),subtitle:Text(kg(x['grams'] as int),style:const TextStyle(fontSize:10)),trailing:IconButton(visualDensity:VisualDensity.compact,iconSize:16,icon:const Icon(Icons.close),onPressed:posting?null:()=>setState(()=>cart.remove(x['product_id']))))).toList())),
   Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,style:OutlinedButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(vertical:4)),child:const Text('مسودة',style:TextStyle(fontSize:10)))),const SizedBox(width:3),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,style:OutlinedButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(vertical:4)),child:const Text('المسودات',style:TextStyle(fontSize:10))))]),
   const SizedBox(height:2),SizedBox(width:double.infinity,height:34,child:FilledButton(style:FilledButton.styleFrom(visualDensity:VisualDensity.compact),onPressed:posting?null:checkout,child:Text(posting?'جارٍ الترحيل...':'إتمام البيع',style:const TextStyle(fontSize:11))))
  ]))
 ]);
}
class PurchasePage extends StatefulWidget {const PurchasePage({super.key});@override State<PurchasePage> createState()=>_PurchasePageState();}
class _PurchasePageState extends State<PurchasePage>{
 final List<Map<String,dynamic>> cart=[];
 int? activeDraftId;
 bool posting=false;
 String keypadValue=''; String purchaseField='packages'; int packageCount=1,packageWeight=0,packageCost=0;
 void key(String k){setState((){if(k=='مسح')keypadValue='';else if(k=='⌫'){if(keypadValue.isNotEmpty)keypadValue=keypadValue.substring(0,keypadValue.length-1);}else keypadValue+=k;});}
 void applyKeypad(){final v=double.tryParse(keypadValue.replaceAll(',', '.'));if(v==null)return;setState((){if(purchaseField=='packages')packageCount=v.toInt();else if(purchaseField=='weight')packageWeight=(v*1000).round();else packageCost=v.toInt();keypadValue='';});}
 Future<void> add(Map<String,Object?> p) async {
  final count=packageCount, weight=packageWeight>0?packageWeight:((p['default_weight'] as num)*1000).round(), price=packageCost;
  if(count<=0||weight<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حدد العدد والوزن والتكلفة بلوحة الأرقام')));return;}
  setState(()=>cart.add({'product_id':p['id'],'name':p['name'],'unit':p['purchase_unit'],'packages':count,'weight_grams':weight,'package_cost':price}));
 }
 int get total=>cart.fold(0,(v,x)=>v+(x['packages'] as int)*(x['package_cost'] as int));
 Future<void> saveDraft() async {
  if(cart.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الفاتورة فارغة')));return;}
  try{final id=await ShopDb.instance.saveDraft(type:'purchase',items:cart,total:total,draftId:activeDraftId);activeDraftId=null;cart.clear();if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('حُفظت مسودة فاتورة التوريد رقم '+id.toString())));}}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
 }
 Future<void> openDrafts() async {
  final draft=await Navigator.push<Map<String,Object?>>(context,MaterialPageRoute(builder:(_)=>const DraftsPage(type:'purchase')));
  if(draft==null)return;
  final items=(draft['items'] as List).cast<Map<String,dynamic>>();
  setState((){activeDraftId=draft['id'] as int;cart..clear()..addAll(items);});
 }
 Future<void> save() async {
  if(posting||cart.isEmpty)return;final suppliers=await rows('suppliers');int? supplier;
  final paid=TextEditingController(text:'0'),due=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD)=>AlertDialog(
   title:const Text('فاتورة التوريد'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButtonFormField<int?>(value:null,decoration:const InputDecoration(labelText:'المورد'),
     items:suppliers.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String))).toList(),onChanged:(v)=>supplier=v),
    Text('الإجمالي: '+money(total)),field(paid,'المدفوع الآن',number:true),field(due,'موعد السداد YYYY-MM-DD')
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ترحيل'))])));
  if(ok!=true)return;if(supplier==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر المورد أولاً')));return;}
  setState(()=>posting=true);
  int? draftId=activeDraftId;
  final paidAmount=int.tryParse(paid.text)??0;
  final dueDate=due.text.trim().isEmpty?null:due.text.trim();
  try{
   if(draftId==null){
    draftId=await ShopDb.instance.saveDraft(type:'purchase',items:cart,partyId:supplier,total:total,paid:paidAmount,dueDate:dueDate);
   }else{
    await ShopDb.instance.saveDraft(type:'purchase',items:cart,partyId:supplier,total:total,paid:paidAmount,dueDate:dueDate,draftId:draftId);
   }
   activeDraftId=draftId;
   await ShopDb.instance.savePurchase(supplierId:supplier!,items:cart,paid:paidAmount,dueDate:dueDate,draftId:draftId);
   activeDraftId=null;cart.clear();if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }
 @override Widget build(BuildContext c)=>Column(children:[
  Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:rows('products'),builder:(c,s){
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.all(4),itemCount:s.data!.length,itemBuilder:(c,i){
     final p=s.data![i];return SizedBox(width:MediaQuery.of(c).size.width/7.2,child:Card(margin:const EdgeInsets.all(2),child:InkWell(onTap:posting?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(3),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(p['name'] as String,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(p['purchase_unit'] as String,style:const TextStyle(fontSize:11)),const Text('إضافة +',style:TextStyle(fontSize:10))
     ]))));
    });
  })),
  Padding(padding:const EdgeInsets.fromLTRB(5,2,5,4),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Text('سلة التوريد: '+cart.length.toString()+' • '+money(total),style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),
   Wrap(spacing:3,children:[for(final x in ['packages','weight','cost'])ChoiceChip(label:Text(x=='packages'?'عدد الجوان':x=='weight'?'وزن الجوان بالكيلو':'تكلفة الجوان'),selected:purchaseField==x,onSelected:(_)=>setState(()=>purchaseField=x))]),
   Text('الرقم: '+(keypadValue.isEmpty?'0':keypadValue)+' • العدد '+packageCount.toString()+' • الوزن '+(packageWeight/1000).toStringAsFixed(2)+' كجم • التكلفة '+packageCost.toString(),style:const TextStyle(fontSize:10)),
   Wrap(spacing:3,runSpacing:2,children:[for(final k in ['7','8','9','4','5','6','1','2','3','0','.','⌫','مسح'])SizedBox(width:MediaQuery.of(c).size.width/7.5,height:27,child:OutlinedButton(onPressed:()=>key(k),style:OutlinedButton.styleFrom(padding:EdgeInsets.zero),child:Text(k))),FilledButton(onPressed:applyKeypad,child:const Text('اعتماد الرقم'))]),

   SizedBox(height:cart.isEmpty?0:58,child:ListView(shrinkWrap:true,children:cart.map((x)=>ListTile(dense:true,visualDensity:VisualDensity.compact,contentPadding:EdgeInsets.zero,title:Text(x['name'] as String,style:const TextStyle(fontSize:11)),subtitle:Text(x['packages'].toString()+' × '+(x['unit'] as String)+' • '+kg((x['packages'] as int)*(x['weight_grams'] as int)),style:const TextStyle(fontSize:10)),trailing:Text(money((x['packages'] as int)*(x['package_cost'] as int)),style:const TextStyle(fontSize:10)))).toList())),
   Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,style:OutlinedButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(vertical:4)),child:const Text('مسودة',style:TextStyle(fontSize:10)))),const SizedBox(width:3),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,style:OutlinedButton.styleFrom(visualDensity:VisualDensity.compact,padding:const EdgeInsets.symmetric(vertical:4)),child:const Text('المسودات',style:TextStyle(fontSize:10))))]),
   const SizedBox(height:2),SizedBox(width:double.infinity,height:34,child:FilledButton(style:FilledButton.styleFrom(visualDensity:VisualDensity.compact),onPressed:posting?null:save,child:Text(posting?'جارٍ ترحيل التوريد...':'اختيار المورد وترحيل التوريد',style:const TextStyle(fontSize:11))))
  ]))
 ]);
}
class StockPage extends StatelessWidget {const StockPage({super.key});@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,Object?>>>(future:rows('products'),builder:(c,s){
 if(!s.hasData)return const Center(child:CircularProgressIndicator());
 return ListView(children:s.data!.map((p)=>ListTile(title:Text(p['name'] as String),subtitle:Text('سعر البيع: '+money(p['sale_price'] as num)+' / كجم'),trailing:Text(kg(p['stock_grams'] as num)))).toList());
});}
class AdminPage extends StatelessWidget {const AdminPage({super.key});@override Widget build(BuildContext c)=>ListView(children:[
 _link(c,'الأصناف',Icons.category,const ProductsPage()),_link(c,'الموردون',Icons.local_shipping,const PartiesPage(type:'supplier')),
 _link(c,'الزبائن',Icons.people,const PartiesPage(type:'customer')),_link(c,'الفواتير',Icons.receipt_long,const InvoicesPage()),_link(c,'المرتجعات',Icons.assignment_return,const ReturnsPage()),_link(c,'مسودات الفواتير',Icons.drafts,const DraftsPage()),
 _link(c,'ملخص الحسابات',Icons.account_balance,const AccountsPage())
]);Widget _link(BuildContext c,String t,IconData i,Widget p)=>ListTile(leading:Icon(i),title:Text(t),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>p)));}
class ProductsPage extends StatefulWidget {const ProductsPage({super.key});@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
 Future<void> add()async{
  final n=TextEditingController(),u=TextEditingController(text:'جوان'),w=TextEditingController(text:'30'),price=TextEditingController(text:'0');
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('إضافة صنف'),content:Column(mainAxisSize:MainAxisSize.min,children:[
   field(n,'اسم الصنف'),field(u,'وحدة الشراء الافتراضية'),field(w,'وزن الوحدة بالكيلو',number:true),field(price,'سعر بيع الكيلو',number:true)
  ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok==true&&n.text.trim().isNotEmpty){final weight=double.tryParse(w.text)??0,p=int.tryParse(price.text)??0;if(weight>0&&p>=0){try{await ShopDb.instance.addProduct(n.text,u.text,(weight*1000).round(),p);if(mounted)setState((){});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}}
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('الأصناف')),body:FutureBuilder<List<Map<String,Object?>>>(future:rows('products'),builder:(c,s){
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  return ListView(children:s.data!.map((p)=>ListTile(title:Text(p['name'] as String),subtitle:Text((p['purchase_unit'] as String)+' • '+money(p['sale_price'] as num)+' / كجم'),trailing:Text(kg(p['stock_grams'] as num)))).toList());
 }),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة صنف')));
}
class PartiesPage extends StatefulWidget {final String type;const PartiesPage({super.key,required this.type});@override State<PartiesPage> createState()=>_PartiesPageState();}
class _PartiesPageState extends State<PartiesPage>{
 Future<void> add()async{final n=TextEditingController(),phone=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
  title:Text(widget.type=='supplier'?'إضافة مورد':'إضافة زبون'),content:Column(mainAxisSize:MainAxisSize.min,children:[field(n,'الاسم'),field(phone,'الهاتف')]),
  actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok==true&&n.text.trim().isNotEmpty){await ShopDb.instance.addParty(widget.type,n.text,phone.text);if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c){final table=widget.type=='supplier'?'suppliers':'customers';return Scaffold(appBar:AppBar(title:Text(widget.type=='supplier'?'الموردون':'الزبائن')),
  body:FutureBuilder<List<Map<String,Object?>>>(future:rows(table),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.map((x)=>ListTile(leading:const Icon(Icons.person_outline),title:Text(x['name'] as String),subtitle:Text((x['phone']??'').toString()))).toList());}),
  floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة')));}
}
class InvoicesPage extends StatelessWidget {const InvoicesPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('الفواتير')),
 body:FutureBuilder<List<List<Map<String,Object?>>>>(future:Future.wait([rows('sales'),rows('purchases')]),builder:(c,s){
  if(!s.hasData)return const Center(child:CircularProgressIndicator());
  final all=<Map<String,Object?>>[...s.data![0].map((x)=>{...x,'kind':'بيع'}),...s.data![1].map((x)=>{...x,'kind':'توريد'})]..sort((a,b)=>(b['id'] as int).compareTo(a['id'] as int));
  return ListView(children:all.map((x)=>ListTile(title:Text((x['kind'] as String)+' رقم '+x['id'].toString()),subtitle:Text(x['date'].toString()),trailing:Text(money(x['total'] as num)))).toList());
 }));}


class ReturnsPage extends StatefulWidget {
 const ReturnsPage({super.key});
 @override State<ReturnsPage> createState()=>_ReturnsPageState();
}
class _ReturnsPageState extends State<ReturnsPage>{
 String type='customer';
 int? invoiceId;
 List<Map<String,Object?>> invoiceItems=[];
 final Map<int,TextEditingController> quantities={};
 final cash=TextEditingController(text:'0');
 bool saving=false;
 Future<void> loadItems(int id) async {
  final data=await ShopDb.instance.returnableItems(type,id);
  for(final c in quantities.values){c.dispose();}
  quantities.clear();
  for(final x in data){quantities[x['source_item_id'] as int]=TextEditingController(text:'0');}
  if(mounted)setState(()=>invoiceItems=data);
 }
 Future<void> changeType(String value) async {
  setState((){type=value;invoiceId=null;invoiceItems=[];quantities.clear();cash.text='0';});
 }
 Future<void> submit() async {
  if(invoiceId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر الفاتورة الأصلية')));return;}
  final selected=<Map<String,dynamic>>[];
  for(final x in invoiceItems){
   final id=x['source_item_id'] as int;
   final grams=int.tryParse(quantities[id]?.text??'0')??0;
   if(grams>0)selected.add({'source_item_id':id,'grams':grams,'unit_price':(x['unit_price'] as num).toInt()});
  }
  if(selected.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل كمية مرتجعة لصنف واحد على الأقل')));return;}
  setState(()=>saving=true);
  try{
   final id=await ShopDb.instance.saveReturn(type:type,invoiceId:invoiceId!,items:selected,cashPaid:type=='customer'?(int.tryParse(cash.text)??0):0);
   if(!mounted)return;
   setState((){invoiceId=null;invoiceItems=[];quantities.clear();cash.text='0';});
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم حفظ المرتجع رقم '+id.toString())));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('مرتجعات الزبائن والموردين')),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   SegmentedButton<String>(segments:const[
    ButtonSegment(value:'customer',label:Text('مرتجع زبون'),icon:Icon(Icons.assignment_return)),
    ButtonSegment(value:'supplier',label:Text('مرتجع للمورد'),icon:Icon(Icons.local_shipping_outlined)),
   ],selected:{type},onSelectionChanged:(v)=>changeType(v.first)),
   const SizedBox(height:12),
   FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.returnableInvoices(type),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int>(
     value:invoiceId,decoration:const InputDecoration(labelText:'اختر الفاتورة الأصلية',border:OutlineInputBorder()),
     items:s.data!.map((x)=>DropdownMenuItem<int>(value:x['id'] as int,child:Text('#'+x['id'].toString()+' • '+(x['party_name']??'بدون اسم').toString()+' • '+money(x['total'] as num)))).toList(),
     onChanged:(v){if(v!=null){setState(()=>invoiceId=v);loadItems(v);}},
    );
   }),
   const SizedBox(height:12),
   if(invoiceId!=null && invoiceItems.isEmpty) const Text('لا توجد كميات متبقية للإرجاع في هذه الفاتورة'),
   ...invoiceItems.map((x){
    final id=x['source_item_id'] as int;
    return Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(x['product_name'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
     Text('المتاح للإرجاع: '+kg(x['remaining_grams'] as num)+' • سعر الوحدة: '+money(x['unit_price'] as num)),
     TextField(controller:quantities[id],keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الكمية المرتجعة بالجرام',border:OutlineInputBorder(),isDense:true)),
    ])));
   }),
   if(type=='customer')field(cash,'المبلغ الذي أُعيد نقداً للزبون',number:true),
   const SizedBox(height:8),
   FilledButton.icon(onPressed:saving?null:submit,icon:const Icon(Icons.save),label:Text(saving?'جارٍ الحفظ...':'حفظ المرتجع وتحديث المخزون')),
   const Padding(padding:EdgeInsets.only(top:12),child:Text('يجب اختيار الفاتورة الأصلية. لا يسمح النظام بإرجاع كمية أكبر من المتبقي من الصنف في الفاتورة. مرتجع المورد لا يتجاوز رصيد المخزون المتاح.',style:TextStyle(height:1.5))),
  ]),
 );
}

class DraftsPage extends StatefulWidget {
 final String? type;
 const DraftsPage({super.key,this.type});
 @override State<DraftsPage> createState()=>_DraftsPageState();
}
class _DraftsPageState extends State<DraftsPage>{
 Future<void> remove(int id) async {await ShopDb.instance.deleteDraft(id);if(mounted)setState((){});}
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(widget.type=='sale'?'مسودات البيع':widget.type=='purchase'?'مسودات التوريد':'مسودات الفواتير')),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.getDrafts(type:widget.type),builder:(c,s){
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return const Center(child:Text('لا توجد مسودات محفوظة'));
   return ListView(children:s.data!.map((d){
    final isSale=d['invoice_type']=='sale';
    final dt=DateTime.tryParse(d['updated_at'] as String);
    return Card(child:ListTile(
     leading:Icon(isSale?Icons.point_of_sale:Icons.local_shipping),
     title:Text((isSale?'مسودة بيع #':'مسودة توريد #')+d['id'].toString()),
     subtitle:Text((dt?.toLocal().toString().substring(0,16)??'')+' • '+money(d['total'] as num)),
     trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='delete'){await remove(d['id'] as int);}else{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);}},itemBuilder:(_)=>const[
      PopupMenuItem(value:'open',child:Text('استعادة المسودة')),PopupMenuItem(value:'delete',child:Text('حذف المسودة'))]),
     onTap:()async{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);},
    ));
   }).toList());
  }));
}

class AccountsPage extends StatelessWidget {const AccountsPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('ملخص الحسابات')),
 body:FutureBuilder<List<List<Map<String,Object?>>>>(future:Future.wait([rows('customers'),rows('suppliers'),rows('sales'),rows('purchases'),rows('returns')]),builder:(c,s){
  if(!s.hasData)return const Center(child:CircularProgressIndicator());final x=s.data!;
  final customerReturns=x[4].where((r)=>r['return_type']=='customer').fold<num>(0,(v,r)=>v+(r['total'] as num)-(r['cash_paid'] as num));
  final supplierReturns=x[4].where((r)=>r['return_type']=='supplier').fold<num>(0,(v,r)=>v+(r['total'] as num));
  final cd=x[2].fold<num>(0,(v,r)=>v+(r['total'] as num)-(r['paid'] as num))-customerReturns;
  final sd=x[3].fold<num>(0,(v,r)=>v+(r['total'] as num)-(r['paid'] as num))-supplierReturns;
  return ListView(children:[ListTile(title:Text('عدد الزبائن: '+x[0].length.toString()),trailing:Text(money(cd))),
   ListTile(title:Text('عدد الموردين: '+x[1].length.toString()),trailing:Text(money(sd))),
   const Padding(padding:EdgeInsets.all(12),child:Text('ملخص أولي. كشف الحساب التفصيلي وتوزيع الدفعات يحتاجان اختباراً إضافياً قبل الاعتماد المحاسبي.',style:TextStyle(height:1.6)))]);
 }));}
