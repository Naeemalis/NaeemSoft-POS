import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdf_export/flutter_pdf_export.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'shop_db.dart';
import 'inventory_center.dart';

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
  appBar:AppBar(title:Text('NaeemSoft POS • '+labels[tab])),body:IndexedStack(index:tab,children:pages),
  bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
   NavigationDestination(icon:Icon(Icons.home_outlined),label:'الرئيسية'),
   NavigationDestination(icon:Icon(Icons.point_of_sale),label:'بيع'),
   NavigationDestination(icon:Icon(Icons.add_shopping_cart),label:'توريد'),
   NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'الأصناف والكميات'),
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
  Widget metric(String label,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:11)),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:14))]))])));
  Widget action(String label,IconData icon,Widget page)=>Card(child:InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page)),child:Padding(padding:const EdgeInsets.symmetric(vertical:12,horizontal:5),child:Column(children:[Icon(icon,size:24),const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))]))));
  return ListView(padding:const EdgeInsets.all(10),children:[
   Card(color:Theme.of(c).colorScheme.primaryContainer,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('ملخص اليوم'),Text(money(x[0]),style:Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),const Text('إجمالي فواتير البيع المسجلة اليوم')]))),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:2.2,children:[metric('مشتريات اليوم',money(x[1]),Icons.local_shipping_outlined),metric('عدد الأصناف',x[2].toString(),Icons.category_outlined),metric('المخزون الحالي',kg(x[3]),Icons.inventory_2_outlined),metric('النظام','محلي • محل واحد',Icons.storefront_outlined)]),
   const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('الوصول السريع',style:TextStyle(fontWeight:FontWeight.bold,fontSize:15))),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,childAspectRatio:.9,children:[action('الأصناف',Icons.category,const ProductsPage()),action('الفواتير',Icons.receipt_long,const InvoicesPage()),action('الموردون',Icons.local_shipping,const PartiesPage(type:'supplier')),action('الزبائن',Icons.people,const PartiesPage(type:'customer')),action('الحسابات',Icons.account_balance,const AccountsPage()),action('المرتجعات',Icons.assignment_return,const ReturnsPage()),action('المسودات',Icons.drafts,const DraftsPage()),action('الإدارة',Icons.settings,const AdminPage())]),
   const Padding(padding:EdgeInsets.all(8),child:Text('فواتير الموردين وفواتير العملاء مستقلة. الكاشير لا يرتبط بالمخزون ولا يخصم منه.',style:TextStyle(height:1.5)))
  ]);
 });
}
Widget cashierNumberPad({required List<String> keys, required void Function(String) onKey}) {
 return SizedBox(height:120,child:GridView.count(
  physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,mainAxisSpacing:2,crossAxisSpacing:2,childAspectRatio:3.2,
  children:[for(final k in keys) OutlinedButton(onPressed:()=>onKey(k),style:OutlinedButton.styleFrom(padding:EdgeInsets.zero),child:Text(k,style:const TextStyle(fontSize:11,fontWeight:FontWeight.bold)))],
 ));
}
class SalePage extends StatefulWidget {const SalePage({super.key});@override State<SalePage> createState()=>_SalePageState();}
class _SalePageState extends State<SalePage>{
 final Map<int,Map<String,dynamic>> cart={};
 int? activeDraftId;
 int? selectedCustomerId;
 bool posting=false;
 String keypadValue=''; String saleMode='weight';
 void key(String k){setState((){if(k=='مسح')keypadValue='';else if(k=='⌫'){if(keypadValue.isNotEmpty)keypadValue=keypadValue.substring(0,keypadValue.length-1);}else if(k=='½')keypadValue='0.5';else if(k=='¼')keypadValue='0.25';else if(k=='1 كجم')keypadValue='1';else if(keypadValue.isEmpty||keypadValue=='0')keypadValue=k;else keypadValue+=k;});}
 Future<void> add(Map<String,Object?> p) async {
  var price=(p['sale_price'] as num).round();
  if(selectedCustomerId!=null){
   final custom=await ShopDb.instance.db.query('customer_product_prices',where:'customer_id=? AND product_id=? AND active=1',whereArgs:[selectedCustomerId,p['id']],limit:1);
   if(custom.isNotEmpty) price=(custom.first['price_per_kg'] as num).round();
  }
  final value=double.tryParse(keypadValue.replaceAll(',', '.'))??0;
  final grams=saleMode=='weight'?(value*1000).round():(price>0?(value*1000/price).round():0);
  final id=p['id'] as int, old=cart[id]?['grams'] as int? ?? 0;
  if(grams<=0||price<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل كمية وسعراً صحيحين')));return;}
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
  final customers=await ShopDb.instance.db.query('customers',where:'active=1',orderBy:'name');
  final paid=TextEditingController(text:total.toString()),due=TextEditingController();
  int? customer=selectedCustomerId;
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:const Text('بيانات فاتورة البيع'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('الإجمالي: '+money(total)),
    DropdownButtonFormField<int?>(value:customer,decoration:const InputDecoration(labelText:'الزبون (اختياري)'),
     items:[const DropdownMenuItem<int?>(value:null,child:Text('نقدي / غير مسجل')),...customers.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],onChanged:(v)=>customer=v),
    field(paid,'المبلغ المدفوع',number:true),field(due,'موعد السداد YYYY-MM-DD')
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('معاينة الفاتورة'))]));
  if(ok!=true)return;
  selectedCustomerId=customer;
  final paidAmount=int.tryParse(paid.text)??0,dueDate=due.text.trim().isEmpty?null:due.text.trim();
  final snapshot=cart.values.map((x)=>Map<String,dynamic>.from(x)).toList(),invoiceTotal=total;
  final party=customer==null?'نقدي / غير مسجل':(customers.firstWhere((x)=>x['id']==customer)['name'] as String);
  final approved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>SaleInvoiceReviewPage(items:snapshot,total:invoiceTotal,paid:paidAmount,party:party)));
  if(approved!=true||!mounted)return;
  setState(()=>posting=true);int? draftId=activeDraftId;
  try{
   if(draftId==null){draftId=await ShopDb.instance.saveDraft(type:'sale',items:snapshot,partyId:customer,total:invoiceTotal,paid:paidAmount,dueDate:dueDate);}
   else{await ShopDb.instance.saveDraft(type:'sale',items:snapshot,partyId:customer,total:invoiceTotal,paid:paidAmount,dueDate:dueDate,draftId:draftId);}
   activeDraftId=draftId;
   final invoiceId=await ShopDb.instance.saveSale(customerId:customer,items:snapshot,paid:paidAmount,dueDate:dueDate,draftId:draftId);
   activeDraftId=null;cart.clear();
   if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم ترحيل فاتورة البيع رقم $invoiceId')));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }

 @override Widget build(BuildContext c) {
  return Column(children:[
   Padding(padding:const EdgeInsets.fromLTRB(8,6,8,2),child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('customers',where:'active=1',orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int?>(value:selectedCustomerId,decoration:const InputDecoration(labelText:'الزبون (اختياري) • السعر الخاص إن وجد',border:OutlineInputBorder(),isDense:true),items:[const DropdownMenuItem<int?>(value:null,child:Text('بيع نقدي / بدون زبون')),...s.data!.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],onChanged:posting?null:(v)=>setState(()=>selectedCustomerId=v));
   })),
   FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:"active=1 AND product_type='sale'",orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const SizedBox(height:120,child:Center(child:CircularProgressIndicator()));
    final ps=s.data!, n=((s.data!.length+6)~/7).clamp(1,1000);
    return SizedBox(height:n*78.0,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),padding:const EdgeInsets.all(3),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,crossAxisSpacing:3,mainAxisSpacing:3,childAspectRatio:.78),itemCount:ps.length,itemBuilder:(c,i){
     final p=ps[i];return Card(margin:EdgeInsets.zero,child:InkWell(onTap:posting?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(2),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(p['name'] as String,maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:10)),
      Text(money(p['sale_price'] as num),maxLines:1,style:const TextStyle(fontSize:9)),
      const Text('بيع مباشر',maxLines:1,style:TextStyle(fontSize:8))
     ]))));
    }));
   }),
   const Divider(height:5),
   Expanded(child:Container(
    margin:const EdgeInsets.symmetric(horizontal:7,vertical:3),padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(border:Border.all(color:Theme.of(c).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(10),color:Theme.of(c).colorScheme.surfaceContainerLowest),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(children:[const Icon(Icons.calculate_outlined,size:18),const SizedBox(width:5),const Text('قراءة الكاشير • العمليات المختارة',style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text('عدد العمليات: ${cart.length}',style:const TextStyle(fontSize:11))]),
     const Divider(height:8),
     Expanded(child:cart.isEmpty?const Center(child:Text('عند اختيار أي صنف ستظهر عمليته هنا مباشرة',style:TextStyle(color:Colors.grey))):ListView(children:cart.values.toList().asMap().entries.map((entry){
      final x=entry.value,grams=x['grams'] as int,price=x['price_per_kg'] as int;
      return Container(margin:const EdgeInsets.only(bottom:5),padding:const EdgeInsets.symmetric(horizontal:6,vertical:5),decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Theme.of(c).colorScheme.outlineVariant))),child:Row(children:[
       SizedBox(width:22,child:Text('${entry.key+1}.',style:const TextStyle(fontSize:11,color:Colors.grey))),
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(x['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:13)),
        Text('الكمية: ${kg(grams)} كيلو • سعر الكيلو: ${money(price)}',style:const TextStyle(fontSize:11,color:Colors.grey))
       ])),
       Column(crossAxisAlignment:CrossAxisAlignment.end,children:[const Text('إجمالي الصنف',style:TextStyle(fontSize:9,color:Colors.grey)),Text(money((grams*price/1000).round()),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12))]),
       IconButton(visualDensity:VisualDensity.compact,constraints:const BoxConstraints.tightFor(width:28,height:28),iconSize:15,onPressed:posting?null:()=>setState(()=>cart.remove(x['product_id'])),icon:const Icon(Icons.close))
      ]));
     }).toList())),
     const Divider(height:8),
     Row(children:[const Text('الإجمالي',style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(money(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))])
    ])
   )),
   Container(padding:const EdgeInsets.fromLTRB(7,4,7,5),color:Theme.of(c).colorScheme.surface,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Row(children:[Expanded(child:SegmentedButton<String>(showSelectedIcon:false,segments:const[ButtonSegment(value:'weight',label:Text('وزن')),ButtonSegment(value:'cash',label:Text('نقد'))],selected:{saleMode},onSelectionChanged:(v)=>setState(()=>saleMode=v.first))),const SizedBox(width:6),Text((keypadValue.isEmpty?'أدخل الرقم':keypadValue)+(saleMode=='cash'?' DJF':' كجم'),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:13))]),
    cashierNumberPad(keys:['7','8','9','⌫','4','5','6','مسح','1','2','3',if(saleMode=='weight')'½' else '.','0','.',if(saleMode=='weight')'¼' else '00',if(saleMode=='weight')'1 كجم' else 'مسح'],onKey:key),
    Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,child:const Text('مسودة'))),const SizedBox(width:5),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,child:const Text('المسودات')))]),
    SizedBox(width:double.infinity,height:42,child:FilledButton(onPressed:posting?null:checkout,child:Text(posting?'جارٍ الترحيل...':'إتمام البيع')))
   ]))
  ]);
 }
}
class PurchasePage extends StatefulWidget {const PurchasePage({super.key});@override State<PurchasePage> createState()=>_PurchasePageState();}
class _PurchasePageState extends State<PurchasePage>{
 final List<Map<String,dynamic>> cart=[];
 int? activeDraftId;
 bool posting=false;
 String keypadValue=''; String purchaseField='packages'; String purchaseCostMode='package'; int packageCount=0,packageWeight=0,packageCost=0; String? expiryDate; int? selectedSupplierId;
 void key(String k){setState((){if(k=='مسح')keypadValue='';else if(k=='⌫'){if(keypadValue.isNotEmpty)keypadValue=keypadValue.substring(0,keypadValue.length-1);}else if(keypadValue.isEmpty||keypadValue=='0')keypadValue=k;else keypadValue+=k;});}
 void applyKeypad(){final v=double.tryParse(keypadValue.replaceAll(',', '.'));if(v==null)return;setState((){if(purchaseField=='packages')packageCount=v.toInt();else packageCost=v.toInt();keypadValue='';});}
 Future<void> add(Map<String,Object?> p) async {
  if(p['paired_sale_product_id']==null){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اربط صنف التوريد بصنف المبيعات من إدارة الأصناف أولاً')));
   return;
  }
  final count=packageCount;
  final supplierUnit=await ShopDb.instance.db.query('supplier_product_units',where:'supplier_id=? AND product_id=? AND unit_name=?',whereArgs:[selectedSupplierId,p['id'],p['purchase_unit']],limit:1);
  final supplierWeight=supplierUnit.isEmpty?null:(supplierUnit.first['weight_grams'] as num).toInt();
  final weight=packageWeight>0?packageWeight:(supplierWeight??((p['default_weight'] as num)*1000).round());
  final stockLink=await ShopDb.instance.db.query('product_stock_links',where:'purchase_product_id=?',whereArgs:[p['id']],limit:1);
  final stockProduct=stockLink.isEmpty?null:(await ShopDb.instance.db.query('products',where:'id=?',whereArgs:[stockLink.first['stock_product_id']],limit:1)).firstOrNull;
  final needsExpiry=(p['requires_expiry'] as num?)?.toInt()==1 || (stockProduct?['requires_expiry'] as num?)?.toInt()==1;
  String? lineExpiry;
  if (needsExpiry) {
   final picked=await showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:30)),firstDate:DateTime.now(),lastDate:DateTime(2100));
   if(picked==null)return;
   lineExpiry=DateFormat('yyyy-MM-dd').format(picked);
  }
  final enteredCost=packageCost>0?packageCost:(p['cost'] as num).round();
  final effectiveMode=packageCost>0?purchaseCostMode:'package';
  final price=effectiveMode=='package'?enteredCost:((enteredCost*weight)/1000).round();
  if(count<=0||weight<=0||price<=0){
   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل العدد وتكلفة الشراء، وسيُؤخذ الوزن تلقائياً من معرض الأصناف')));
   return;
  }
  setState((){
   cart.add({'product_id':p['id'],'name':p['name'],'unit':p['purchase_unit'],'packages':count,'weight_grams':weight,'package_cost':price,'cost_mode':effectiveMode,'entered_cost':enteredCost,'expiry_date':lineExpiry});
   packageCount=0;packageWeight=0;packageCost=0;keypadValue='';expiryDate=null;
  });
 }
 Future<void> editLineWeight(int index) async {
  final item=cart[index];
  final controller=TextEditingController(text:((item['weight_grams'] as int)/1000).toStringAsFixed(2));
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text('تعديل وزن ' + item['name'].toString() + ' في هذه الفاتورة'),
   content:field(controller,'وزن الوحدة بالكيلو',number:true),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok!=true)return;
  final value=double.tryParse(controller.text.replaceAll(',', '.'))??0;
  if(value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الوزن غير صحيح')));return;}
  setState((){cart[index]['weight_grams']=(value*1000).round();if(item['cost_mode']=='kg'){cart[index]['package_cost']=(((item['entered_cost'] as num)*value).round());}});
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
  if(posting||cart.isEmpty)return;
  if(selectedSupplierId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر المورد أولاً')));return;}
  final paid=TextEditingController(text:'0'),due=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('اعتماد فاتورة التوريد'),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('الإجمالي: '+money(total)),field(paid,'المدفوع الآن',number:true),field(due,'موعد السداد YYYY-MM-DD')]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ الفاتورة'))]));
  if(ok!=true)return;
  final snapshot=cart.map((x)=>Map<String,dynamic>.from(x)).toList();
  final suppliers=await ShopDb.instance.db.query('suppliers',where:'id=?',whereArgs:[selectedSupplierId],limit:1);
  final supplierName=suppliers.isEmpty?'مورد غير محدد':suppliers.first['name'].toString();
  final paidAmount=int.tryParse(paid.text)??0;
  final approved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>PurchaseInvoiceReviewPage(items:snapshot,total:total,paid:paidAmount,party:supplierName)));
  if(approved!=true||!mounted)return;
  setState(()=>posting=true);int? draftId=activeDraftId;final dueDate=due.text.trim().isEmpty?null:due.text.trim();
  try{
   if(draftId==null){draftId=await ShopDb.instance.saveDraft(type:'purchase',items:cart,partyId:selectedSupplierId,total:total,paid:paidAmount,dueDate:dueDate);}
   else{await ShopDb.instance.saveDraft(type:'purchase',items:cart,partyId:selectedSupplierId,total:total,paid:paidAmount,dueDate:dueDate,draftId:draftId);}
   activeDraftId=draftId;final id=await ShopDb.instance.savePurchase(supplierId:selectedSupplierId!,items:cart,paid:paidAmount,dueDate:dueDate,draftId:draftId);
   activeDraftId=null;cart.clear();
   if(mounted){setState((){});await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text('فاتورة توريد رقم $id'),content:Text('تم تسجيل التوريد بقيمة '+money(total)+' وتحديث مخزون أصناف المبيعات المرتبطة.'),actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('حسناً'))]));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }
 @override Widget build(BuildContext c){
  final w=MediaQuery.of(c).size.width;
  return Column(children:[
   Padding(padding:const EdgeInsets.fromLTRB(8,6,8,2),child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('suppliers',where:'active=1',orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int>(value:selectedSupplierId,decoration:const InputDecoration(labelText:'اختر المورد أولاً',prefixIcon:Icon(Icons.local_shipping_outlined),border:OutlineInputBorder(),isDense:true),items:s.data!.map((v)=>DropdownMenuItem<int>(value:v['id'] as int,child:Text(v['name'] as String))).toList(),onChanged:posting?null:(v)=>setState(()=>selectedSupplierId=v));
   })),
   SizedBox(height:104,child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:"active=1 AND product_type='purchase'",orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return const Center(child:Text('أضف الأصناف من الإدارة أولاً'));
    return ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:3),itemCount:s.data!.length,itemBuilder:(c,i){
     final p=s.data![i];return SizedBox(width:w/7.2,child:Card(margin:const EdgeInsets.all(2),child:InkWell(onTap:posting||selectedSupplierId==null?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(2),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(p['name'] as String,maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:10)),Text(p['purchase_unit'] as String,style:const TextStyle(fontSize:9)),const Text('إضافة',style:TextStyle(fontSize:9))])))));
    });
   })),
   Expanded(child:Container(
    margin:const EdgeInsets.symmetric(horizontal:7,vertical:3),padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(border:Border.all(color:Theme.of(c).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(10),color:Theme.of(c).colorScheme.surfaceContainerLowest),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(children:[const Icon(Icons.calculate_outlined,size:18),const SizedBox(width:5),const Text('قراءة كاشير التوريد • العمليات المختارة',style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text('عدد العمليات: ${cart.length}',style:const TextStyle(fontSize:11))]),
     const Divider(height:8),
     Expanded(child:cart.isEmpty?const Center(child:Text('الأصناف والعمليات التي تختارها ستظهر هنا',style:TextStyle(color:Colors.grey))):ListView(children:cart.asMap().entries.map((e){
      final x=e.value,line=(x['packages'] as int)*(x['package_cost'] as int);
      return Padding(padding:const EdgeInsets.symmetric(vertical:4),child:InkWell(onTap:()=>editLineWeight(e.key),child:Row(children:[
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(x['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
        Text('الكمية ${x['packages']} ${x['unit']}، وزن الوحدة ${((x['weight_grams'] as int)/1000).toStringAsFixed(2)} كيلو • اضغط لتعديل الوزن',style:const TextStyle(fontSize:10,color:Colors.grey)),
        Text('تكلفة العبوة ${money(x['package_cost'] as num)}',style:const TextStyle(fontSize:10,color:Colors.grey))
       ])),
       Text(money(line),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
       IconButton(visualDensity:VisualDensity.compact,constraints:const BoxConstraints.tightFor(width:28,height:28),iconSize:15,onPressed:posting?null:()=>setState(()=>cart.removeAt(e.key)),icon:const Icon(Icons.close))
      ])));
     }).toList())),
     const Divider(height:8),
     Row(children:[const Text('إجمالي التوريد',style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(money(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))])
    ])
   )),
   Container(padding:const EdgeInsets.fromLTRB(7,3,7,4),color:Theme.of(c).colorScheme.surface,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Wrap(spacing:3,runSpacing:2,children:[ChoiceChip(label:const Text('عدد الوحدات'),selected:purchaseField=='packages',onSelected:(_)=>setState(()=>purchaseField='packages')),ChoiceChip(label:const Text('تكلفة الشراء'),selected:purchaseField=='cost',onSelected:(_)=>setState(()=>purchaseField='cost'))]),
    if(purchaseField=='cost')Row(children:[const Text('إدخال التكلفة:'),ChoiceChip(label:const Text('للوحدة'),selected:purchaseCostMode=='package',onSelected:(_)=>setState(()=>purchaseCostMode='package')),ChoiceChip(label:const Text('للكيلو'),selected:purchaseCostMode=='kg',onSelected:(_)=>setState(()=>purchaseCostMode='kg'))]),
    Text('القيمة: ${keypadValue.isEmpty?'أدخل الرقم':keypadValue} • العدد: ${packageCount==0?'—':packageCount} • تكلفة الشراء: ${packageCost==0?'—':packageCost} • الوزن يُقرأ تلقائياً من معرض الأصناف',style:const TextStyle(fontSize:10)),
    cashierNumberPad(keys:['7','8','9','⌫','4','5','6','مسح','1','2','3','.','0','00','اعتماد'],onKey:(k)=>k=='اعتماد'?applyKeypad():key(k)),
    Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,child:const Text('حفظ مسودة'))),const SizedBox(width:4),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,child:const Text('المسودات')))]),
    SizedBox(width:double.infinity,height:40,child:FilledButton(onPressed:posting?null:save,child:Text(posting?'جارٍ الحفظ...':'ترحيل فاتورة التوريد')))
   ]))
  ]);
 }
}
class PurchaseInvoiceReviewPage extends StatelessWidget {
 final List<Map<String,dynamic>> items;
 final int total,paid;
 final String party;
 const PurchaseInvoiceReviewPage({super.key,required this.items,required this.total,required this.paid,required this.party});
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('معاينة فاتورة التوريد قبل الترحيل')),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('NaeemSoft POS',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
    const Center(child:Text('فاتورة توريد',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16))),
    const Divider(),
    Text('المورد: $party'),
    Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
    const Divider(),
    const Row(children:[Expanded(child:Text('اسم الصنف',style:TextStyle(fontWeight:FontWeight.bold))),Text('الكمية',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(width:10),Text('إجمالي الصنف',style:TextStyle(fontWeight:FontWeight.bold))]),
    const Divider(),
    ...items.map((x)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[
     Expanded(child:Text(x['name'].toString(),style:const TextStyle(fontWeight:FontWeight.bold))),
     Text('${x['packages']} ${x['unit']} • ${((x['weight_grams'] as num)/1000).toStringAsFixed(2)} كجم/وحدة'),
     const SizedBox(width:10),
     Text(money((x['packages'] as num)*(x['package_cost'] as num)),style:const TextStyle(fontWeight:FontWeight.bold)),
    ]))),
    const Divider(),
    _receiptRow('الإجمالي',money(total),strong:true),
    _receiptRow('المدفوع',money(paid)),
    _receiptRow('المتبقي',money(total-paid),strong:true),
   ]))),
   FilledButton.icon(onPressed:()=>Navigator.pop(c,true),icon:const Icon(Icons.check_circle),label:const Text('تأكيد وترحيل فاتورة التوريد')),
   TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع للتعديل')),
  ]));
}

class StockPage extends StatelessWidget {
  const StockPage({super.key});
  @override
  Widget build(BuildContext context) => InventoryCenterPage(
    onManageProducts: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductsPage()),
    ),
  );
}
class ExpiryAlertsPage extends StatelessWidget {
 const ExpiryAlertsPage({super.key});
 Future<List<Map<String,Object?>>> load() async {
  return ShopDb.instance.db.rawQuery("""
   SELECT b.id batch_id,b.expiry_date,b.remaining_grams,b.cost_per_kg,p.name product_name,p.expiry_warning_days
   FROM purchase_batches b JOIN products p ON p.id=b.product_id
   WHERE b.remaining_grams>0 AND b.expiry_date IS NOT NULL
   AND date(b.expiry_date)<=date('now', '+' || p.expiry_warning_days || ' days')
   ORDER BY date(b.expiry_date),p.name
  """);
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('تنبيهات صلاحية الأصناف')),
  body:FutureBuilder<List<Map<String,Object?>>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Text('تعذر تحميل التنبيهات: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return const Center(child:Text('لا توجد دفعات منتهية أو قريبة من الانتهاء'));
   return ListView(children:s.data!.map((x){
    final expiry=DateTime.tryParse(x['expiry_date'].toString());
    final expired=expiry!=null&&expiry.isBefore(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day));
    return ListTile(
     leading:Icon(expired?Icons.warning_amber_rounded:Icons.schedule,color:expired?Colors.red:Colors.orange),
     title:Text(x['product_name'].toString()),
     subtitle:Text('الانتهاء: ${x['expiry_date']} • المتبقي: ${kg(x['remaining_grams'] as num)}'),
     trailing:Text(expired?'منتهي':'قريب',style:TextStyle(color:expired?Colors.red:Colors.orange,fontWeight:FontWeight.bold)),
    );
   }).toList());
  }),
 );
}

class AdminPage extends StatelessWidget {const AdminPage({super.key});@override Widget build(BuildContext c)=>ListView(children:[
 _link(c,'الأصناف',Icons.category,const ProductsPage()),_link(c,'الموردون',Icons.local_shipping,const PartiesPage(type:'supplier')),
 _link(c,'الزبائن',Icons.people,const PartiesPage(type:'customer')),_link(c,'الفواتير',Icons.receipt_long,const InvoicesPage()),_link(c,'المرتجعات',Icons.assignment_return,const ReturnsPage()),_link(c,'مسودات الفواتير',Icons.drafts,const DraftsPage()),
 _link(c,'ملخص الحسابات',Icons.account_balance,const AccountsPage()),_link(c,'تنبيهات الصلاحية',Icons.warning_amber,const ExpiryAlertsPage())
]);Widget _link(BuildContext c,String t,IconData i,Widget p)=>ListTile(leading:Icon(i),title:Text(t),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>p)));}
class ProductsPage extends StatefulWidget {const ProductsPage({super.key});@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
 Future<void> edit(Map<String,Object?>? product) async {
  final n=TextEditingController(text:(product?['name']??'').toString());
  final u=TextEditingController(text:(product?['purchase_unit']??'جوان').toString());
  final w=TextEditingController(text:((product?['default_weight'] as num?)??30).toString());
  final price=TextEditingController(text:((product?['sale_price'] as num?)??0).round().toString());
  final expiryDays=TextEditingController(text:((product?['expiry_warning_days'] as num?)??7).toString());
  bool requiresExpiry=(product?['requires_expiry'] as num?)?.toInt()==1;
  final cost=TextEditingController(text:((product?['cost'] as num?)??0).round().toString());
  final saleProducts=await ShopDb.instance.db.query('products',where:"active=1 AND product_type='sale' AND id != ?",whereArgs:[product?['id']??-1],orderBy:'name');
  final categories=await ShopDb.instance.db.query('categories',orderBy:'name');
  int? categoryId=(product?['category_id'] as num?)?.toInt();
  String productType=(product?['product_type']??'sale').toString();
  int? pairedSaleProductId=product?['paired_sale_product_id'] as int?;
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(product==null?'إضافة صنف':'تعديل الصنف والسعر'),
   content:StatefulBuilder(builder:(c,setDialogState)=>SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    field(n,'اسم الصنف'),DropdownButtonFormField<String>(value:productType,decoration:const InputDecoration(labelText:'نوع الصنف'),items:const [DropdownMenuItem(value:'sale',child:Text('أصناف المبيعات')),DropdownMenuItem(value:'purchase',child:Text('أصناف التوريد'))],onChanged:(v){if(v!=null)setDialogState(()=>productType=v);}),DropdownButtonFormField<int?>(value:categories.any((x)=>(x['id'] as num).toInt()==categoryId)?categoryId:null,decoration:const InputDecoration(labelText:'التصنيف'),items:[const DropdownMenuItem<int?>(value:null,child:Text('بدون تصنيف')),...categories.map((x)=>DropdownMenuItem<int?>(value:(x['id'] as num).toInt(),child:Text(x['name'] as String)))],onChanged:(v)=>setDialogState(()=>categoryId=v)),field(u,'وحدة الشراء الافتراضية'),field(w,'وزن الوحدة بالكيلو',number:true),if(productType=='sale')field(price,'سعر بيع الكيلو',number:true),
    CheckboxListTile(contentPadding:EdgeInsets.zero,value:requiresExpiry,title:const Text('يتطلب تاريخ انتهاء الصلاحية'),onChanged:(v)=>setDialogState(()=>requiresExpiry=v??false)),
    if(requiresExpiry)field(expiryDays,'التنبيه قبل الانتهاء بعدد الأيام',number:true),
    if(productType=='purchase')...[
     field(cost,'سعر التكلفة الافتراضي للوحدة',number:true),
     DropdownButtonFormField<int?>(value:saleProducts.any((x)=>x['id']==pairedSaleProductId)?pairedSaleProductId:null,decoration:const InputDecoration(labelText:'صنف المبيعات المقابل للمخزون',border:OutlineInputBorder(),isDense:true),items:[const DropdownMenuItem<int?>(value:null,child:Text('اختر صنف المبيعات')),...saleProducts.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],onChanged:(v)=>setDialogState(()=>pairedSaleProductId=v))
    ]
   ]))),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok!=true)return;
  final weight=double.tryParse(w.text)??0,p=int.tryParse(price.text)??-1, purchaseCost=int.tryParse(cost.text)??-1;
  if(n.text.trim().isEmpty||u.text.trim().isEmpty||weight<=0||p<0||(productType=='purchase'&&(purchaseCost<0||pairedSaleProductId==null))){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تحقق من الاسم والوزن والسعر')));return;}
  try{
   if(product==null){await ShopDb.instance.addProduct(n.text,u.text,(weight*1000).round(),p,productType:productType,cost:productType=='purchase'?purchaseCost:0,pairedSaleProductId:productType=='purchase'?pairedSaleProductId:null,categoryId:categoryId,requiresExpiry:requiresExpiry,expiryWarningDays:int.tryParse(expiryDays.text)??7);}
   else{await ShopDb.instance.updateProduct(id:product['id'] as int,name:n.text,unit:u.text,defaultWeightGrams:(weight*1000).round(),salePrice:p,productType:productType,cost:productType=='purchase'?purchaseCost:0,pairedSaleProductId:productType=='purchase'?pairedSaleProductId:null,categoryId:categoryId,requiresExpiry:requiresExpiry,expiryWarningDays:int.tryParse(expiryDays.text)??7);}
   if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الصنف: $e')));}
 }
 Future<void> archive(Map<String,Object?> product) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:const Text('حذف الصنف من القائمة؟'),
   content:Text('سيختفي «${product['name']}» من البيع والتوريد، مع الاحتفاظ به في الفواتير السابقة.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حذف'))]));
  if(ok==true){await ShopDb.instance.deactivateProduct(product['id'] as int);if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('مركز إدارة الأصناف'),actions:[IconButton(tooltip:'إدارة التصنيفات',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CategoriesPage())).then((_) {if(mounted)setState((){});}),icon:const Icon(Icons.category_outlined))]),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:'active=1',orderBy:'name'),builder:(c,s){
   if(s.hasError)return Center(child:Text('تعذر تحميل الأصناف: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return const Center(child:Text('لا توجد أصناف نشطة'));
   return ListView(children:s.data!.map((p)=>ListTile(
    leading:const Icon(Icons.category_outlined),
    title:Text(p['name'] as String),
    subtitle:Text(p['product_type']=='purchase'?'${p['purchase_unit']} • تكلفة الوحدة الافتراضية: ${money(p['cost'] as num)}':'${p['purchase_unit']} • ${money(p['sale_price'] as num)} / كجم'),
    trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);else if(v=='supplier')Navigator.push(context,MaterialPageRoute(builder:(_)=>SupplierPackageWeightsPage(product:p)));else archive(p);},itemBuilder:(_)=>[
     const PopupMenuItem(value:'edit',child:Text('تعديل الاسم والوزن والسعر')),
     if(p['product_type']=='purchase')const PopupMenuItem(value:'supplier',child:Text('أوزان العبوات حسب المورد')),
     const PopupMenuItem(value:'delete',child:Text('حذف الصنف')),
    ]),
    onTap:()=>edit(p),
   )).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(null),icon:const Icon(Icons.add),label:const Text('إضافة صنف')));
}
class CategoriesPage extends StatefulWidget {
 const CategoriesPage({super.key});
 @override State<CategoriesPage> createState()=>_CategoriesPageState();
}
class _CategoriesPageState extends State<CategoriesPage>{
 Future<void> add() async {
  final name=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:const Text('إضافة تصنيف'),
   content:field(name,'اسم التصنيف'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok!=true)return;
  try{await ShopDb.instance.addCategory(name.text);if(mounted)setState((){});}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إضافة التصنيف: $e')));}
 }
 Future<void> remove(Map<String,Object?> row) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:const Text('حذف التصنيف؟'),
   content:Text('سيتم إلغاء ربط التصنيف بالصنف «${row['name']}» إن وجد، دون حذف الصنف أو فواتيره.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حذف التصنيف'))]));
  if(ok==true){await ShopDb.instance.deleteCategory((row['id'] as num).toInt());if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('تصنيفات الأصناف')),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('categories',orderBy:'name'),builder:(c,s){
   if(s.hasError)return Center(child:Text('تعذر تحميل التصنيفات: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return const Center(child:Text('لا توجد تصنيفات. أضف تصنيفاً جديداً.'));
   return ListView(children:s.data!.map((x)=>ListTile(
    leading:const Icon(Icons.folder_outlined),
    title:Text(x['name'] as String),
    trailing:IconButton(tooltip:'حذف التصنيف',onPressed:()=>remove(x),icon:const Icon(Icons.delete_outline)),
   )).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة تصنيف')));
}

class SupplierPackageWeightsPage extends StatefulWidget {
 final Map<String,Object?> product;
 const SupplierPackageWeightsPage({super.key,required this.product});
 @override State<SupplierPackageWeightsPage> createState()=>_SupplierPackageWeightsPageState();
}
class _SupplierPackageWeightsPageState extends State<SupplierPackageWeightsPage>{
 int? supplierId;
 String unitName='جوان';
 final weight=TextEditingController();
 Future<List<Map<String,Object?>>> get suppliers=>ShopDb.instance.db.query('suppliers',where:'active=1',orderBy:'name');
 Future<List<Map<String,Object?>>> get units=>ShopDb.instance.getSupplierProductUnits((widget.product['id'] as num).toInt());
 Future<void> save() async {
  final grams=((double.tryParse(weight.text.trim().replaceAll(',','.'))??0)*1000).round();
  if(supplierId==null||grams<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر المورد وأدخل وزناً صحيحاً')));return;}
  try{
   await ShopDb.instance.saveSupplierProductUnit(
    supplierId:supplierId!,productId:(widget.product['id'] as num).toInt(),
    unitName:unitName,weightGrams:grams,
   );
   weight.clear();
   if(mounted)setState((){});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ وزن العبوة لهذا المورد')));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الحفظ: $e')));}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text('أوزان الموردين • ${widget.product['name']}')),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    const Align(alignment:Alignment.centerRight,child:Text('إضافة وزن عبوة خاص بمورد',style:TextStyle(fontWeight:FontWeight.bold))),
    const SizedBox(height:10),
    FutureBuilder<List<Map<String,Object?>>>(future:suppliers,builder:(c,s){
     if(!s.hasData)return const LinearProgressIndicator();
     return DropdownButtonFormField<int>(
      value:supplierId,decoration:const InputDecoration(labelText:'المورد'),
      items:s.data!.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text(x['name'] as String))).toList(),
      onChanged:(v)=>setState(()=>supplierId=v),
     );
    }),
    const SizedBox(height:8),
    DropdownButtonFormField<String>(
     value:unitName,decoration:const InputDecoration(labelText:'نوع العبوة'),
     items:const ['جوان','كيس','سحارة','حزمة','صندوق','كرتون','كيلو']
      .map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
     onChanged:(v){if(v!=null)setState(()=>unitName=v);},
    ),
    const SizedBox(height:8),
    field(weight,'وزن العبوة بالكيلو',number:true),
    const SizedBox(height:8),
    SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:save,icon:const Icon(Icons.save),label:const Text('حفظ وزن المورد'))),
   ]))),
   const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('الأوزان المسجلة حسب المورد',style:TextStyle(fontWeight:FontWeight.bold))),
   FutureBuilder<List<Map<String,Object?>>>(future:units,builder:(c,s){
    if(s.hasError)return Text('تعذر تحميل الأوزان: ${s.error}');
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return const Text('لا توجد أوزان خاصة مسجلة بعد.');
    return Card(child:Column(children:s.data!.map((x)=>ListTile(
     leading:const Icon(Icons.scale_outlined),
     title:Text('${x['supplier_name']} • ${x['unit_name']}'),
     subtitle:Text('وزن العبوة: ${((x['weight_grams'] as num).toDouble()/1000).toStringAsFixed(3)} كجم'),
    )).toList()));
   }),
  ]),
 );
}

class PartiesPage extends StatefulWidget {final String type;const PartiesPage({super.key,required this.type});@override State<PartiesPage> createState()=>_PartiesPageState();}
class _PartiesPageState extends State<PartiesPage>{
 Future<num> customerBalance(int id) async {
  final db=ShopDb.instance.db;
  final partyRows=await db.query('customers',where:'id=?',whereArgs:[id],limit:1);
  if(partyRows.isEmpty)return 0;
  num balance=(partyRows.first['opening_balance'] as num?)??0;
  final invoices=await db.query('sales',where:"customer_id=? AND status='posted'",whereArgs:[id]);
  for(final x in invoices){balance+=(x['total'] as num?)??0;balance-=(x['paid'] as num?)??0;}
  final payments=await db.query('payments',where:'party_type=? AND party_id=?',whereArgs:['customer',id]);
  final allocationRows=await db.rawQuery('SELECT COALESCE(SUM(amount),0) AS total FROM payment_allocations WHERE invoice_type=? AND invoice_id IN (SELECT id FROM sales WHERE customer_id=?)',['sale',id]);
  final allocated=(allocationRows.first['total'] as num?)??0;
  final separatePayments=payments.fold<num>(0,(sum,x)=>sum+((x['amount'] as num?)??0));
  // Invoice paid already contains allocated payments; subtract only payments not allocated to invoices.
  balance-=separatePayments-allocated;
  final returns=await db.query('returns',where:'customer_id=?',whereArgs:[id]);
  for(final x in returns){
   final total=(x['total'] as num?)??0;
   final cash=(x['cash_paid'] as num?)??0;
   balance-=total-cash;
  }
  return balance;
 }

 Future<void> edit(Map<String,Object?>? party)async{
  final n=TextEditingController(text:(party?['name']??'').toString()),phone=TextEditingController(text:(party?['phone']??'').toString());
  final customer=widget.type=='customer';
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(party==null?(customer?'إضافة زبون':'إضافة مورد'):(customer?'تعديل بيانات الزبون':'تعديل بيانات المورد')),
   content:Column(mainAxisSize:MainAxisSize.min,children:[field(n,'الاسم'),field(phone,'الهاتف')]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]));
  if(ok!=true)return;
  if(n.text.trim().isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب الاسم أولاً')));return;}
  try{
   if(party==null)await ShopDb.instance.addParty(widget.type,n.text,phone.text);
   else await ShopDb.instance.updateParty(widget.type,party['id'] as int,n.text,phone.text);
   if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ البيانات: $e')));}
 }
 Future<void> archive(Map<String,Object?> party)async{
  final customer=widget.type=='customer';
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(customer?'حذف الزبون؟':'حذف المورد؟'),
   content:Text('سيختفي «${party['name']}» من قوائم الاختيار، مع الاحتفاظ بفواتيره وكشف حسابه.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حذف'))]));
  if(ok==true){await ShopDb.instance.deactivateParty(widget.type,party['id'] as int);if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c){
  final table=widget.type=='supplier'?'suppliers':'customers';
  final customer=widget.type=='customer';
  return Scaffold(appBar:AppBar(title:Text(customer?'إدارة الزبائن':'إدارة الموردين')),
   body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query(table,where:'active=1',orderBy:'name'),builder:(c,s){
    if(s.hasError)return Center(child:Text('تعذر تحميل القائمة: ${s.error}'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return Center(child:Text(customer?'لا يوجد زبائن مسجلون':'لا يوجد موردون مسجلون'));
    return ListView(children:s.data!.map((x)=>ListTile(
     leading:const Icon(Icons.person_outline),
     title:Text(x['name'] as String),
     subtitle:customer
      ? Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
         FutureBuilder<num>(future:customerBalance(x['id'] as int),builder:(context,balanceSnap){
          if(!balanceSnap.hasData)return const Text('حالة الحساب: جارٍ الحساب…',style:TextStyle(fontSize:12));
          final balance=balanceSnap.data!;
          final label=balance>0?'مدين • عليه للمحل':balance<0?'دائن • للمحل عليه':'صفر • الحساب مسدد';
          final color=balance>0?Colors.red:balance<0?Colors.green:Colors.grey;
          return Text('حالة الحساب: $label  |  الرصيد: ${money(balance.abs())}',style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:color));
         }),
         if((x['phone']??'').toString().isNotEmpty)Text(x['phone'].toString()),
        ])
      :Text((x['phone']??'').toString()),
     trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?edit(x):archive(x),itemBuilder:(_)=>const[
      PopupMenuItem(value:'edit',child:Text('تعديل الاسم والهاتف')),
      PopupMenuItem(value:'delete',child:Text('حذف')),
     ]),
     onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>PartyStatementPage(type:widget.type,partyId:x['id'] as int))).then((_) {if(mounted)setState((){});}),
    )).toList());
   }),
   floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(null),icon:const Icon(Icons.add),label:Text(customer?'إضافة زبون':'إضافة مورد')));
 }
}
Future<void> _showPaymentReceipt(BuildContext context,{required String type,required int paymentId,required String partyName,required int amount,required String note}) async {
 final customer=type=='customer';
 final md='''# NaeemSoft POS\n\n## ${customer?'سند قبض من زبون':'سند سداد مورد'}\n\n- رقم السند: $paymentId\n- التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n- ${customer?'الزبون':'المورد'}: $partyName\n- المبلغ: ${money(amount)}\n- البيان: ${note.isEmpty?'سداد حساب':note}\n\nتم تسجيل العملية بنجاح.''';
 final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title:'${customer?'سند قبض':'سند سداد'} $paymentId',author:'NaeemSoft POS',markdown:md));
 if(context.mounted) await Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
}

class PartyStatementPage extends StatefulWidget {
 final String type;
 final int partyId;
 const PartyStatementPage({super.key,required this.type,required this.partyId});
 @override State<PartyStatementPage> createState()=>_PartyStatementPageState();
}
class _PartyStatementPageState extends State<PartyStatementPage>{
 bool saving=false;
 DateTime? fromDate,toDate;
 String dateText(DateTime? d)=>d==null?'من البداية':DateFormat('yyyy-MM-dd').format(d);
 Future<void> chooseDate(bool isFrom) async {
  final picked=await showDatePicker(context:context,initialDate:(isFrom?fromDate:toDate)??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));
  if(picked!=null&&mounted)setState(()=>isFrom?fromDate=picked:toDate=picked);
 }
 Future<Map<String,Object?>> load() async {
  final customer=widget.type=='customer',db=ShopDb.instance.db;
  final table=customer?'customers':'suppliers';
  final found=await db.query(table,where:'id=?',whereArgs:[widget.partyId],limit:1);
  if(found.isEmpty)throw Exception('الحساب غير موجود');
  final party=found.first;
  final invoiceTable=customer?'sales':'purchases',partyColumn=customer?'customer_id':'supplier_id';
  final invoices=await db.query(invoiceTable,where:'$partyColumn=?',whereArgs:[widget.partyId],orderBy:'date,id');
  final payments=await db.query('payments',where:'party_type=? AND party_id=?',whereArgs:[widget.type,widget.partyId],orderBy:'date,id');
  final returnColumn=customer?'customer_id':'supplier_id';
  final returns=await db.query('returns',where:'$returnColumn=?',whereArgs:[widget.partyId],orderBy:'date,id');
  final all=<Map<String,Object?>>[];
  final invoiceType=customer?'sale':'purchase';
  final allocationRows=await db.rawQuery('SELECT invoice_id, SUM(amount) AS allocated FROM payment_allocations WHERE invoice_type=? GROUP BY invoice_id',[invoiceType]);
  final allocatedByInvoice=<int,num>{for(final a in allocationRows)(a['invoice_id'] as num).toInt():(a['allocated'] as num)};
  for(final x in invoices){
   if(x['status']!='posted')continue;
   final invoiceId=(x['id'] as num).toInt();
   all.add({'date':x['date'],'sort':invoiceId*100000,'label':(customer?'فاتورة بيع':'فاتورة توريد')+' #'+invoiceId.toString(),'amount':(x['total'] as num).toDouble(),'direction':1});
   // paid includes later allocated payments; remove those here because they are listed separately below.
   final paid=(x['paid'] as num?)?.toDouble()??0;
   final initialPaid=(paid-(allocatedByInvoice[invoiceId]??0)).clamp(0,paid).toDouble();
   if(initialPaid>0){
    all.add({'date':x['date'],'sort':invoiceId*100000+1,'label':customer?'دفعة عند البيع':'دفعة عند التوريد','amount':initialPaid,'direction':-1});
   }
  }
  for(final x in payments){
   all.add({'date':x['date'],'sort':(x['id'] as num).toInt()*100000+50000,'label':(x['note']??(customer?'دفعة من الزبون':'دفعة للمورد')).toString(),'amount':(x['amount'] as num).toDouble(),'direction':-1});
  }
  for(final x in returns){
   final total=(x['total'] as num).toDouble(),cash=(x['cash_paid'] as num?)?.toDouble()??0;
   final net=customer?total-cash:total;
   final label=customer?(cash>0?'مرتجع زبون #'+x['id'].toString()+' (المعاد نقداً '+money(cash)+')':'مرتجع زبون #'+x['id'].toString()):'مرتجع مورد #'+x['id'].toString();
   all.add({'date':x['date'],'sort':x['id'],'label':label,'amount':net,'direction':-1});
  }
  all.sort((a,b){final c=(a['date'] as String).compareTo(b['date'] as String);return c!=0?c:(a['sort'] as int).compareTo(b['sort'] as int);});
  final start=fromDate==null?null:DateTime(fromDate!.year,fromDate!.month,fromDate!.day);
  final end=toDate==null?null:DateTime(toDate!.year,toDate!.month,toDate!.day,23,59,59,999);
  if(start!=null&&end!=null&&start.isAfter(end))throw Exception('تاريخ البداية يجب أن يسبق تاريخ النهاية');
  num opening=(party['opening_balance'] as num?)??0;
  final visible=<Map<String,Object?>>[];
  for(final x in all){
   final dt=DateTime.tryParse(x['date'].toString())?.toLocal();
   if(dt!=null&&start!=null&&dt.isBefore(start)){opening+=(x['amount'] as num)*(x['direction'] as int);continue;}
   if(dt!=null&&end!=null&&dt.isAfter(end))continue;
   visible.add(x);
  }
  num balance=opening;
  for(final x in visible){balance+=(x['amount'] as num)*(x['direction'] as int);x['balance']=balance;}
  return {'party':party,'transactions':visible,'opening':opening,'balance':balance};
 }
 Future<void> addPayment() async {
  final amount=TextEditingController(),note=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(widget.type=='customer'?'تسجيل دفعة من الزبون':'تسجيل دفعة للمورد'),
   content:Column(mainAxisSize:MainAxisSize.min,children:[field(amount,'المبلغ',number:true),field(note,'ملاحظة')]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('تسجيل'))],
  ));
  final value=int.tryParse(amount.text.trim())??0;
  if(ok!=true||value<=0)return;
  setState(()=>saving=true);
  try{
   int savedPaymentId=0;
   await ShopDb.instance.db.transaction((tx) async {
    final paymentId=await tx.insert('payments',{'party_type':widget.type,'party_id':widget.partyId,'date':DateTime.now().toIso8601String(),'amount':value,'note':note.text.trim().isEmpty?'دفعة حساب':note.text.trim()});
    savedPaymentId=paymentId;
    if(widget.type=='customer') await tx.insert('customer_payment_links',{'payment_id':paymentId,'customer_id':widget.partyId});
    else await tx.insert('supplier_payment_links',{'payment_id':paymentId,'supplier_id':widget.partyId});
    final customer=widget.type=='customer',invoiceType=customer?'sale':'purchase';
    final invoiceTable=customer?'sales':'purchases',partyColumn=customer?'customer_id':'supplier_id';
    final invoices=await tx.query(invoiceTable,where:'$partyColumn=? AND status=?',whereArgs:[widget.partyId,'posted'],orderBy:'date ASC,id ASC');
    var remaining=value;
    for(final invoice in invoices){
     if(remaining<=0)break;
     final due=((invoice['total'] as num)-(invoice['paid'] as num)).toInt();
     if(due<=0)continue;
     final allocated=remaining<due?remaining:due;
     await tx.update(invoiceTable,{'paid':(invoice['paid'] as num).toInt()+allocated},where:'id=?',whereArgs:[invoice['id']]);
     await tx.insert('payment_allocations',{'payment_id':paymentId,'invoice_type':invoiceType,'invoice_id':invoice['id'],'amount':allocated});
     if(customer) await tx.insert('sale_payment_allocations',{'payment_id':paymentId,'sale_id':invoice['id'],'amount':allocated});
     else await tx.insert('purchase_payment_allocations',{'payment_id':paymentId,'purchase_id':invoice['id'],'amount':allocated});
     remaining-=allocated;
    }
   });
   if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل السداد وتوزيعه على أقدم الفواتير المستحقة'))); await _showPaymentReceipt(context,type:widget.type,paymentId:savedPaymentId,partyName:(await ShopDb.instance.db.query(widget.type=='customer'?'customers':'suppliers',where:'id=?',whereArgs:[widget.partyId],limit:1)).first['name'].toString(),amount:value,note:note.text.trim());}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تسجيل الدفعة: $e')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 Future<void> export(Map<String,Object?> data) async {
  final party=data['party'] as Map<String,Object?>,tx=data['transactions'] as List<Map<String,Object?>>;
  final customer=widget.type=='customer';
  final out=StringBuffer()..writeln('# NaeemSoft POS')..writeln('## كشف حساب '+(customer?'زبون':'مورد'))..writeln('**الاسم:** '+party['name'].toString())..writeln('**الفترة:** '+dateText(fromDate)+' إلى '+dateText(toDate))..writeln('**الرصيد المرحل:** '+money(data['opening'] as num))..writeln('')..writeln('| التاريخ | البيان | مدين | دائن | الرصيد |')..writeln('|---|---|---:|---:|---:|');
  for(final x in tx){
   final amount=x['amount'] as num,dir=x['direction'] as int;
   final debit=(customer?dir>0:dir<0)?amount:0,credit=(customer?dir<0:dir>0)?amount:0;
   out.writeln('| '+x['date'].toString()+' | '+x['label'].toString()+' | '+money(debit)+' | '+money(credit)+' | '+money(x['balance'] as num)+' |');
  }
  out..writeln('')..writeln('**الرصيد الافتتاحي للفترة:** '+money(data['opening'] as num))..writeln('**الرصيد الختامي:** '+money(data['balance'] as num));
  final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title:'كشف حساب '+party['name'].toString(),author:'NaeemSoft POS',markdown:out.toString()));
  if(mounted)await Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(widget.type=='customer'?'كشف حساب الزبون':'كشف حساب المورد')),
  floatingActionButton:FloatingActionButton.extended(onPressed:saving?null:addPayment,icon:const Icon(Icons.payments),label:const Text('تسجيل دفعة')),
  body:FutureBuilder<Map<String,Object?>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(16),child:Text('تعذر تحميل الكشف: '+s.error.toString())));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final data=s.data!,party=data['party'] as Map<String,Object?>;
   final tx=data['transactions'] as List<Map<String,Object?>>,balance=data['balance'] as num,opening=data['opening'] as num;
   final customer=widget.type=='customer';
   return ListView(padding:const EdgeInsets.all(12),children:[
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(party['name'] as String,style:Theme.of(c).textTheme.titleLarge),Text((party['phone']??'').toString()),const SizedBox(height:8),
     Text('الرصيد الافتتاحي للفترة: '+money(opening)),
     Text('الرصيد '+(balance<0?'الدائن':'المستحق')+': '+money(balance.abs()),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
    ]))),
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
     const Align(alignment:Alignment.centerRight,child:Text('تصفية الكشف حسب الفترة',style:TextStyle(fontWeight:FontWeight.bold))),
     Row(children:[
      Expanded(child:OutlinedButton.icon(onPressed:()=>chooseDate(true),icon:const Icon(Icons.calendar_month),label:Text('من: '+dateText(fromDate)))),
      const SizedBox(width:8),
      Expanded(child:OutlinedButton.icon(onPressed:()=>chooseDate(false),icon:const Icon(Icons.calendar_month),label:Text('إلى: '+dateText(toDate)))),
     ]),
     TextButton.icon(onPressed:()=>setState((){fromDate=null;toDate=null;}),icon:const Icon(Icons.clear),label:const Text('عرض كل الفترة')),
    ]))),
    SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>export(data),icon:const Icon(Icons.picture_as_pdf),label:const Text('حفظ / مشاركة كشف الحساب PDF'))),
    if(tx.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('لا توجد حركات في الفترة المحددة',textAlign:TextAlign.center)),
    if(tx.isNotEmpty)SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
     columns:const [DataColumn(label:Text('التاريخ')),DataColumn(label:Text('البيان')),DataColumn(label:Text('مدين')),DataColumn(label:Text('دائن')),DataColumn(label:Text('الرصيد'))],
     rows:[
      DataRow(cells:[const DataCell(Text('—')),const DataCell(Text('رصيد مرحل')),DataCell(Text(customer?money(opening.abs()):'—')),DataCell(Text(customer?'—':money(opening.abs()))),DataCell(Text(money(opening)))]),
      ...tx.map((x){
       final amount=x['amount'] as num,dir=x['direction'] as int;
       final debit=(customer?dir>0:dir<0)?amount:0,credit=(customer?dir<0:dir>0)?amount:0;
       final dt=DateTime.tryParse(x['date'].toString())?.toLocal();
       return DataRow(cells:[
        DataCell(Text(dt==null?x['date'].toString():DateFormat('yyyy-MM-dd').format(dt))),DataCell(Text(x['label'] as String)),
        DataCell(Text(debit==0?'—':money(debit))),DataCell(Text(credit==0?'—':money(credit))),
        DataCell(Text(money(x['balance'] as num),style:const TextStyle(fontWeight:FontWeight.bold))),
       ]);
      }),
     ],
    )),
    Card(child:ListTile(
     title:Text(customer?'حالة حساب الزبون':'حالة حساب المورد'),
     subtitle:Text(balance>0?'مدين • عليه للمحل':balance<0?'دائن • للمحل عليه':'صفر • الحساب مسدد'),
     trailing:Text(money(balance.abs()),style:TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:balance>0?Colors.red:balance<0?Colors.green:null)),
    )),
   ]);
  }),
 );
}

class InvoicesPage extends StatelessWidget {
 const InvoicesPage({super.key});
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:const Text('الفواتير')),
  body:FutureBuilder<List<List<Map<String,Object?>>>>(
   future:Future.wait([rows('sales'),rows('purchases')]),
   builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final all=<Map<String,Object?>>[
     ...s.data![0].map((x)=>{...x,'kind':'بيع'}),
     ...s.data![1].map((x)=>{...x,'kind':'توريد'})
    ]..sort((a,b)=>(b['id'] as int).compareTo(a['id'] as int));
    if(all.isEmpty)return const Center(child:Text('لا توجد فواتير محفوظة بعد'));
    return ListView.separated(
     itemCount:all.length,separatorBuilder:(_,__)=>const Divider(height:1),
     itemBuilder:(c,i){
      final x=all[i],sale=x['kind']=='بيع';
      return ListTile(
       leading:CircleAvatar(child:Icon(sale?Icons.point_of_sale:Icons.local_shipping_outlined)),
       title:Text((sale?'فاتورة بيع رقم ':'فاتورة مورد رقم ')+x['id'].toString()),
       subtitle:Text(x['date'].toString()+' • '+money(x['paid'] as num)+' مدفوع • '+money((x['total'] as num)-(x['paid'] as num))+' متبقٍ'),
       trailing:Text(money(x['total'] as num),style:const TextStyle(fontWeight:FontWeight.bold)),
       onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>InvoiceDetailPage(type:sale?'sale':'purchase',invoiceId:x['id'] as int))),
      );
     });
   }));
}


class SaleInvoiceReviewPage extends StatelessWidget {
 final List<Map<String,dynamic>> items; final int total,paid; final String party;
 SaleInvoiceReviewPage({super.key,required this.items,required this.total,required this.paid,required this.party});
 final ScreenshotController shot=ScreenshotController();
 String get receiptText {
  final b=StringBuffer('NaeemSoft POS\\nمعاينة فاتورة بيع\\nالزبون: $party\\n--------------------\\n');
  for(final x in items){final g=x['grams'] as int,p=x['price_per_kg'] as int;b.writeln(x['name']);b.writeln('الكمية: ${(g/1000).toStringAsFixed(3)} كيلو');b.writeln('إجمالي الصنف: ${money((g*p/1000).round())}');}
  b.writeln('--------------------');b.writeln('الإجمالي: ${money(total)}');b.writeln('المدفوع: ${money(paid)}');b.writeln('المتبقي: ${money(total-paid)}');b.writeln('شكراً لتعاملكم معنا');return b.toString();
 }
 Future<void> shareImage(BuildContext c) async {
  try{final bytes=await shot.captureFromWidget(Directionality(textDirection:ui.TextDirection.rtl,child:Material(color:Colors.white,child:Padding(padding:const EdgeInsets.all(20),child:ReceiptShareCard(items:items,total:total,paid:paid,party:party)))),context:c,pixelRatio:3);
   await Share.shareXFiles([XFile.fromData(bytes,mimeType:'image/png',name:'NaeemSoft-invoice.png')],text:'فاتورة بيع - NaeemSoft POS');
  }catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('تعذر تجهيز صورة الفاتورة: $e')));}
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مراجعة فاتورة البيع قبل الترحيل')),body:ListView(padding:const EdgeInsets.all(12),children:[
  ReceiptShareCard(items:items,total:total,paid:paid,party:party),const SizedBox(height:12),
  Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>Share.share(receiptText,subject:'فاتورة بيع'),icon:const Icon(Icons.share),label:const Text('مشاركة التفاصيل'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>shareImage(c),icon:const Icon(Icons.image),label:const Text('مشاركة صورة')))]),
  const SizedBox(height:8),FilledButton.icon(onPressed:()=>Navigator.pop(c,true),icon:const Icon(Icons.check_circle),label:const Text('تأكيد وترحيل الفاتورة')),
  TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع للتعديل'))
 ]));
}
class ReceiptShareCard extends StatelessWidget {
 final List<Map<String,dynamic>> items;final int total,paid;final String party;
 const ReceiptShareCard({super.key,required this.items,required this.total,required this.paid,required this.party});
 @override Widget build(BuildContext c)=>Container(width:360,padding:const EdgeInsets.all(18),color:Colors.white,child:DefaultTextStyle(style:const TextStyle(color:Colors.black,fontSize:13),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
  const Text('NaeemSoft POS',textAlign:TextAlign.center,style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const Text('فاتورة بيع',textAlign:TextAlign.center,style:TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const Divider(thickness:2),
  Text('الزبون: $party'),Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),const Divider(),const Text('تفاصيل الأصناف',style:TextStyle(fontWeight:FontWeight.bold)),
  const Row(children:[Expanded(child:Text('اسم الصنف',style:TextStyle(fontWeight:FontWeight.bold))),Text('الكمية',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(width:12),Text('إجمالي الصنف',style:TextStyle(fontWeight:FontWeight.bold))]),
  const Divider(),
  ...items.map((x){final g=x['grams'] as int,p=x['price_per_kg'] as int;return Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(x['name'].toString(),style:const TextStyle(fontWeight:FontWeight.bold))),Text('${(g/1000).toStringAsFixed(3)} كجم'),const SizedBox(width:12),Text(money((g*p/1000).round()),style:const TextStyle(fontWeight:FontWeight.bold))]));}),
  _receiptRow('الإجمالي',money(total),strong:true),_receiptRow('المدفوع',money(paid)),_receiptRow('المتبقي',money(total-paid),strong:true),const SizedBox(height:8),const Text('شكراً لتعاملكم معنا',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold))
 ])));
}
Widget _receiptRow(String label,String value,{bool strong=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(label,style:TextStyle(fontWeight:strong?FontWeight.bold:FontWeight.normal))),Text(value,style:TextStyle(fontWeight:strong?FontWeight.bold:FontWeight.normal))]));
Future<File> _buildInvoicePdf({
 required String type,
 required int invoiceId,
 required Map<String,Object?> header,
 required List<Map<String,Object?>> lines,
 required String party,
}) async {
 // Download and cache the Arabic font before generating the receipt.
 await FontResolver.preload([
  'فاتورة مبيعات',
  'فاتورة توريد',
  'رقم الفاتورة',
  'التاريخ',
  'الزبون',
  'المورد',
  'تفاصيل الأصناف',
  'الإجمالي',
  'المدفوع',
  'المتبقي',
  'شكراً لتعاملكم معنا',
 ]);
 final sale=type=='sale';
 final total=header['total'] as num, paid=header['paid'] as num;
 final rawDate=DateTime.tryParse((header['date']??'').toString());
 final invoiceDate=rawDate==null?(header['date']??'').toString():DateFormat('yyyy-MM-dd  HH:mm').format(rawDate);
 final receiptHeight=(112 + lines.length*24).clamp(150, 500).toDouble();
 final sections=<PdfSection>[
  PdfSection.h1('NaeemSoft POS'),
  PdfSection.h2(sale?'فاتورة بيع':'فاتورة توريد'),
  PdfSection.paragraph('رقم الفاتورة: $invoiceId'),
  PdfSection.paragraph('التاريخ: $invoiceDate'),
  PdfSection.paragraph('${sale?'الزبون':'المورد'}: $party'),
  PdfSection.divider(),
  PdfSection.h2('تفاصيل الأصناف'),
 ];
 for(var i=0;i<lines.length;i++){
  final x=lines[i];
  final name=(x['product_name']??'صنف محذوف').toString();
  final quantity=sale
    ? 'الكمية: ${((x['quantity_grams'] as num)/1000).toStringAsFixed(3)} كيلو'
    : 'الكمية: ${x['packages']} عبوة، وزن العبوة ${x['weight_each']} كيلو';
  sections.add(PdfSection.paragraph(
    '$name\n$quantity\nإجمالي الصنف: ${money(x['line_total'] as num)}'
  ));
  sections.add(PdfSection.divider());
 }
 sections.addAll([
  PdfSection.h2('ملخص الحساب'),
  PdfSection.paragraph('الإجمالي: ${money(total)}'),
  PdfSection.paragraph('المدفوع: ${money(paid)}'),
  PdfSection.paragraph('المتبقي: ${money(total-paid)}'),
  PdfSection.paragraph('شكراً لتعاملكم معنا'),
 ]);
 return PdfBuilder.generate(PdfDocumentData(
  title:'${sale?'فاتورة بيع':'فاتورة توريد'} $invoiceId',
  author:'NaeemSoft POS',
  style:PdfStyle.minimal.copyWith(
   pageFormat:PdfPageFormat(80 * PdfPageFormat.mm, receiptHeight * PdfPageFormat.mm),
   horizontalMargin:12,
   verticalMargin:12,
   h1FontSize:16,
   h2FontSize:12,
   bodyFontSize:9,
   bodyLineHeight:1.35,
   showHeaderBar:false,
   showHeaderTitle:false,
   showPageNumbers:false,
   footerLeftText:null,
  ),
  sections:sections,
 ));
}

class InvoicePdfPreviewPage extends StatelessWidget {
 final File file;
 const InvoicePdfPreviewPage({super.key,required this.file});
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('معاينة الفاتورة PDF')),
  body:PdfPreview(
   build:(format)=>file.readAsBytes(),
   pdfFileName:file.uri.pathSegments.isEmpty?'NaeemSoft-Invoice.pdf':file.uri.pathSegments.last,
   canChangePageFormat:false,
   canChangeOrientation:false,
   canDebug:false,
  ),
 );
}

class InvoiceDetailPage extends StatelessWidget {
 final String type;
 final int invoiceId;
 const InvoiceDetailPage({super.key,required this.type,required this.invoiceId});
 Future<Map<String,Object?>> load() async {
  final sale=type=='sale';
  final header=(await ShopDb.instance.query(sale?'sales':'purchases',orderBy:'id DESC'))
    .firstWhere((x)=>x['id']==invoiceId);
  final lines=await ShopDb.instance.db.rawQuery(
   sale
    ? 'SELECT si.*,p.name product_name FROM sale_items si LEFT JOIN products p ON p.id=si.product_id WHERE si.sale_id=? ORDER BY si.id'
    : 'SELECT pi.*,p.name product_name FROM purchase_items pi LEFT JOIN products p ON p.id=pi.product_id WHERE pi.purchase_id=? ORDER BY pi.id',
   [invoiceId]);
  final returnRows=await ShopDb.instance.db.rawQuery(
   sale
    ? 'SELECT COALESCE(SUM(total-cash_paid),0) amount FROM returns WHERE sale_id=? AND return_type=?'
    : 'SELECT COALESCE(SUM(total),0) amount FROM returns WHERE purchase_id=? AND return_type=?',
   [invoiceId,sale?'customer':'supplier']);
  final returnCredit=(returnRows.first['amount'] as num?)??0;
  String? party;
  final partyId=header[sale?'customer_id':'supplier_id'];
  if(partyId!=null){
   final list=await ShopDb.instance.query(sale?'customers':'suppliers');
   final found=list.where((x)=>x['id']==partyId);
   if(found.isNotEmpty)party=found.first['name'] as String?;
  }
  return {'header':header,'lines':lines,'return_credit':returnCredit,'party':party??(sale?'نقدي / غير مسجل':'غير محدد')};
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text((type=='sale'?'فاتورة بيع #':'فاتورة مورد #')+invoiceId.toString())),
  body:FutureBuilder<Map<String,Object?>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Text('تعذر فتح الفاتورة: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final h=s.data!['header'] as Map<String,Object?>;
   final lines=s.data!['lines'] as List<Map<String,Object?>>;
   final sale=type=='sale',total=h['total'] as num,paid=h['paid'] as num,returnCredit=s.data!['return_credit'] as num,remaining=total-paid-returnCredit;
   return ListView(padding:const EdgeInsets.all(12),children:[
     SizedBox(width:double.infinity,child:FilledButton.icon(
      icon:const Icon(Icons.picture_as_pdf),
      label:const Text('طباعة / مشاركة / حفظ PDF'),
      onPressed:() async {
       try{
        final file=await _buildInvoicePdf(type:type,invoiceId:invoiceId,header:h,lines:lines,party:s.data!['party'].toString());
        if(c.mounted)await Navigator.push(c,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
       }catch(e){
        if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('تعذر إنشاء PDF: $e')));
       }
      },
     )),
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(sale?'فاتورة مبيعات':'فاتورة توريد',style:Theme.of(c).textTheme.titleLarge),
     Text('رقم الفاتورة: $invoiceId'),
     Text('التاريخ: ${h['date']}'),
     Text((sale?'الزبون: ':'المورد: ')+s.data!['party'].toString()),
    ]))),
    const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('تفاصيل الأصناف',style:TextStyle(fontWeight:FontWeight.bold))),
    if(lines.isNotEmpty)SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
     columns:const [
      DataColumn(label:Text('اسم الصنف')),
      DataColumn(label:Text('الكمية')),
      DataColumn(label:Text('إجمالي الصنف')),
     ],
     rows:lines.map((x){
      final quantity=sale
       ? '${((x['quantity_grams'] as num)/1000).toStringAsFixed(3)} كجم'
       : '${x['packages']} ${x['unit']} • ${x['weight_each']} كجم/وحدة';
      return DataRow(cells:[
       DataCell(Text((x['product_name']??'صنف محذوف').toString())),
       DataCell(Text(quantity)),
       DataCell(Text(money(x['line_total'] as num),style:const TextStyle(fontWeight:FontWeight.bold))),
      ]);
     }).toList(),
    )),
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
     _invoiceAmount('الإجمالي',total),
     _invoiceAmount('المدفوع نقداً',paid),
     _invoiceAmount('خصم المرتجعات',returnCredit),
     const Divider(),
     _invoiceAmount('المتبقي بعد المرتجعات',remaining),
    ]))),
    Text(sale?'تم خصم الكمية من مخزون الصنف.':'تمت إضافة الكمية إلى مخزون صنف المبيعات المرتبط.'),
   ]);
  }));
}

Widget _invoiceAmount(String label,num amount)=>Padding(
 padding:const EdgeInsets.symmetric(vertical:4),
 child:Row(children:[Expanded(child:Text(label)),Text(money(amount),style:const TextStyle(fontWeight:FontWeight.bold))]));



Future<void> _showReturnReceipt(BuildContext context,{required String type,required int returnId,required String partyName,required int amount}) async {
 final customer=type=='customer';
 final md='''# NaeemSoft POS\n\n## ${customer?'سند مرتجع زبون':'سند إرجاع إلى المورد'}\n\n- رقم السند: $returnId\n- التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n- ${customer?'الزبون':'المورد'}: $partyName\n- قيمة المرتجع: ${money(amount)}\n\nتم تسجيل المرتجع وتحديث الحساب والمخزون.''';
 final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title:'${customer?'مرتجع زبون':'مرتجع مورد'} $returnId',author:'NaeemSoft POS',markdown:md));
 if(context.mounted) await Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
}

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
   final kilos=double.tryParse((quantities[id]?.text??'0').trim().replaceAll(',', '.'))??0;
   final grams=(kilos*1000).round();
   if(grams>0)selected.add({'source_item_id':id,'grams':grams,'unit_price':(x['unit_price'] as num).toInt()});
  }
  if(selected.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل كمية مرتجعة لصنف واحد على الأقل')));return;}
  setState(()=>saving=true);
  try{
   final sourceInvoiceId=invoiceId!;
   final id=await ShopDb.instance.saveReturn(type:type,invoiceId:sourceInvoiceId,items:selected,cashPaid:type=='customer'?(int.tryParse(cash.text)??0):0);
   if(!mounted)return;
   final partyColumn=type=='customer'?'customer_id':'supplier_id';
   final invoiceTable=type=='customer'?'sales':'purchases';
   final invoice=(await ShopDb.instance.db.query(invoiceTable,where:'id=?',whereArgs:[sourceInvoiceId],limit:1)).first;
   final partyId=invoice[partyColumn] as int?;
   final partyName=partyId==null?(type=='customer'?'زبون نقدي':'مورد غير محدد'):(await ShopDb.instance.db.query(type=='customer'?'customers':'suppliers',where:'id=?',whereArgs:[partyId],limit:1)).first['name'].toString();
   final returnTotal=selected.fold<int>(0,(sum,x)=>sum+(((x['grams'] as int)*(x['unit_price'] as int))/1000).round());
   setState((){invoiceId=null;invoiceItems=[];quantities.clear();cash.text='0';});
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم حفظ المرتجع رقم $id')));
   await _showReturnReceipt(context,type:type,returnId:id,partyName:partyName,amount:returnTotal);
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
     TextField(controller:quantities[id],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الكمية المرتجعة بالكيلو',hintText:'مثال: 1 أو 0.5',border:OutlineInputBorder(),isDense:true)),
    ])));
   }),
   if(type=='customer')field(cash,'المبلغ الذي أُعيد نقداً للزبون',number:true),
   const SizedBox(height:8),
   FilledButton.icon(onPressed:saving?null:submit,icon:const Icon(Icons.save),label:Text(saving?'جارٍ الحفظ...':'حفظ المرتجع وتحديث الحساب')),
   const Padding(padding:EdgeInsets.only(top:12),child:Text('يجب اختيار الفاتورة الأصلية. لا يسمح النظام بإرجاع كمية أكبر من المتبقي من الصنف. يُخصم صافي المرتجع من حساب الزبون أو المورد المرتبط بالفاتورة.',style:TextStyle(height:1.5))),
  ]),
 );
}

class AccountsPage extends StatelessWidget {
 const AccountsPage({super.key});
 Future<List<num>> load() async {
  final db=ShopDb.instance.db;
  final r=await db.rawQuery("SELECT COALESCE(SUM(total-paid),0) v FROM sales WHERE status='posted'");
  final p=await db.rawQuery("SELECT COALESCE(SUM(total-paid),0) v FROM purchases WHERE status='posted'");
  final cr=await db.rawQuery("SELECT COALESCE(SUM(total-cash_paid),0) v FROM returns WHERE return_type='customer'");
  final sr=await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM returns WHERE return_type='supplier'");
  final s=await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM sales WHERE status='posted'");
  final b=await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM purchases WHERE status='posted'");
  return [(r.first['v'] as num)-(cr.first['v'] as num),(p.first['v'] as num)-(sr.first['v'] as num),s.first['v'] as num,b.first['v'] as num];
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('ملخص الحسابات')),
  body:FutureBuilder<List<num>>(future:load(),builder:(context,s){
   if(s.hasError)return Center(child:Text('تعذر تحميل الحسابات: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final v=s.data!;
   Widget item(String title,num amount,IconData icon)=>Card(child:ListTile(leading:Icon(icon),title:Text(title),trailing:Text(money(amount),style:const TextStyle(fontWeight:FontWeight.bold))));
   return ListView(padding:const EdgeInsets.all(12),children:[
    item('مستحقات الزبائن بعد المرتجعات',v[0],Icons.account_balance_wallet_outlined),
    item('مستحقات الموردين بعد المرتجعات',v[1],Icons.local_shipping_outlined),
    item('إجمالي فواتير البيع',v[2],Icons.point_of_sale),
    item('إجمالي فواتير التوريد',v[3],Icons.shopping_basket_outlined),
    const Text('هذا ملخص للأرصدة والفواتير، وليس تقرير صافي ربح. حساب الربح يتطلب تكلفة فعلية ومصروفات مسجلة.',style:TextStyle(height:1.5)),
   ]);
  }),
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
   if(s.hasError)return Center(child:Text('تعذر تحميل المسودات: ${s.error}'));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return const Center(child:Text('لا توجد مسودات محفوظة'));
   return ListView(children:s.data!.map<Widget>((d){
    final isSale=d['invoice_type']=='sale';
    final dt=DateTime.tryParse(d['updated_at'] as String);
    return Card(child:ListTile(
     leading:Icon(isSale?Icons.point_of_sale:Icons.local_shipping),
     title:Text((isSale?'مسودة بيع #':'مسودة توريد #')+d['id'].toString()),
     subtitle:Text((dt?.toLocal().toString().substring(0,16)??'')+' • '+money(d['total'] as num)),
     trailing:PopupMenuButton<String>(onSelected:(v)async{
      if(v=='delete'){await remove(d['id'] as int);}
      else{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);}
     },itemBuilder:(_)=>const[
      PopupMenuItem(value:'open',child:Text('استعادة المسودة')),
      PopupMenuItem(value:'delete',child:Text('حذف المسودة')),
     ]),
     onTap:()async{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);},
    ));
   }).toList());
  }),
 );
}
