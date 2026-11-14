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
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_db.dart';
import 'inventory_center.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier<Locale>(const Locale('ar'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedLanguage = preferences.getString('app_language') ?? 'ar';
  appLocale.value = Locale(['ar', 'en', 'fr'].contains(savedLanguage) ? savedLanguage : 'ar');
  await ShopDb.instance.open();
  runApp(const NaeemSoftApp());
}


String tr(String value) {
  final language = appLocale.value.languageCode;
  const translations = <String, Map<String, String>>{
    'en': {
      'العربية • English • Français':'العربية • English • Français',
      'الرئيسية':'Home',
      'المبيعات':'Sales',
      'التوريد':'Purchases',
      'المخزون':'Inventory',
      'الإدارة':'Administration',
      'بيع':'Sell',
      'توريد':'Purchase',
      'الأصناف والكميات':'Products & quantities',
      'ملخص اليوم':'Today summary',
      'إجمالي فواتير البيع المسجلة اليوم':'Total sales invoices today',
      'مشتريات اليوم':'Purchases today',
      'عدد الأصناف':'Products count',
      'المخزون الحالي':'Current stock',
      'النظام':'System',
      'محلي • محل واحد':'Local • Single shop',
      'الوصول السريع':'Quick access',
      'الأصناف':'Products',
      'الفواتير':'Invoices',
      'الموردون':'Suppliers',
      'الزبائن':'Customers',
      'الحسابات':'Accounts',
      'المرتجعات':'Returns',
      'المسودات':'Drafts',
      'كيلو':'Kilogram',
      'مسح':'Clear',
      'اختر وحدة الكمية':'Choose quantity unit',
      'إلغاء':'Cancel',
      'اختيار':'Select',
      'السلة فارغة':'Cart is empty',
      'بيانات فاتورة البيع':'Sales invoice details',
      'الإجمالي: ':'Total: ',
      'الزبون: ':'Customer: ',
      'نقدي / غير مسجل':'Cash / walk-in',
      'المبلغ المدفوع':'Amount paid',
      'رجوع':'Back',
      'معاينة الفاتورة':'Invoice preview',
      'المدفوع الآن':'Paid now',
      'حفظ الفاتورة':'Save invoice',
      'مورد غير محدد':'No supplier selected',
      'حسناً':'OK',
      'إضافة':'Add',
      'اعتماد':'Confirm',
      'حفظ مسودة':'Save draft',
      'جارٍ الحفظ...':'Saving...',
      'إتمام البيع':'Complete sale',
      'ترحيل فاتورة التوريد':'Post purchase invoice',
      'فاتورة توريد':'Purchase invoice',
      'المورد: ':'Supplier: ',
      'اسم الصنف':'Product name',
      'الكمية':'Quantity',
      'المدفوع':'Paid',
      'المتبقي':'Remaining',
      'تنبيهات صلاحية الأصناف':'Product expiry alerts',
      'لا توجد دفعات منتهية أو قريبة من الانتهاء':'No expired or soon-to-expire batches',
      'منتهي':'Expired',
      'قريب':'Expiring soon',
      'العربية':'Arabic',
      'مسودات الفواتير':'Invoice drafts',
      'ملخص الحسابات':'Accounts summary',
      'إضافة صنف':'Add product',
      'تعديل الصنف والسعر':'Edit product and price',
      'نوع الصنف':'Product type',
      'أصناف المبيعات':'Sales products',
      'أصناف التوريد':'Purchase products',
      'التصنيف':'Category',
      'بدون تصنيف':'Uncategorized',
      'وحدة الشراء الافتراضية':'Default purchase unit',
      'سعر بيع الكيلو':'Sale price per kg',
      'يتطلب تاريخ انتهاء الصلاحية':'Expiry date required',
      'التنبيه قبل الانتهاء بعدد الأيام':'Expiry warning (days)',
      'سعر التكلفة الافتراضي للوحدة':'Default unit cost',
      'صنف المبيعات المقابل للمخزون':'Linked stock sales product',
      'اختر صنف المبيعات':'Choose sales product',
      'حذف':'Delete',
      'مركز إدارة الأصناف':'Product management center',
      'إدارة التصنيفات':'Manage categories',
      'لا توجد أصناف نشطة':'No active products',
      'تعديل الاسم والوزن والسعر':'Edit name, weight and price',
      'إدارة الوحدات والعبوات':'Manage units and packages',
      'أوزان العبوات حسب المورد':'Package weights by supplier',
      'حذف الصنف':'Delete product',
      'إضافة تصنيف':'Add category',
      'اسم التصنيف':'Category name',
      'تصنيفات الأصناف':'Product categories',
      'إضافة وحدة أو عبوة':'Add unit or package',
      'تعديل الوحدة':'Edit unit',
      'إضافة وحدة':'Add unit',
      'تعديل':'Edit',
      'إضافة زبون':'Add customer',
      'إضافة مورد':'Add supplier',
      'تعديل بيانات الزبون':'Edit customer details',
      'تعديل بيانات المورد':'Edit supplier details',
      'الاسم':'Name',
      'الهاتف':'Phone',
      'حفظ':'Save',
      'بحث':'Search',
      'التاريخ':'Date',
      'السعر':'Price',
      'الإجمالي':'Total',
      'التفاصيل':'Details',
      'طباعة':'Print',
      'مشاركة':'Share',
      'حفظ PDF':'Save PDF',
      'كشف الحساب':'Account statement',
      'سداد المورد':'Supplier settlement',
      'تحصيل من الزبون':'Customer collection',
      'فاتورة بيع':'Sales invoice',
      'رقم الفاتورة: ':'Invoice number: ',
      'التاريخ: ':'Date: ',
      'تفاصيل الأصناف':'Item details',
      'الكمية: ':'Quantity: ',
      'عبوة، وزن العبوة':'packages, package weight',
      'إجمالي الصنف: ':'Item total: ',
      'ملخص الحساب':'Account summary',
      'المدفوع: ':'Paid: ',
      'المتبقي: ':'Remaining: ',
      'شكراً لتعاملكم معنا':'Thank you for your business',
      'سند قبض من زبون':'Customer receipt','سند مرتجع زبون':'Customer return voucher','سند إرجاع إلى المورد':'Supplier return voucher','قيمة المرتجع: ':'Return amount: ','تم تسجيل المرتجع وتحديث الحساب والمخزون.':'Return recorded; account and stock updated.','مرتجع مورد':'Supplier return',
      'سند سداد مورد':'Supplier payment voucher',
      'سند قبض':'Receipt voucher',
      'سند سداد':'Payment voucher',
      'البيان: ':'Description: ',
      'سداد حساب':'Account payment',
      'تم تسجيل العملية بنجاح.':'Transaction recorded successfully.',
      'معاينة فاتورة بيع':'Sales invoice preview',
      'غير محدد':'Unspecified',
      'رقم السند: ':'Voucher number: ',
      'المبلغ: ':'Amount: ',
      'معاينة الفاتورة PDF':'Invoice PDF preview',
      'صنف محذوف':'Deleted product',
      'كشف حساب زبون':'Customer statement',
      'كشف حساب مورد':'Supplier statement',
      'الاسم: ':'Name: ',
      'الفترة: ':'Period: ',
      ' إلى ':' to ',
      'الرصيد المرحل: ':'Opening balance: ',
      'الرصيد الافتتاحي للفترة: ':'Period opening balance: ',
      'الرصيد الختامي: ':'Closing balance: ',
      'تصفية الكشف حسب الفترة':'Filter statement by period',
      'من: ':'From: ',
      'إلى: ':'To: ',
      'من البداية':'From beginning',
      'لا توجد حركات في الفترة المحددة':'No transactions in the selected period',
      'الرصيد ':'Balance ',
      'الدائن':'Credit balance',
      'المستحق':'Due','مستحقات الزبائن بعد المرتجعات':'Customer balances due after returns','مستحقات الموردين بعد المرتجعات':'Supplier balances due after returns','إجمالي فواتير البيع':'Total sales invoices','إجمالي فواتير التوريد':'Total purchase invoices','لغة التطبيق / Application language / Langue':'Application language / Langue de l’application',
      'تم ترحيل فاتورة البيع رقم ':'Sales invoice posted #',
      'فاتورة توريد رقم ':'Purchase invoice #',
      'تعذر تحميل التنبيهات: ':'Could not load expiry alerts: ',
      'سيختفي الصنف':'This product will be removed',
      'من البيع والتوريد، مع الاحتفاظ به في الفواتير السابقة.':'from sales and purchases; previous invoices will be kept.',
      'تعذر تحميل الأصناف: ':'Could not load products: ',
      'تعذر إضافة التصنيف: ':'Could not add category: ',
      'حذف التصنيف؟':'Delete category?',
      'سيتم إلغاء ربط التصنيف بالصنف':'The category will be unlinked from product',
      'إن وجد، دون حذف الصنف أو فواتيره.':'if assigned; the product and its invoices will remain.',
      'حذف التصنيف':'Delete category',
      'تعذر تحميل التصنيفات: ':'Could not load categories: ',
      'لا توجد تصنيفات. أضف تصنيفاً جديداً.':'No categories. Add a new category.',
      'حذف الوحدة؟':'Delete unit?',
      'سيتم حذف وحدة':'The unit will be deleted',
      'من إعدادات الصنف.':'from product settings.',
      'وحدات وعبوات':'Units and packages',
      'تعذر تحميل الوحدات: ':'Could not load units: ',
      'لا توجد وحدات معرفة لهذا الصنف':'No units configured for this product',
      'الصنف: ':'Product: ',
      'كل وحدة تسجل بمعامل تحويل إلى الكيلوغرام، ويُستخدم وزن المورد إذا كان له وزن خاص لهذه العبوة.':'Each unit has a kg conversion factor; supplier-specific package weight overrides it when configured.',
      'المورد':'Supplier',
      'تعذر تحميل الأوزان: ':'Could not load package weights: ',
      'تعذر حفظ البيانات: ':'Could not save data: ',
      'سيختفي':'This record will disappear',
      'من قوائم الاختيار، مع الاحتفاظ بفواتيره وكشف حسابه.':'from selection lists; its invoices and statement will be retained.',
      'تعذر تحميل القائمة: ':'Could not load list: ','مستحق للمورد • على المحل':'Due to supplier • payable by shop','رصيد دائن • للمحل عند المورد':'Supplier credit • held by supplier','مدين • عليه للمحل':'Customer owes the shop','دائن • للمحل عليه':'Customer credit • owed by shop','صفر • الحساب مسدد':'Zero • settled',
      'حالة الحساب: جارٍ الحساب…':'Account status: calculating…',
      'الرصيد: ':'Balance: ',
      'تعذر تسجيل الدفعة: ':'Could not record payment: ',
      'تعذر تحميل الكشف: ':'Could not load statement: ',
      'تعذر تجهيز صورة الفاتورة: ':'Could not prepare invoice image: ',
      'تعذر فتح الفاتورة: ':'Could not open invoice: ',
      'تعذر إنشاء PDF: ':'Could not create PDF: ',
      'تم حفظ المرتجع رقم ':'Return saved #',
      'تعذر تحميل الحسابات: ':'Could not load accounts: ',
      'هذا ملخص للأرصدة والفواتير، وليس تقرير صافي ربح. حساب الربح يتطلب تكلفة فعلية ومصروفات مسجلة.':'This is an account and invoice summary, not a net-profit report. Profit requires actual costs and recorded expenses.',
      'تعذر تحميل المسودات: ':'Could not load drafts: ','تعديل وزن ':'Edit weight ',' في هذه الفاتورة':' in this invoice','تكلفة الوحدة الافتراضية: ':'Default unit cost: ','بدون اسم':'Unnamed',
      'ترحّل فواتير التوريد إلى المخزون، وتخصم فواتير البيع الكميات من الرصيد.':'Purchase invoices add stock; sales invoices deduct quantities.',
      'وحدة بيع':'Sales unit',
      'حُفظت مسودة فاتورة البيع رقم ':'Sales draft saved #',
      'الزبون (اختياري) • السعر الخاص إن وجد':'Customer (optional) • agreed price if available',
      'عدد العمليات: ':'Items: ',
      'الوحدة: ':'Unit: ',
      'سعر الكيلو: ':'Price per kg: ',
      'مسودة':'Draft',
      'اربط صنف التوريد بصنف المبيعات من إدارة الأصناف أولاً':'Link the purchase product to its sales stock item in Product Management first',
      'اختر عبوة':'Choose package',
      'حُفظت مسودة فاتورة التوريد رقم ':'Purchase draft saved #',
      'وزن الوحدة':'Unit weight',
      'اضغط لتعديل الوزن':'Tap to edit weight',
      'تكلفة العبوة':'Package cost',
      'أدخل عدد العبوات فقط: ':'Enter package count only: ',
      'العدد المعتمد: ':'Confirmed count: ',
      'الوحدة':'Unit',
      'الانتهاء: ':'Expiry: ',
      'الوحدة الافتراضية':'Default unit',
      'اختر المورد وأدخل وزناً صحيحاً':'Select a supplier and enter a valid weight',
      'تم حفظ وزن العبوة لهذا المورد':'Supplier package weight saved',
      'أوزان الموردين':'Supplier package weights',
      'إضافة وزن عبوة خاص بمورد':'Add supplier-specific package weight',
      'نوع العبوة':'Package type',
      'وزن العبوة: ':'Package weight: ',
      'تعديل الاسم والهاتف':'Edit name and phone',
      'كشف حساب ':'Account statement ',
      'تسجيل دفعة':'Record payment',
      'مدفوع':'Paid',
      'متبقٍ':'Remaining',
      'طباعة / مشاركة / حفظ PDF':'Print / share / save PDF',
      'مرتجعات الزبائن والموردين':'Customer and supplier returns',
      'مرتجع للمورد':'Supplier return',
      'لا توجد كميات متبقية للإرجاع في هذه الفاتورة':'No remaining quantities to return on this invoice',
      'المتاح للإرجاع: ':'Available to return: ',
      'سعر الوحدة: ':'Unit price: ',
      'حفظ المرتجع وتحديث الحساب':'Save return and update account',
      'يجب اختيار الفاتورة الأصلية. لا يسمح النظام بإرجاع كمية أكبر من المتبقي من الصنف. يُخصم صافي المرتجع من حساب الزبون أو المورد المرتبط بالفاتورة.':'Select the original invoice. Returns cannot exceed the remaining item quantity. The net return is deducted from the linked customer or supplier account.',
      'استعادة المسودة':'Restore draft',
      'حذف المسودة':'Delete draft',
      'تسجيل دفعة من الزبون':'Record customer payment',
      'تسجيل دفعة للمورد':'Record supplier payment',
      'ملاحظة':'Note',
      'تسجيل':'Record',
      'دفعة حساب':'Account payment',
      'تم تسجيل السداد وتوزيعه على أقدم الفواتير المستحقة':'Payment recorded and allocated to the oldest outstanding invoices',
      'حالة حساب الزبون':'Customer account status',
      'حالة حساب المورد':'Supplier account status',
      'دفعة من الزبون':'Customer payment',
      'دفعة للمورد':'Supplier payment',
      'مرتجع زبون':'Customer return',
      'حالة الحساب: ':'Account status: ',
      'المبلغ':'Amount',
      'سعر البيع: ':'Sale price: ',
      'التكلفة':'Cost',
      'أدخل كمية أو مبلغاً وسعراً صحيحاً':'Enter a valid quantity or amount and price',
      'موعد السداد YYYY-MM-DD':'Payment due date YYYY-MM-DD',
      'بيع نقدي / بدون زبون':'Cash sale / no customer',
      'بيع مباشر':'Direct sale',
      'قراءة الكاشير • العمليات المختارة':'Cashier • selected items',
      'عند اختيار أي صنف ستظهر عمليته هنا مباشرة':'Selected items will appear here',
      'إجمالي الصنف':'Item total',
      'وزن':'Weight',
      'نقد':'Cash amount',
      'أدخل الرقم':'Enter value',
      'جارٍ الترحيل...':'Posting...',
      'وحدة التوريد':'Purchase unit',
      'أدخل العدد وتكلفة الشراء، وسيُؤخذ الوزن تلقائياً من معرض الأصناف':'Enter package count; weight is read from product settings',
      'وزن الوحدة بالكيلو':'Unit weight (kg)',
      'الوزن غير صحيح':'Invalid weight',
      'الفاتورة فارغة':'Invoice is empty',
      'اختر المورد أولاً':'Select a supplier first',
      'اعتماد فاتورة التوريد':'Confirm purchase invoice',
      'تم تسجيل التوريد بقيمة ':'Purchase recorded for ',
      ' وتحديث مخزون أصناف المبيعات المرتبطة.':' and linked sales stock updated.',
      'أضف الأصناف من الإدارة أولاً':'Add products in Administration first',
      'قراءة كاشير التوريد • العمليات المختارة':'Purchase cashier • selected items',
      'الأصناف والعمليات التي تختارها ستظهر هنا':'Selected products and operations appear here',
      'إجمالي التوريد':'Purchase total',
      'عدد العبوات':'Package count',
      'سعر الشراء من مركز الأصناف':'Purchase price from Product Center',
      'السعر والوزن يُقرآن تلقائياً من إعدادات الصنف والمورد':'Price and weight are read from product and supplier settings',
      'معاينة فاتورة التوريد قبل الترحيل':'Preview purchase invoice before posting',
      'تأكيد وترحيل فاتورة التوريد':'Confirm and post purchase invoice',
      'رجوع للتعديل':'Back to edit',
      'تحقق من الاسم والوزن والسعر':'Check the name, weight and price',
      'تعذر حفظ الصنف: ':'Could not save product: ',
      'حذف الصنف من القائمة؟':'Remove product from the list?',
      'اسم الوحدة (كيس، جوان، حزمة، كرتون...)':'Unit name (bag, jowan, bundle, carton...)',
      'الوزن أو معامل التحويل بالكيلو':'Weight or conversion factor (kg)',
      'أدخل ما تعادله الوحدة بالكيلوغرام. مثال: كيس 25 كجم = 25':'Enter unit equivalent in kg. Example: 25 kg bag = 25',
      'تم حفظ الوحدة ومعامل تحويلها':'Unit and conversion factor saved',
      'تعذر الحفظ: ':'Could not save: ',
      'وزن العبوة بالكيلو':'Package weight (kg)',
      'حفظ وزن المورد':'Save supplier package weight',
      'الأوزان المسجلة حسب المورد':'Registered supplier package weights',
      'لا توجد أوزان خاصة مسجلة بعد.':'No supplier-specific weights registered yet.',
      'اكتب الاسم أولاً':'Enter the name first',
      'لا توجد فواتير محفوظة بعد':'No invoices saved yet',
      'عرض كل الفترة':'Show all dates',
      'حفظ / مشاركة كشف الحساب PDF':'Save / share account statement PDF',
      'البيان':'Description',
      'مدين':'Debit',
      'دائن':'Credit',
      'الرصيد':'Balance',
      'رصيد مرحل':'Opening balance',
      'مراجعة فاتورة البيع قبل الترحيل':'Review sales invoice before posting',
      'مشاركة التفاصيل':'Share details',
      'مشاركة صورة':'Share image',
      'تأكيد وترحيل الفاتورة':'Confirm and post invoice',
      'اختر الفاتورة الأصلية':'Select original invoice',
      'أدخل كمية مرتجعة لصنف واحد على الأقل':'Enter a return quantity for at least one item',
      'الكمية المرتجعة بالكيلو':'Returned quantity (kg)',
      'مثال: 1 أو 0.5':'Example: 1 or 0.5',
      'لا توجد مسودات محفوظة':'No saved drafts',
    
      'كجم':'kg',
      'كجم/وحدة':'kg/unit',
      'المدفوع نقداً':'Paid in cash',
      'خصم المرتجعات':'Returns deducted',
      'المتبقي بعد المرتجعات':'Balance after returns',
      'تم خصم الكمية من مخزون الصنف.':'Quantity deducted from product stock.',
      'تمت إضافة الكمية إلى مخزون صنف المبيعات المرتبط.':'Quantity added to the linked sales product stock.',
    
      'حذف الزبون؟':'Delete customer?',
      'حذف المورد؟':'Delete supplier?',
      'إدارة الزبائن':'Manage customers',
      'إدارة الموردين':'Manage suppliers',
      'لا يوجد زبائن مسجلون':'No customers registered',
      'لا يوجد موردون مسجلون':'No suppliers registered',
      'فاتورة بيع رقم ':'Sales invoice #',
      'فاتورة مورد رقم ':'Purchase invoice #',
      'فاتورة بيع #':'Sale invoice #',
      'فاتورة مورد #':'Supplier invoice #',
      'فاتورة مبيعات':'Sales invoice',
      'مسودات البيع':'Sales drafts',
      'مسودات التوريد':'Purchase drafts',
      'مسودة بيع #':'Sales draft #',
      'مسودة توريد #':'Purchase draft #',
    
      'التقارير':'Reports',
      'نوع التقرير':'Report type',
      'تقرير المبيعات اليومية':'Daily sales report',
      'تقرير المخزون':'Inventory report',
      'تقرير الأرباح والخسائر':'Profit and loss report',
      'المؤشر':'Metric',
      'القيمة':'Value',
      'إجمالي المبيعات':'Total sales',
      'مرتجعات الزبائن':'Customer returns',
      'صافي المبيعات':'Net sales',
      'المقبوض من المبيعات':'Sales received',
      'المتبقي على الزبائن':'Customer balances due',
      'مرتجعات الموردين':'Supplier returns',
      'مجمل الربح بعد المرتجعات':'Gross profit after returns',
      'المصروفات':'Expenses',
      'صافي الربح التقديري':'Estimated net profit',
      'تفاصيل فواتير البيع':'Sales invoice details',
      'الزبون':'Customer',
      'إجمالي الكمية: ':'Total quantity: ',
      'معاينة / طباعة / مشاركة PDF':'Preview / print / share PDF',
      'تعذر تحميل التقرير: ':'Could not load report: ',
      'صافي الربح التقديري يساوي مجمل الربح بعد المرتجعات ناقص المصروفات المسجلة للفترة.':'Estimated net profit equals gross profit after returns minus recorded expenses for the period.',
    
      'قيمة المخزون':'Inventory value',
    
      'المتبقي على الزبائن بعد المرتجعات':'Customer balance due after returns',
      'المقبوض الصافي من المبيعات':'Net sales receipts',
      'المتبقي للموردين بعد المرتجعات':'Supplier balance due after returns',
    
      'قيمة المخزون: ':'Stock value: ',
    
      'إجمالي الكمية':'Total quantity',
    
      'تنبيهات الصلاحية':'Expiry alerts',
    },
    'fr': {
      'لغة التطبيق / Application language / Langue':'Langue de l’application',
      'العربية • English • Français':'العربية • English • Français',
      'الرئيسية':'Accueil',
      'المبيعات':'Ventes',
      'التوريد':'Achats',
      'المخزون':'Stock',
      'الإدارة':'Administration',
      'بيع':'Vendre',
      'توريد':'Approvisionnement',
      'الأصناف والكميات':'Articles et quantités',
      'ملخص اليوم':'Résumé du jour',
      'إجمالي فواتير البيع المسجلة اليوم':'Total des factures de vente du jour',
      'مشتريات اليوم':'Achats du jour',
      'عدد الأصناف':'Nombre d’articles',
      'المخزون الحالي':'Stock actuel',
      'النظام':'Système',
      'محلي • محل واحد':'Local • Un seul magasin',
      'الوصول السريع':'Accès rapide',
      'الأصناف':'Articles',
      'الفواتير':'Factures',
      'الموردون':'Fournisseurs',
      'الزبائن':'Clients',
      'الحسابات':'Comptes',
      'المرتجعات':'Retours',
      'المسودات':'Brouillons',
      'كيلو':'Kilogramme',
      'مسح':'Effacer',
      'اختر وحدة الكمية':'Choisir l’unité de quantité',
      'إلغاء':'Annuler',
      'اختيار':'Sélectionner',
      'السلة فارغة':'Le panier est vide',
      'بيانات فاتورة البيع':'Détails de la facture de vente',
      'الإجمالي: ':'Total : ',
      'الزبون: ':'Client : ',
      'نقدي / غير مسجل':'Comptant / passage',
      'المبلغ المدفوع':'Montant payé',
      'رجوع':'Retour',
      'معاينة الفاتورة':'Aperçu de la facture',
      'المدفوع الآن':'Payé maintenant',
      'حفظ الفاتورة':'Enregistrer la facture',
      'مورد غير محدد':'Aucun fournisseur sélectionné',
      'حسناً':'OK',
      'إضافة':'Ajouter',
      'اعتماد':'Valider',
      'حفظ مسودة':'Enregistrer le brouillon',
      'جارٍ الحفظ...':'Enregistrement...',
      'إتمام البيع':'Finaliser la vente',
      'ترحيل فاتورة التوريد':'Valider la facture d’achat',
      'فاتورة توريد':'Facture d’achat',
      'المورد: ':'Fournisseur : ',
      'اسم الصنف':'Nom de l’article',
      'الكمية':'Quantité',
      'المدفوع':'Payé',
      'المتبقي':'Reste à payer',
      'تنبيهات صلاحية الأصناف':'Alertes d’expiration',
      'لا توجد دفعات منتهية أو قريبة من الانتهاء':'Aucun lot expiré ou proche de l’expiration',
      'منتهي':'Expiré',
      'قريب':'Bientôt expiré',
      'العربية':'Arabe',
      'مسودات الفواتير':'Brouillons de factures',
      'ملخص الحسابات':'Résumé des comptes',
      'إضافة صنف':'Ajouter un article',
      'تعديل الصنف والسعر':'Modifier l’article et le prix',
      'نوع الصنف':'Type d’article',
      'أصناف المبيعات':'Articles de vente',
      'أصناف التوريد':'Articles d’achat',
      'التصنيف':'Catégorie',
      'بدون تصنيف':'Sans catégorie',
      'وحدة الشراء الافتراضية':'Unité d’achat par défaut',
      'سعر بيع الكيلو':'Prix de vente au kg',
      'يتطلب تاريخ انتهاء الصلاحية':'Date d’expiration obligatoire',
      'التنبيه قبل الانتهاء بعدد الأيام':'Alerte avant expiration (jours)',
      'سعر التكلفة الافتراضي للوحدة':'Coût unitaire par défaut',
      'صنف المبيعات المقابل للمخزون':'Article de vente lié au stock',
      'اختر صنف المبيعات':'Choisir l’article de vente',
      'حذف':'Supprimer',
      'مركز إدارة الأصناف':'Centre de gestion des articles',
      'إدارة التصنيفات':'Gérer les catégories',
      'لا توجد أصناف نشطة':'Aucun article actif',
      'تعديل الاسم والوزن والسعر':'Modifier le nom, le poids et le prix',
      'إدارة الوحدات والعبوات':'Gérer les unités et emballages',
      'أوزان العبوات حسب المورد':'Poids des emballages par fournisseur',
      'حذف الصنف':'Supprimer l’article',
      'إضافة تصنيف':'Ajouter une catégorie',
      'اسم التصنيف':'Nom de la catégorie',
      'تصنيفات الأصناف':'Catégories d’articles',
      'إضافة وحدة أو عبوة':'Ajouter une unité ou un emballage',
      'تعديل الوحدة':'Modifier l’unité',
      'إضافة وحدة':'Ajouter une unité',
      'تعديل':'Modifier',
      'إضافة زبون':'Ajouter un client',
      'إضافة مورد':'Ajouter un fournisseur',
      'تعديل بيانات الزبون':'Modifier les données du client',
      'تعديل بيانات المورد':'Modifier les données du fournisseur',
      'الاسم':'Nom',
      'الهاتف':'Téléphone',
      'حفظ':'Enregistrer',
      'بحث':'Rechercher',
      'التاريخ':'Date',
      'السعر':'Prix',
      'الإجمالي':'Total',
      'التفاصيل':'Détails',
      'طباعة':'Imprimer',
      'مشاركة':'Partager',
      'حفظ PDF':'Enregistrer PDF',
      'كشف الحساب':'Relevé de compte',
      'سداد المورد':'Règlement fournisseur',
      'تحصيل من الزبون':'Encaissement client',
      'فاتورة بيع':'Facture de vente',
      'رقم الفاتورة: ':'N° de facture : ',
      'التاريخ: ':'Date : ',
      'تفاصيل الأصناف':'Détails des articles',
      'الكمية: ':'Quantité : ',
      'عبوة، وزن العبوة':'colis, poids du colis',
      'إجمالي الصنف: ':'Total de l’article : ',
      'ملخص الحساب':'Résumé du compte',
      'المدفوع: ':'Payé : ',
      'المتبقي: ':'Reste à payer : ',
      'شكراً لتعاملكم معنا':'Merci de votre confiance',
      'سند قبض من زبون':'Reçu client','سند مرتجع زبون':'Bon de retour client','سند إرجاع إلى المورد':'Bon de retour fournisseur','قيمة المرتجع: ':'Montant du retour : ','تم تسجيل المرتجع وتحديث الحساب والمخزون.':'Retour enregistré ; compte et stock mis à jour.','مرتجع مورد':'Retour fournisseur',
      'سند سداد مورد':'Bon de règlement fournisseur',
      'سند قبض':'Reçu',
      'سند سداد':'Bon de règlement',
      'البيان: ':'Description : ',
      'سداد حساب':'Règlement du compte',
      'تم تسجيل العملية بنجاح.':'Opération enregistrée avec succès.',
      'معاينة فاتورة بيع':'Aperçu de la facture de vente',
      'غير محدد':'Non spécifié',
      'رقم السند: ':'N° de pièce : ',
      'المبلغ: ':'Montant : ',
      'معاينة الفاتورة PDF':'Aperçu PDF de la facture',
      'صنف محذوف':'Article supprimé',
      'كشف حساب زبون':'Relevé client',
      'كشف حساب مورد':'Relevé fournisseur',
      'الاسم: ':'Nom : ',
      'الفترة: ':'Période : ',
      ' إلى ':' à ',
      'الرصيد المرحل: ':'Solde reporté : ',
      'الرصيد الافتتاحي للفترة: ':'Solde d’ouverture de la période : ',
      'الرصيد الختامي: ':'Solde de clôture : ',
      'تصفية الكشف حسب الفترة':'Filtrer le relevé par période',
      'من: ':'Du : ',
      'إلى: ':'Au : ',
      'من البداية':'Depuis le début',
      'لا توجد حركات في الفترة المحددة':'Aucune opération pour la période sélectionnée',
      'الرصيد ':'Solde ',
      'الدائن':'Créditeur',
      'المستحق':'Langue de l’application',
      'تم ترحيل فاتورة البيع رقم ':'Facture de vente validée n° ',
      'فاتورة توريد رقم ':'Facture d’achat n° ',
      'تعذر تحميل التنبيهات: ':'Impossible de charger les alertes d’expiration : ',
      'سيختفي الصنف':'Cet article sera retiré',
      'من البيع والتوريد، مع الاحتفاظ به في الفواتير السابقة.':'des ventes et achats ; les anciennes factures seront conservées.',
      'تعذر تحميل الأصناف: ':'Impossible de charger les articles : ',
      'تعذر إضافة التصنيف: ':'Impossible d’ajouter la catégorie : ',
      'حذف التصنيف؟':'Supprimer la catégorie ?',
      'سيتم إلغاء ربط التصنيف بالصنف':'La catégorie sera dissociée de l’article',
      'إن وجد، دون حذف الصنف أو فواتيره.':'si elle est liée, sans supprimer l’article ni ses factures.',
      'حذف التصنيف':'Supprimer la catégorie',
      'تعذر تحميل التصنيفات: ':'Impossible de charger les catégories : ',
      'لا توجد تصنيفات. أضف تصنيفاً جديداً.':'Aucune catégorie. Ajoutez-en une nouvelle.',
      'حذف الوحدة؟':'Supprimer l’unité ?',
      'سيتم حذف وحدة':'L’unité sera supprimée',
      'من إعدادات الصنف.':'des paramètres de l’article.',
      'وحدات وعبوات':'Unités et emballages',
      'تعذر تحميل الوحدات: ':'Impossible de charger les unités : ',
      'لا توجد وحدات معرفة لهذا الصنف':'Aucune unité configurée pour cet article',
      'الصنف: ':'Article : ',
      'كل وحدة تسجل بمعامل تحويل إلى الكيلوغرام، ويُستخدم وزن المورد إذا كان له وزن خاص لهذه العبوة.':'Chaque unité possède un facteur de conversion en kg ; le poids spécifique du fournisseur le remplace s’il existe.',
      'المورد':'Fournisseur',
      'تعذر تحميل الأوزان: ':'Impossible de charger les poids des colis : ',
      'تعذر حفظ البيانات: ':'Impossible d’enregistrer les données : ',
      'سيختفي':'Cet enregistrement disparaîtra',
      'من قوائم الاختيار، مع الاحتفاظ بفواتيره وكشف حسابه.':'des listes ; ses factures et son relevé seront conservés.',
      'تعذر تحميل القائمة: ':'Impossible de charger la liste : ','مستحق للمورد • على المحل':'Dû au fournisseur • payable par le magasin','رصيد دائن • للمحل عند المورد':'Crédit du magasin chez le fournisseur','مدين • عليه للمحل':'Client débiteur • dû au magasin','دائن • للمحل عليه':'Crédit client • dû par le magasin','صفر • الحساب مسدد':'Zéro • soldé',
      'حالة الحساب: جارٍ الحساب…':'État du compte : calcul en cours…',
      'الرصيد: ':'Solde : ',
      'تعذر تسجيل الدفعة: ':'Impossible d’enregistrer le paiement : ',
      'تعذر تحميل الكشف: ':'Impossible de charger le relevé : ',
      'تعذر تجهيز صورة الفاتورة: ':'Impossible de préparer l’image de la facture : ',
      'تعذر فتح الفاتورة: ':'Impossible d’ouvrir la facture : ',
      'تعذر إنشاء PDF: ':'Impossible de créer le PDF : ',
      'تم حفظ المرتجع رقم ':'Retour enregistré n° ',
      'تعذر تحميل الحسابات: ':'Impossible de charger les comptes : ',
      'هذا ملخص للأرصدة والفواتير، وليس تقرير صافي ربح. حساب الربح يتطلب تكلفة فعلية ومصروفات مسجلة.':'Ceci est un résumé des soldes et factures, pas un rapport de bénéfice net. Le bénéfice nécessite les coûts réels et les dépenses enregistrées.',
      'تعذر تحميل المسودات: ':'Impossible de charger les brouillons : ','تعديل وزن ':'Modifier le poids ',' في هذه الفاتورة':' dans cette facture','تكلفة الوحدة الافتراضية: ':'Coût unitaire par défaut : ','بدون اسم':'Sans nom',
      'ترحّل فواتير التوريد إلى المخزون، وتخصم فواتير البيع الكميات من الرصيد.':'Les achats alimentent le stock ; les ventes déduisent les quantités.',
      'وحدة بيع':'Unité de vente',
      'حُفظت مسودة فاتورة البيع رقم ':'Brouillon de vente enregistré n° ',
      'الزبون (اختياري) • السعر الخاص إن وجد':'Client (facultatif) • prix convenu si disponible',
      'عدد العمليات: ':'Articles : ',
      'الوحدة: ':'Unité : ',
      'سعر الكيلو: ':'Prix au kg : ',
      'مسودة':'Brouillon',
      'اربط صنف التوريد بصنف المبيعات من إدارة الأصناف أولاً':'Liez d’abord l’article d’achat à son article de stock de vente dans la gestion des articles',
      'اختر عبوة':'Choisir un emballage',
      'حُفظت مسودة فاتورة التوريد رقم ':'Brouillon d’achat enregistré n° ',
      'وزن الوحدة':'Poids unitaire',
      'اضغط لتعديل الوزن':'Touchez pour modifier le poids',
      'تكلفة العبوة':'Coût du colis',
      'أدخل عدد العبوات فقط: ':'Saisissez uniquement le nombre de colis : ',
      'العدد المعتمد: ':'Quantité validée : ',
      'الوحدة':'Unité',
      'الانتهاء: ':'Expiration : ',
      'الوحدة الافتراضية':'Unité par défaut',
      'اختر المورد وأدخل وزناً صحيحاً':'Sélectionnez un fournisseur et saisissez un poids valide',
      'تم حفظ وزن العبوة لهذا المورد':'Poids du colis fournisseur enregistré',
      'أوزان الموردين':'Poids par fournisseur',
      'إضافة وزن عبوة خاص بمورد':'Ajouter un poids spécifique au fournisseur',
      'نوع العبوة':'Type d’emballage',
      'وزن العبوة: ':'Poids du colis : ',
      'تعديل الاسم والهاتف':'Modifier le nom et le téléphone',
      'كشف حساب ':'Relevé de compte ',
      'تسجيل دفعة':'Enregistrer un paiement',
      'مدفوع':'Payé',
      'متبقٍ':'Restant',
      'طباعة / مشاركة / حفظ PDF':'Imprimer / partager / enregistrer PDF',
      'مرتجعات الزبائن والموردين':'Retours clients et fournisseurs',
      'مرتجع للمورد':'Retour fournisseur',
      'لا توجد كميات متبقية للإرجاع في هذه الفاتورة':'Aucune quantité restante à retourner sur cette facture',
      'المتاح للإرجاع: ':'Disponible au retour : ',
      'سعر الوحدة: ':'Prix unitaire : ',
      'حفظ المرتجع وتحديث الحساب':'Enregistrer le retour et mettre à jour le compte',
      'يجب اختيار الفاتورة الأصلية. لا يسمح النظام بإرجاع كمية أكبر من المتبقي من الصنف. يُخصم صافي المرتجع من حساب الزبون أو المورد المرتبط بالفاتورة.':'Sélectionnez la facture d’origine. Les retours ne peuvent pas dépasser la quantité restante. Le retour net est déduit du compte client ou fournisseur lié.',
      'استعادة المسودة':'Restaurer le brouillon',
      'حذف المسودة':'Supprimer le brouillon',
      'تسجيل دفعة من الزبون':'Enregistrer un paiement client',
      'تسجيل دفعة للمورد':'Enregistrer un règlement fournisseur',
      'ملاحظة':'Note',
      'تسجيل':'Enregistrer',
      'دفعة حساب':'Paiement du compte',
      'تم تسجيل السداد وتوزيعه على أقدم الفواتير المستحقة':'Paiement enregistré et affecté aux factures impayées les plus anciennes',
      'حالة حساب الزبون':'État du compte client',
      'حالة حساب المورد':'État du compte fournisseur',
      'دفعة من الزبون':'Paiement client',
      'دفعة للمورد':'Règlement fournisseur',
      'مرتجع زبون':'Retour client',
      'حالة الحساب: ':'État du compte : ',
      'المبلغ':'Montant',
      'سعر البيع: ':'Prix de vente : ',
      'التكلفة':'Coût',
      'أدخل كمية أو مبلغاً وسعراً صحيحاً':'Saisissez une quantité ou un montant et un prix valides',
      'موعد السداد YYYY-MM-DD':'Date d’échéance YYYY-MM-DD',
      'بيع نقدي / بدون زبون':'Vente comptant / sans client',
      'بيع مباشر':'Vente directe',
      'قراءة الكاشير • العمليات المختارة':'Caisse • articles sélectionnés',
      'عند اختيار أي صنف ستظهر عمليته هنا مباشرة':'Les articles sélectionnés apparaîtront ici',
      'إجمالي الصنف':'Total de l’article',
      'وزن':'Poids',
      'نقد':'Montant',
      'أدخل الرقم':'Saisir la valeur',
      'جارٍ الترحيل...':'Validation...',
      'وحدة التوريد':'Unité d’achat',
      'أدخل العدد وتكلفة الشراء، وسيُؤخذ الوزن تلقائياً من معرض الأصناف':'Saisissez le nombre de colis ; le poids vient des paramètres de l’article',
      'وزن الوحدة بالكيلو':'Poids unitaire (kg)',
      'الوزن غير صحيح':'Poids invalide',
      'الفاتورة فارغة':'La facture est vide',
      'اختر المورد أولاً':'Sélectionnez d’abord un fournisseur',
      'اعتماد فاتورة التوريد':'Valider la facture d’achat',
      'تم تسجيل التوريد بقيمة ':'Achat enregistré pour ',
      ' وتحديث مخزون أصناف المبيعات المرتبطة.':' et stock des articles liés mis à jour.',
      'أضف الأصناف من الإدارة أولاً':'Ajoutez d’abord les articles dans Administration',
      'قراءة كاشير التوريد • العمليات المختارة':'Caisse achats • articles sélectionnés',
      'الأصناف والعمليات التي تختارها ستظهر هنا':'Les articles et opérations sélectionnés apparaîtront ici',
      'إجمالي التوريد':'Total des achats',
      'عدد العبوات':'Nombre de colis',
      'سعر الشراء من مركز الأصناف':'Prix d’achat du centre articles',
      'السعر والوزن يُقرآن تلقائياً من إعدادات الصنف والمورد':'Le prix et le poids proviennent des paramètres de l’article et du fournisseur',
      'معاينة فاتورة التوريد قبل الترحيل':'Aperçu de la facture d’achat avant validation',
      'تأكيد وترحيل فاتورة التوريد':'Confirmer et valider la facture d’achat',
      'رجوع للتعديل':'Retour à la modification',
      'تحقق من الاسم والوزن والسعر':'Vérifiez le nom, le poids et le prix',
      'تعذر حفظ الصنف: ':'Impossible d’enregistrer l’article : ',
      'حذف الصنف من القائمة؟':'Supprimer l’article de la liste ?',
      'اسم الوحدة (كيس، جوان، حزمة، كرتون...)':'Nom de l’unité (sac, jowan, botte, carton...)',
      'الوزن أو معامل التحويل بالكيلو':'Poids ou facteur de conversion (kg)',
      'أدخل ما تعادله الوحدة بالكيلوغرام. مثال: كيس 25 كجم = 25':'Saisissez l’équivalent en kg. Exemple : sac de 25 kg = 25',
      'تم حفظ الوحدة ومعامل تحويلها':'Unité et facteur de conversion enregistrés',
      'تعذر الحفظ: ':'Échec de l’enregistrement : ',
      'وزن العبوة بالكيلو':'Poids du colis (kg)',
      'حفظ وزن المورد':'Enregistrer le poids fournisseur',
      'الأوزان المسجلة حسب المورد':'Poids enregistrés par fournisseur',
      'لا توجد أوزان خاصة مسجلة بعد.':'Aucun poids spécifique fournisseur enregistré.',
      'اكتب الاسم أولاً':'Saisissez d’abord le nom',
      'لا توجد فواتير محفوظة بعد':'Aucune facture enregistrée',
      'عرض كل الفترة':'Afficher toute la période',
      'حفظ / مشاركة كشف الحساب PDF':'Enregistrer / partager le relevé PDF',
      'البيان':'Description',
      'مدين':'Débit',
      'دائن':'Crédit',
      'الرصيد':'Solde',
      'رصيد مرحل':'Solde initial',
      'مراجعة فاتورة البيع قبل الترحيل':'Vérifier la facture de vente avant validation',
      'مشاركة التفاصيل':'Partager les détails',
      'مشاركة صورة':'Partager l’image',
      'تأكيد وترحيل الفاتورة':'Confirmer et valider la facture',
      'اختر الفاتورة الأصلية':'Sélectionnez la facture d’origine',
      'أدخل كمية مرتجعة لصنف واحد على الأقل':'Saisissez une quantité retournée pour au moins un article',
      'الكمية المرتجعة بالكيلو':'Quantité retournée (kg)',
      'مثال: 1 أو 0.5':'Exemple : 1 ou 0,5',
      'لا توجد مسودات محفوظة':'Aucun brouillon enregistré',
    
      'كجم':'kg',
      'كجم/وحدة':'kg/unité',
      'المدفوع نقداً':'Payé en espèces',
      'خصم المرتجعات':'Retours déduits',
      'المتبقي بعد المرتجعات':'Solde après retours',
      'تم خصم الكمية من مخزون الصنف.':'Quantité déduite du stock de l’article.',
      'تمت إضافة الكمية إلى مخزون صنف المبيعات المرتبط.':'Quantité ajoutée au stock de l’article de vente associé.',
    
      'حذف الزبون؟':'Supprimer le client ?',
      'حذف المورد؟':'Supprimer le fournisseur ?',
      'إدارة الزبائن':'Gérer les clients',
      'إدارة الموردين':'Gérer les fournisseurs',
      'لا يوجد زبائن مسجلون':'Aucun client enregistré',
      'لا يوجد موردون مسجلون':'Aucun fournisseur enregistré',
      'فاتورة بيع رقم ':'Facture de vente n° ',
      'فاتورة مورد رقم ':'Facture d’achat n° ',
      'فاتورة بيع #':'Facture de vente n° ',
      'فاتورة مورد #':'Facture fournisseur n° ',
      'فاتورة مبيعات':'Facture de vente',
      'مسودات البيع':'Brouillons de vente',
      'مسودات التوريد':'Brouillons d’achat',
      'مسودة بيع #':'Brouillon de vente n° ',
      'مسودة توريد #':'Brouillon d’achat n° ',
    
      'التقارير':'Rapports',
      'نوع التقرير':'Type de rapport',
      'تقرير المبيعات اليومية':'Rapport des ventes quotidiennes',
      'تقرير المخزون':'Rapport de stock',
      'تقرير الأرباح والخسائر':'Rapport des profits et pertes',
      'المؤشر':'Indicateur',
      'القيمة':'Valeur',
      'إجمالي المبيعات':'Ventes totales',
      'مرتجعات الزبائن':'Retours clients',
      'صافي المبيعات':'Ventes nettes',
      'المقبوض من المبيعات':'Encaissements des ventes',
      'المتبقي على الزبائن':'Soldes clients dus',
      'مرتجعات الموردين':'Retours fournisseurs',
      'مجمل الربح بعد المرتجعات':'Marge brute après retours',
      'المصروفات':'Dépenses',
      'صافي الربح التقديري':'Bénéfice net estimé',
      'تفاصيل فواتير البيع':'Détails des factures de vente',
      'الزبون':'Client',
      'إجمالي الكمية: ':'Quantité totale : ',
      'معاينة / طباعة / مشاركة PDF':'Aperçu / imprimer / partager PDF',
      'تعذر تحميل التقرير: ':'Impossible de charger le rapport : ',
      'صافي الربح التقديري يساوي مجمل الربح بعد المرتجعات ناقص المصروفات المسجلة للفترة.':'Le bénéfice net estimé correspond à la marge brute après retours moins les dépenses enregistrées pour la période.',
    
      'قيمة المخزون':'Valeur du stock',
    
      'المتبقي على الزبائن بعد المرتجعات':'Solde client dû après retours',
      'المقبوض الصافي من المبيعات':'Encaissements nets des ventes',
      'المتبقي للموردين بعد المرتجعات':'Solde fournisseur dû après retours',
    
      'قيمة المخزون: ':'Valeur du stock : ',
    
      'إجمالي الكمية':'Quantité totale',
    
      'تنبيهات الصلاحية':'Alertes d’expiration',
    }
  };
  return translations[language]?[value] ?? value;
}


String trStatementLabel(String label) {
  for (final prefix in ['فاتورة بيع','فاتورة توريد','دفعة من الزبون','دفعة للمورد','مرتجع زبون','مرتجع مورد']) {
    if (label.startsWith(prefix)) return tr(prefix) + label.substring(prefix.length);
  }
  return label;
}

Future<void> changeAppLanguage(String languageCode) async {
  if (!['ar', 'en', 'fr'].contains(languageCode)) return;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('app_language', languageCode);
  appLocale.value = Locale(languageCode);
}
String money(num n) => NumberFormat('#,##0', appLocale.value.languageCode).format(n) + ' DJF';
String kg(num g) => (g / 1000).toStringAsFixed(3) + (appLocale.value.languageCode == 'ar' ? ' كجم' : ' kg');
Future<List<Map<String,Object?>>> rows(String t) => ShopDb.instance.query(t);
Widget field(TextEditingController c, String label, {bool number=false}) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: TextField(controller:c, keyboardType:number ? const TextInputType.numberWithOptions(decimal:true) : TextInputType.text,
    decoration:InputDecoration(labelText:tr(label),border:const OutlineInputBorder(),isDense:true)));

class NaeemSoftApp extends StatelessWidget {
 const NaeemSoftApp({super.key});
 @override Widget build(BuildContext c)=>ValueListenableBuilder<Locale>(
  valueListenable:appLocale,
  builder:(context,locale,_)=>MaterialApp(
   title:'NaeemSoft POS',debugShowCheckedModeBanner:false,locale:locale,
   supportedLocales:const [Locale('ar'),Locale('en'),Locale('fr')],
   localizationsDelegates:const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
   ],
   theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff218653))),
   home:Directionality(
    textDirection:locale.languageCode=='ar'?ui.TextDirection.rtl:ui.TextDirection.ltr,
    child:const MainShell(),
   ),
  ),
 );
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
  Widget metric(String label,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(tr(label),style:const TextStyle(fontSize:11)),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:14))]))])));
  Widget action(String label,IconData icon,Widget page)=>Card(child:InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page)),child:Padding(padding:const EdgeInsets.symmetric(vertical:12,horizontal:5),child:Column(children:[Icon(icon,size:24),const SizedBox(height:5),Text(tr(label),style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))]))));
  return ListView(padding:const EdgeInsets.all(10),children:[
   Card(color:Theme.of(c).colorScheme.primaryContainer,child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(tr('ملخص اليوم')),Text(money(x[0]),style:Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),Text(tr('إجمالي فواتير البيع المسجلة اليوم'))]))),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:2.2,children:[metric('مشتريات اليوم',money(x[1]),Icons.local_shipping_outlined),metric('عدد الأصناف',x[2].toString(),Icons.category_outlined),metric('المخزون الحالي',kg(x[3]),Icons.inventory_2_outlined),metric('النظام','محلي • محل واحد',Icons.storefront_outlined)]),
   Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text(tr('الوصول السريع'),style:TextStyle(fontWeight:FontWeight.bold,fontSize:15))),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:4,childAspectRatio:.9,children:[action('الأصناف',Icons.category,const ProductsPage()),action('الفواتير',Icons.receipt_long,const InvoicesPage()),action('الموردون',Icons.local_shipping,const PartiesPage(type:'supplier')),action('الزبائن',Icons.people,const PartiesPage(type:'customer')),action('الحسابات',Icons.account_balance,const AccountsPage()),action('المرتجعات',Icons.assignment_return,const ReturnsPage()),action('المسودات',Icons.drafts,const DraftsPage()),action('الإدارة',Icons.settings,const AdminPage())]),
   Padding(padding:EdgeInsets.all(8),child:Text(tr('ترحّل فواتير التوريد إلى المخزون، وتخصم فواتير البيع الكميات من الرصيد.'),style:TextStyle(height:1.5)))
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
 String keypadValue=''; String saleMode='weight'; String selectedSaleUnitName='كيلو'; int selectedSaleUnitWeightGrams=1000;
 void key(String k){setState((){if(k=='مسح')keypadValue='';else if(k=='⌫'){if(keypadValue.isNotEmpty)keypadValue=keypadValue.substring(0,keypadValue.length-1);}else if(k=='½')keypadValue='0.5';else if(k=='¼')keypadValue='0.25';else if(k=='1 كجم')keypadValue='1';else if(keypadValue.isEmpty||keypadValue=='0')keypadValue=k;else keypadValue+=k;});}
 Future<void> changeCustomer(int? customerId) async {
  final updated=<int,Map<String,dynamic>>{};
  for(final entry in cart.entries){
   final product=await ShopDb.instance.db.query('products',columns:['sale_price'],where:'id=?',whereArgs:[entry.key],limit:1);
   var price=product.isEmpty?((entry.value['price_per_kg'] as num).round()):(product.first['sale_price'] as num).round();
   if(customerId!=null){
    final custom=await ShopDb.instance.db.query('customer_product_prices',where:'customer_id=? AND product_id=? AND active=1',whereArgs:[customerId,entry.key],limit:1);
    if(custom.isNotEmpty)price=(custom.first['price_per_kg'] as num).round();
   }
   updated[entry.key]={...entry.value,'price_per_kg':price};
  }
  if(mounted)setState((){selectedCustomerId=customerId;cart..clear()..addAll(updated);});
 }
 Future<void> add(Map<String,Object?> p) async {
  var price=(p['sale_price'] as num).round();
  if(selectedCustomerId!=null){
   final custom=await ShopDb.instance.db.query('customer_product_prices',where:'customer_id=? AND product_id=? AND active=1',whereArgs:[selectedCustomerId,p['id']],limit:1);
   if(custom.isNotEmpty) price=(custom.first['price_per_kg'] as num).round();
  }
  final id=(p['id'] as num).toInt();
  var unitName='كيلو',unitWeight=1000;
  if(saleMode=='weight'){
   final units=await ShopDb.instance.getProductUnits(id);
   if(units.isNotEmpty){
    final defaultName=(p['purchase_unit']??'كيلو').toString();
    final initial=units.firstWhere((x)=>x['unit_name']==defaultName,orElse:()=>units.first);
    final chosen=units.length==1?initial:await showDialog<Map<String,Object?>>(context:context,builder:(c){
     var selected=(initial['id'] as num).toInt();
     return StatefulBuilder(builder:(c,setChoice)=>AlertDialog(
      title:Text(tr('وحدة بيع')+' ${p['name']}'),
      content:DropdownButtonFormField<int>(
       value:selected,
       decoration:InputDecoration(labelText: tr('اختر وحدة الكمية')),
       items:units.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text('${x['unit_name']} • ${((x['default_weight_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كيلو')}'))).toList(),
       onChanged:(v){if(v!=null)setChoice(()=>selected=v);},
      ),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,units.firstWhere((x)=>(x['id'] as num).toInt()==selected)),child:Text(tr('اختيار')))],
     ));
    });
    if(chosen==null)return;
    unitName=chosen['unit_name'].toString();
    unitWeight=(chosen['default_weight_grams'] as num).toInt();
   }
  }
  final value=double.tryParse(keypadValue.replaceAll(',', '.'))??0;
  final grams=ShopDb.calculateSaleGrams(enteredValue:value,mode:saleMode,unitWeightGrams:unitWeight,pricePerKg:price);
  final old=cart[id]?['grams'] as int? ?? 0;
  if(grams<=0||price<=0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('أدخل كمية أو مبلغاً وسعراً صحيحاً'))));return;}
  setState((){
   cart[id]={'product_id':id,'name':p['name'],'grams':old+grams,'price_per_kg':price,'unit_name':unitName};
   selectedSaleUnitName=unitName;selectedSaleUnitWeightGrams=unitWeight;keypadValue='';
  });
 }
 int get total=>cart.values.fold(0,(v,x)=>v+(((x['grams'] as int)*(x['price_per_kg'] as int))/1000).round());
 Future<void> saveDraft() async {
  if(cart.isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('السلة فارغة'))));return;}
  try{final id=await ShopDb.instance.saveDraft(type:'sale',items:cart.values.toList(),total:total,draftId:activeDraftId);activeDraftId=null;cart.clear();if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('حُفظت مسودة فاتورة البيع رقم ')+id.toString())));}}
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
   title:Text(tr('بيانات فاتورة البيع')),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(tr('الإجمالي: ')+money(total)),
    Text(tr('الزبون: ')+(customer==null?tr('نقدي / غير مسجل'):customers.firstWhere((x)=>x['id']==customer)['name'].toString())),
    field(paid,'المبلغ المدفوع',number:true),field(due,'موعد السداد YYYY-MM-DD')
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('رجوع'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('معاينة الفاتورة')))]));
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
   if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تم ترحيل فاتورة البيع رقم ')+invoiceId.toString())));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }

 @override Widget build(BuildContext c) {
  return Column(children:[
   Padding(padding:const EdgeInsets.fromLTRB(8,6,8,2),child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('customers',where:'active=1',orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int?>(value:selectedCustomerId,decoration:InputDecoration(labelText: tr('الزبون (اختياري) • السعر الخاص إن وجد'),border:OutlineInputBorder(),isDense:true),items:[DropdownMenuItem<int?>(value:null,child:Text(tr('بيع نقدي / بدون زبون'))),...s.data!.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],onChanged:posting?null:(v)=>changeCustomer(v));
   })),
   FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:"active=1 AND product_type='sale'",orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const SizedBox(height:120,child:Center(child:CircularProgressIndicator()));
    final ps=s.data!, n=((s.data!.length+6)~/7).clamp(1,1000);
    return SizedBox(height:n*78.0,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),padding:const EdgeInsets.all(3),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,crossAxisSpacing:3,mainAxisSpacing:3,childAspectRatio:.78),itemCount:ps.length,itemBuilder:(c,i){
     final p=ps[i];return Card(margin:EdgeInsets.zero,child:InkWell(onTap:posting?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(2),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(p['name'] as String,maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:10)),
      Text(money(p['sale_price'] as num),maxLines:1,style:const TextStyle(fontSize:9)),
      Text(tr('بيع مباشر'),maxLines:1,style:TextStyle(fontSize:8))
     ]))));
    }));
   }),
   const Divider(height:5),
   Expanded(child:Container(
    margin:const EdgeInsets.symmetric(horizontal:7,vertical:3),padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(border:Border.all(color:Theme.of(c).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(10),color:Theme.of(c).colorScheme.surfaceContainerLowest),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(children:[const Icon(Icons.calculate_outlined,size:18),const SizedBox(width:5),Text(tr('قراءة الكاشير • العمليات المختارة'),style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(tr('عدد العمليات: ')+cart.length.toString(),style:const TextStyle(fontSize:11))]),
     const Divider(height:8),
     Expanded(child:cart.isEmpty?Center(child:Text(tr('عند اختيار أي صنف ستظهر عمليته هنا مباشرة'),style:TextStyle(color:Colors.grey))):ListView(children:cart.values.toList().asMap().entries.map((entry){
      final x=entry.value,grams=x['grams'] as int,price=x['price_per_kg'] as int;
      return Container(margin:const EdgeInsets.only(bottom:5),padding:const EdgeInsets.symmetric(horizontal:6,vertical:5),decoration:BoxDecoration(border:Border(bottom:BorderSide(color:Theme.of(c).colorScheme.outlineVariant))),child:Row(children:[
       SizedBox(width:22,child:Text('${entry.key+1}.',style:const TextStyle(fontSize:11,color:Colors.grey))),
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(x['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:13)),
        Text('${tr('الكمية: ')}${kg(grams)} • ${tr('الوحدة: ')}${x['unit_name']??tr('كيلو')} • ${tr('سعر الكيلو: ')}${money(price)}',style:const TextStyle(fontSize:11,color:Colors.grey))
       ])),
       Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(tr('إجمالي الصنف'),style:TextStyle(fontSize:9,color:Colors.grey)),Text(money((grams*price/1000).round()),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12))]),
       IconButton(visualDensity:VisualDensity.compact,constraints:const BoxConstraints.tightFor(width:28,height:28),iconSize:15,onPressed:posting?null:()=>setState(()=>cart.remove(x['product_id'])),icon:const Icon(Icons.close))
      ]));
     }).toList())),
     const Divider(height:8),
     Row(children:[Text(tr('الإجمالي'),style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(money(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))])
    ])
   )),
   Container(padding:const EdgeInsets.fromLTRB(7,4,7,5),color:Theme.of(c).colorScheme.surface,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Row(children:[Expanded(child:SegmentedButton<String>(showSelectedIcon:false,segments:[ButtonSegment(value:'weight',label:Text(tr('وزن'))),ButtonSegment(value:'cash',label:Text(tr('نقد')))],selected:{saleMode},onSelectionChanged:(v)=>setState(()=>saleMode=v.first))),SizedBox(width:6),Text((keypadValue.isEmpty?'أدخل الرقم':keypadValue)+(saleMode=='cash'?' DJF':' × ${selectedSaleUnitName}'),style:TextStyle(fontWeight:FontWeight.bold,fontSize:13))]),
    cashierNumberPad(keys:['7','8','9','⌫','4','5','6','مسح','1','2','3',if(saleMode=='weight')'½' else '.','0','.',if(saleMode=='weight')'¼' else '00',if(saleMode=='weight')'1 كجم' else 'مسح'],onKey:key),
    Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,child:Text(tr('مسودة')))),SizedBox(width:5),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,child:Text(tr('المسودات'))))]),
    SizedBox(width:double.infinity,height:42,child:FilledButton(onPressed:posting?null:checkout,child:Text(posting?tr('جارٍ الترحيل...'):tr('إتمام البيع'))))
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
 void applyKeypad(){final v=double.tryParse(keypadValue.replaceAll(',', '.'));if(v==null)return;setState((){packageCount=v.toInt();keypadValue='';});}
 Future<void> add(Map<String,Object?> p) async {
  if(p['paired_sale_product_id']==null){
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('اربط صنف التوريد بصنف المبيعات من إدارة الأصناف أولاً'))));
   return;
  }
  final count=packageCount;
  final productUnits=await ShopDb.instance.getProductUnits((p['id'] as num).toInt());
  var selectedUnit=(p['purchase_unit']??'كيلو').toString();
  if(productUnits.isNotEmpty){
   final selected=await showDialog<String>(context:context,builder:(c){
    var choice=selectedUnit;
    return StatefulBuilder(builder:(c,setChoice)=>AlertDialog(
     title:Text(tr('اختر عبوة')+' ${p['name']}'),
     content:DropdownButtonFormField<String>(
      value:productUnits.any((x)=>x['unit_name']==choice)?choice:productUnits.first['unit_name'] as String,
      decoration:InputDecoration(labelText: tr('وحدة التوريد')),
      items:productUnits.map((x)=>DropdownMenuItem<String>(value:x['unit_name'] as String,child:Text('${x['unit_name']} • ${((x['default_weight_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كيلو')}'))).toList(),
      onChanged:(v){if(v!=null)setChoice(()=>choice=v);},
     ),
     actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,choice),child:Text(tr('اختيار')))],
    ));
   });
   if(selected==null)return;
   selectedUnit=selected;
  }
  final configuredUnit=productUnits.where((x)=>x['unit_name']==selectedUnit).toList();
  final supplierUnit=await ShopDb.instance.db.query('supplier_product_units',where:'supplier_id=? AND product_id=? AND unit_name=?',whereArgs:[selectedSupplierId,p['id'],selectedUnit],limit:1);
  final supplierWeight=supplierUnit.isEmpty?null:(supplierUnit.first['weight_grams'] as num).toInt();
  final configuredWeight=configuredUnit.isEmpty?((p['default_weight'] as num)*1000).round():(configuredUnit.first['default_weight_grams'] as num).toInt();
  final weight=packageWeight>0?packageWeight:(supplierWeight??configuredWeight);
  final stockLink=await ShopDb.instance.db.query('product_stock_links',where:'purchase_product_id=?',whereArgs:[p['id']],limit:1);
  final stockProduct=stockLink.isEmpty?null:(await ShopDb.instance.db.query('products',where:'id=?',whereArgs:[stockLink.first['stock_product_id']],limit:1)).firstOrNull;
  final needsExpiry=(p['requires_expiry'] as num?)?.toInt()==1 || (stockProduct?['requires_expiry'] as num?)?.toInt()==1;
  String? lineExpiry;
  if (needsExpiry) {
   final picked=await showDatePicker(context:context,initialDate:DateTime.now().add(const Duration(days:30)),firstDate:DateTime.now(),lastDate:DateTime(2100));
   if(picked==null)return;
   lineExpiry=DateFormat('yyyy-MM-dd').format(picked);
  }
  // Purchase cost is centrally defined on the purchase product and is uniform across suppliers.
  // Supplier-specific settings may change package weight, never the product's purchase price.
  final enteredCost=(p['cost'] as num?)?.round() ?? 0;
  const effectiveMode='package';
  final price=enteredCost;
  if(count<=0||weight<=0||price<=0){
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('أدخل العدد وتكلفة الشراء، وسيُؤخذ الوزن تلقائياً من معرض الأصناف'))));
   return;
  }
  setState((){
   cart.add({'product_id':p['id'],'name':p['name'],'unit':selectedUnit,'packages':count,'weight_grams':weight,'package_cost':price,'cost_mode':effectiveMode,'entered_cost':enteredCost,'expiry_date':lineExpiry});
   packageCount=0;packageWeight=0;packageCost=0;keypadValue='';expiryDate=null;
  });
 }
 Future<void> editLineWeight(int index) async {
  final item=cart[index];
  final controller=TextEditingController(text:((item['weight_grams'] as int)/1000).toStringAsFixed(2));
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr('تعديل وزن ') + item['name'].toString() + tr(' في هذه الفاتورة')),
   content:field(controller,'وزن الوحدة بالكيلو',number:true),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ')))]));
  if(ok!=true)return;
  final value=double.tryParse(controller.text.replaceAll(',', '.'))??0;
  if(value<=0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('الوزن غير صحيح'))));return;}
  setState((){cart[index]['weight_grams']=(value*1000).round();if(item['cost_mode']=='kg'){cart[index]['package_cost']=(((item['entered_cost'] as num)*value).round());}});
 }
 int get total=>cart.fold(0,(v,x)=>v+(x['packages'] as int)*(x['package_cost'] as int));
 Future<void> saveDraft() async {
  if(cart.isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('الفاتورة فارغة'))));return;}
  try{final id=await ShopDb.instance.saveDraft(type:'purchase',items:cart,total:total,draftId:activeDraftId);activeDraftId=null;cart.clear();if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('حُفظت مسودة فاتورة التوريد رقم ')+id.toString())));}}
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
  if(selectedSupplierId==null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('اختر المورد أولاً'))));return;}
  final paid=TextEditingController(text:'0'),due=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(tr('اعتماد فاتورة التوريد')),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('الإجمالي: '+money(total)),field(paid,'المدفوع الآن',number:true),field(due,'موعد السداد YYYY-MM-DD')]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('رجوع'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ الفاتورة')))]));
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
   if(mounted){setState((){});await showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(tr('فاتورة توريد رقم ')+id.toString()),content:Text(tr('تم تسجيل التوريد بقيمة ')+money(total)+tr(' وتحديث مخزون أصناف المبيعات المرتبطة.')),actions:[FilledButton(onPressed:()=>Navigator.pop(c),child:Text(tr('حسناً')))]));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>posting=false);}
 }
 @override Widget build(BuildContext c){
  final w=MediaQuery.of(c).size.width;
  return Column(children:[
   Padding(padding:const EdgeInsets.fromLTRB(8,6,8,2),child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('suppliers',where:'active=1',orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int>(value:selectedSupplierId,decoration:InputDecoration(labelText: tr('اختر المورد أولاً'),prefixIcon:Icon(Icons.local_shipping_outlined),border:OutlineInputBorder(),isDense:true),items:s.data!.map((v)=>DropdownMenuItem<int>(value:v['id'] as int,child:Text(v['name'] as String))).toList(),onChanged:posting?null:(v)=>setState(()=>selectedSupplierId=v));
   })),
   SizedBox(height:104,child:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:"active=1 AND product_type='purchase'",orderBy:'name'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return Center(child:Text(tr('أضف الأصناف من الإدارة أولاً')));
    return ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:3),itemCount:s.data!.length,itemBuilder:(c,i){
     final p=s.data![i];return SizedBox(width:w/7.2,child:Card(margin:const EdgeInsets.all(2),child:InkWell(onTap:posting||selectedSupplierId==null?null:()=>add(p),child:Padding(padding:const EdgeInsets.all(2),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(p['name'] as String,maxLines:2,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:10)),Text(p['purchase_unit'] as String,style:const TextStyle(fontSize:9)),Text(tr('إضافة'),style:TextStyle(fontSize:9))])))));
    });
   })),
   Expanded(child:Container(
    margin:const EdgeInsets.symmetric(horizontal:7,vertical:3),padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(border:Border.all(color:Theme.of(c).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(10),color:Theme.of(c).colorScheme.surfaceContainerLowest),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(children:[const Icon(Icons.calculate_outlined,size:18),const SizedBox(width:5),Text(tr('قراءة كاشير التوريد • العمليات المختارة'),style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(tr('عدد العمليات: ')+cart.length.toString(),style:const TextStyle(fontSize:11))]),
     const Divider(height:8),
     Expanded(child:cart.isEmpty?Center(child:Text(tr('الأصناف والعمليات التي تختارها ستظهر هنا'),style:TextStyle(color:Colors.grey))):ListView(children:cart.asMap().entries.map((e){
      final x=e.value,line=(x['packages'] as int)*(x['package_cost'] as int);
      return Padding(padding:const EdgeInsets.symmetric(vertical:4),child:InkWell(onTap:()=>editLineWeight(e.key),child:Row(children:[
       Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(x['name'] as String,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
        Text('${tr('الكمية')} ${x['packages']} ${x['unit']}، ${tr('وزن الوحدة')} ${((x['weight_grams'] as int)/1000).toStringAsFixed(2)} ${tr('كيلو')} • ${tr('اضغط لتعديل الوزن')}',style:const TextStyle(fontSize:10,color:Colors.grey)),
        Text('${tr('تكلفة العبوة')} ${money(x['package_cost'] as num)}',style:const TextStyle(fontSize:10,color:Colors.grey))
       ])),
       Text(money(line),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),
       IconButton(visualDensity:VisualDensity.compact,constraints:const BoxConstraints.tightFor(width:28,height:28),iconSize:15,onPressed:posting?null:()=>setState(()=>cart.removeAt(e.key)),icon:const Icon(Icons.close))
      ])));
     }).toList())),
     const Divider(height:8),
     Row(children:[Text(tr('إجمالي التوريد'),style:TextStyle(fontWeight:FontWeight.bold)),const Spacer(),Text(money(total),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))])
    ])
   )),
   Container(padding:const EdgeInsets.fromLTRB(7,3,7,4),color:Theme.of(c).colorScheme.surface,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Row(children:[ChoiceChip(label:Text(tr('عدد العبوات')),selected:true,onSelected:null),Spacer(),Text('سعر الشراء من مركز الأصناف',style:TextStyle(fontSize:11,color:Colors.grey))]),
    Text('${tr('أدخل عدد العبوات فقط: ')}${keypadValue.isEmpty?'—':keypadValue} • ${tr('العدد المعتمد: ')}${packageCount==0?'—':packageCount} • ${tr('السعر والوزن يُقرآن تلقائياً من إعدادات الصنف والمورد')}',style:const TextStyle(fontSize:10)), 
    cashierNumberPad(keys:['7','8','9','⌫','4','5','6','مسح','1','2','3','.','0','00','اعتماد'],onKey:(k)=>k=='اعتماد'?applyKeypad():key(k)),
    Row(children:[Expanded(child:OutlinedButton(onPressed:posting?null:saveDraft,child:Text(tr('حفظ مسودة')))),SizedBox(width:4),Expanded(child:OutlinedButton(onPressed:posting?null:openDrafts,child:Text(tr('المسودات'))))]),
    SizedBox(width:double.infinity,height:40,child:FilledButton(onPressed:posting?null:save,child:Text(posting?tr('جارٍ الحفظ...'):tr('ترحيل فاتورة التوريد'))))
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
  appBar:AppBar(title:Text(tr('معاينة فاتورة التوريد قبل الترحيل'))),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('NaeemSoft POS',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
    Center(child:Text(tr('فاتورة توريد'),style:TextStyle(fontWeight:FontWeight.bold,fontSize:16))),
    const Divider(),
    Text(tr('المورد: ')+party),
    Text(tr('التاريخ: ')+DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
    const Divider(),
    Row(children:[Expanded(child:Text(tr('اسم الصنف'),style:TextStyle(fontWeight:FontWeight.bold))),Text(tr('الكمية'),style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(width:10),Text(tr('إجمالي الصنف'),style:TextStyle(fontWeight:FontWeight.bold))]),
    const Divider(),
    ...items.map((x)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[
     Expanded(child:Text(x['name'].toString(),style:const TextStyle(fontWeight:FontWeight.bold))),
     Text('${x['packages']} ${x['unit']} • ${((x['weight_grams'] as num)/1000).toStringAsFixed(2)} kg/${tr('الوحدة')}'),
     const SizedBox(width:10),
     Text(money((x['packages'] as num)*(x['package_cost'] as num)),style:const TextStyle(fontWeight:FontWeight.bold)),
    ]))),
    const Divider(),
    _receiptRow('الإجمالي',money(total),strong:true),
    _receiptRow('المدفوع',money(paid)),
    _receiptRow('المتبقي',money(total-paid),strong:true),
   ]))),
   FilledButton.icon(onPressed:()=>Navigator.pop(c,true),icon:Icon(Icons.check_circle),label:Text(tr('تأكيد وترحيل فاتورة التوريد'))),
   TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('رجوع للتعديل'))),
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
  appBar:AppBar(title:Text(tr('تنبيهات صلاحية الأصناف'))),
  body:FutureBuilder<List<Map<String,Object?>>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل التنبيهات: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return Center(child:Text(tr('لا توجد دفعات منتهية أو قريبة من الانتهاء')));
   return ListView(children:s.data!.map((x){
    final expiry=DateTime.tryParse(x['expiry_date'].toString());
    final expired=expiry!=null&&expiry.isBefore(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day));
    return ListTile(
     leading:Icon(expired?Icons.warning_amber_rounded:Icons.schedule,color:expired?Colors.red:Colors.orange),
     title:Text(x['product_name'].toString()),
     subtitle:Text('${tr('الانتهاء: ')}${x['expiry_date']} • ${tr('المتبقي: ')}${kg(x['remaining_grams'] as num)}'),
     trailing:Text(tr(expired?'منتهي':'قريب'),style:TextStyle(color:expired?Colors.red:Colors.orange,fontWeight:FontWeight.bold)),
    );
   }).toList());
  }),
 );
}

class AdminPage extends StatelessWidget {
 const AdminPage({super.key});
 @override Widget build(BuildContext c)=>ListView(children:[
  ListTile(
   leading:const Icon(Icons.language),
   title:Text(tr('لغة التطبيق / Application language / Langue')),
   subtitle:Text(tr('العربية • English • Français')),
   trailing:DropdownButton<String>(
    value:appLocale.value.languageCode,
    items: [
     DropdownMenuItem(value:'ar',child:Text(tr('العربية'))),
     DropdownMenuItem(value:'en',child:Text('English')),
     DropdownMenuItem(value:'fr',child:Text('Français')),
    ],
    onChanged:(value){if(value!=null)changeAppLanguage(value);},
   ),
  ),
  _link(c,'الأصناف',Icons.category,const ProductsPage()),_link(c,'الموردون',Icons.local_shipping,const PartiesPage(type:'supplier')),
  _link(c,'الزبائن',Icons.people,const PartiesPage(type:'customer')),_link(c,'الفواتير',Icons.receipt_long,const InvoicesPage()),_link(c,'المرتجعات',Icons.assignment_return,const ReturnsPage()),_link(c,'مسودات الفواتير',Icons.drafts,const DraftsPage()),
  _link(c,'ملخص الحسابات',Icons.account_balance,const AccountsPage()),_link(c,'التقارير',Icons.analytics,const ReportsPage()),_link(c,'تنبيهات الصلاحية',Icons.warning_amber,const ExpiryAlertsPage())
 ]);
 Widget _link(BuildContext c,String t,IconData i,Widget p)=>ListTile(
  leading:Icon(i),title:Text(tr(t)),trailing:const Icon(Icons.chevron_left),
  onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>p)),
 );
}
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
   title:Text(tr(product==null?'إضافة صنف':'تعديل الصنف والسعر')),
   content:StatefulBuilder(builder:(c,setDialogState)=>SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    field(n,'اسم الصنف'),DropdownButtonFormField<String>(value:productType,decoration:InputDecoration(labelText: tr('نوع الصنف')),items:[DropdownMenuItem(value:'sale',child:Text(tr('أصناف المبيعات'))),DropdownMenuItem(value:'purchase',child:Text(tr('أصناف التوريد')))],onChanged:(v){if(v!=null)setDialogState(()=>productType=v);}),DropdownButtonFormField<int?>(value:categories.any((x)=>(x['id'] as num).toInt()==categoryId)?categoryId:null,decoration:InputDecoration(labelText: tr('التصنيف')),items:[DropdownMenuItem<int?>(value:null,child:Text(tr('بدون تصنيف'))),...categories.map((x)=>DropdownMenuItem<int?>(value:(x['id'] as num).toInt(),child:Text(x['name'] as String)))],onChanged:(v)=>setDialogState(()=>categoryId=v)),field(u,'وحدة الشراء الافتراضية'),field(w,'وزن الوحدة بالكيلو',number:true),if(productType=='sale')field(price,'سعر بيع الكيلو',number:true),
    CheckboxListTile(contentPadding:EdgeInsets.zero,value:requiresExpiry,title:Text(tr('يتطلب تاريخ انتهاء الصلاحية')),onChanged:(v)=>setDialogState(()=>requiresExpiry=v??false)),
    if(requiresExpiry)field(expiryDays,'التنبيه قبل الانتهاء بعدد الأيام',number:true),
    if(productType=='purchase')...[
     field(cost,'سعر التكلفة الافتراضي للوحدة',number:true),
     DropdownButtonFormField<int?>(value:saleProducts.any((x)=>x['id']==pairedSaleProductId)?pairedSaleProductId:null,decoration:InputDecoration(labelText: tr('صنف المبيعات المقابل للمخزون'),border:OutlineInputBorder(),isDense:true),items:[DropdownMenuItem<int?>(value:null,child:Text(tr('اختر صنف المبيعات'))),...saleProducts.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'] as String)))],onChanged:(v)=>setDialogState(()=>pairedSaleProductId=v))
    ]
   ]))),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ')))]));
  if(ok!=true)return;
  final weight=double.tryParse(w.text)??0,p=int.tryParse(price.text)??-1, purchaseCost=int.tryParse(cost.text)??-1;
  if(n.text.trim().isEmpty||u.text.trim().isEmpty||weight<=0||p<0||(productType=='purchase'&&(purchaseCost<0||pairedSaleProductId==null))){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تحقق من الاسم والوزن والسعر'))));return;}
  try{
   if(product==null){await ShopDb.instance.addProduct(n.text,u.text,(weight*1000).round(),p,productType:productType,cost:productType=='purchase'?purchaseCost:0,pairedSaleProductId:productType=='purchase'?pairedSaleProductId:null,categoryId:categoryId,requiresExpiry:requiresExpiry,expiryWarningDays:int.tryParse(expiryDays.text)??7);}
   else{await ShopDb.instance.updateProduct(id:product['id'] as int,name:n.text,unit:u.text,defaultWeightGrams:(weight*1000).round(),salePrice:p,productType:productType,cost:productType=='purchase'?purchaseCost:0,pairedSaleProductId:productType=='purchase'?pairedSaleProductId:null,categoryId:categoryId,requiresExpiry:requiresExpiry,expiryWarningDays:int.tryParse(expiryDays.text)??7);}
   if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر حفظ الصنف: ')+e.toString())));}
 }
 Future<void> archive(Map<String,Object?> product) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr('حذف الصنف من القائمة؟')),
   content:Text('${tr('سيختفي الصنف')} «${product['name']}» ${tr('من البيع والتوريد، مع الاحتفاظ به في الفواتير السابقة.')}'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حذف')))]));
  if(ok==true){await ShopDb.instance.deactivateProduct(product['id'] as int);if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text(tr('مركز إدارة الأصناف')),actions:[IconButton(tooltip: tr('إدارة التصنيفات'),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CategoriesPage())).then((_) {if(mounted)setState((){});}),icon:Icon(Icons.category_outlined))]),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('products',where:'active=1',orderBy:'name'),builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل الأصناف: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return Center(child:Text(tr('لا توجد أصناف نشطة')));
   return ListView(children:s.data!.map((p)=>ListTile(
    leading:const Icon(Icons.category_outlined),
    title:Text(p['name'] as String),
    subtitle:Text(p['product_type']=='purchase'?'${p['purchase_unit']} • ${tr('تكلفة الوحدة الافتراضية: ')}${money(p['cost'] as num)}':'${p['purchase_unit']} • ${money(p['sale_price'] as num)} / ${tr('كيلو')}'),
    trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);else if(v=='supplier')Navigator.push(context,MaterialPageRoute(builder:(_)=>SupplierPackageWeightsPage(product:p)));else if(v=='units')Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductUnitsPage(product:p))).then((_){if(mounted)setState((){});});else archive(p);},itemBuilder:(_)=>[
     PopupMenuItem(value:'edit',child:Text(tr('تعديل الاسم والوزن والسعر'))),
     PopupMenuItem(value:'units',child:Text(tr('إدارة الوحدات والعبوات'))),
     if(p['product_type']=='purchase')PopupMenuItem(value:'supplier',child:Text(tr('أوزان العبوات حسب المورد'))),
     PopupMenuItem(value:'delete',child:Text(tr('حذف الصنف'))),
    ]),
    onTap:()=>edit(p),
   )).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(null),icon:Icon(Icons.add),label:Text(tr('إضافة صنف'))));
}
class CategoriesPage extends StatefulWidget {
 const CategoriesPage({super.key});
 @override State<CategoriesPage> createState()=>_CategoriesPageState();
}
class _CategoriesPageState extends State<CategoriesPage>{
 Future<void> add() async {
  final name=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr('إضافة تصنيف')),
   content:field(name,'اسم التصنيف'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ')))]));
  if(ok!=true)return;
  try{await ShopDb.instance.addCategory(name.text);if(mounted)setState((){});}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر إضافة التصنيف: ')+e.toString())));}
 }
 Future<void> remove(Map<String,Object?> row) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr('حذف التصنيف؟')),
   content:Text('${tr('سيتم إلغاء ربط التصنيف بالصنف')} «${row['name']}» ${tr('إن وجد، دون حذف الصنف أو فواتيره.')}'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حذف التصنيف')))]));
  if(ok==true){await ShopDb.instance.deleteCategory((row['id'] as num).toInt());if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text(tr('تصنيفات الأصناف'))),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query('categories',orderBy:'name'),builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل التصنيفات: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return Center(child:Text(tr('لا توجد تصنيفات. أضف تصنيفاً جديداً.')));
   return ListView(children:s.data!.map((x)=>ListTile(
    leading:const Icon(Icons.folder_outlined),
    title:Text(x['name'] as String),
    trailing:IconButton(tooltip: tr('حذف التصنيف'),onPressed:()=>remove(x),icon:Icon(Icons.delete_outline)),
   )).toList());
  }),
  floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:Icon(Icons.add),label:Text(tr('إضافة تصنيف'))));
}


class ProductUnitsPage extends StatefulWidget {
 final Map<String,Object?> product;
 const ProductUnitsPage({super.key,required this.product});
 @override State<ProductUnitsPage> createState()=>_ProductUnitsPageState();
}
class _ProductUnitsPageState extends State<ProductUnitsPage>{
 final name=TextEditingController();
 late String defaultUnit;
 @override void initState(){super.initState();defaultUnit=(widget.product['purchase_unit']??'').toString();}
 final weight=TextEditingController();
 @override void dispose(){name.dispose();weight.dispose();super.dispose();}
 Future<List<Map<String,Object?>>> get units=>ShopDb.instance.getProductUnits((widget.product['id'] as num).toInt());
 Future<void> editUnit([Map<String,Object?>? unit]) async {
  name.text=(unit?['unit_name']??'').toString();
  weight.text=unit==null?'':(((unit['default_weight_grams'] as num).toDouble())/1000).toStringAsFixed(3);
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr(unit==null?'إضافة وحدة أو عبوة':'تعديل الوحدة')),
   content:Column(mainAxisSize:MainAxisSize.min,children:[
    field(name,'اسم الوحدة (كيس، جوان، حزمة، كرتون...)'),
    field(weight,'الوزن أو معامل التحويل بالكيلو',number:true),
    Align(alignment:Alignment.centerRight,child:Text(tr('أدخل ما تعادله الوحدة بالكيلوغرام. مثال: كيس 25 كجم = 25'))),
   ]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ')))]));
  if(ok!=true)return;
  final grams=((double.tryParse(weight.text.trim().replaceAll(',','.'))??0)*1000).round();
  try{
   if(unit==null){
    await ShopDb.instance.saveProductUnit(productId:(widget.product['id'] as num).toInt(),unitName:name.text,weightGrams:grams);
   }else{
    await ShopDb.instance.updateProductUnit(unitId:(unit['id'] as num).toInt(),productId:(widget.product['id'] as num).toInt(),unitName:name.text,weightGrams:grams);
    if(unit['unit_name']==defaultUnit)defaultUnit=name.text.trim();
   }
   if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تم حفظ الوحدة ومعامل تحويلها'))));}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر الحفظ: ')+e.toString())));}
 }
 Future<void> remove(Map<String,Object?> unit) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr('حذف الوحدة؟')),
   content:Text('${tr('سيتم حذف وحدة')} «${unit['unit_name']}» ${tr('من إعدادات الصنف.')}'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حذف')))]));
  if(ok!=true)return;
  try{await ShopDb.instance.deleteProductUnit((unit['id'] as num).toInt(),productId:(widget.product['id'] as num).toInt());if(mounted)setState((){});}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text('${tr('وحدات وعبوات')} • ${widget.product['name']}')),
  floatingActionButton:FloatingActionButton.extended(onPressed:()=>editUnit(),icon:Icon(Icons.add),label:Text(tr('إضافة وحدة'))),
  body:FutureBuilder<List<Map<String,Object?>>>(future:units,builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل الوحدات: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return Center(child:Text(tr('لا توجد وحدات معرفة لهذا الصنف')));
   return ListView(padding:const EdgeInsets.all(12),children:[
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Text('${tr('الصنف: ')}${widget.product['name']}\n${tr('كل وحدة تسجل بمعامل تحويل إلى الكيلوغرام، ويُستخدم وزن المورد إذا كان له وزن خاص لهذه العبوة.')}'))),
    ...s.data!.map((x){
     final isBase=x['unit_name']==defaultUnit;
     final kg=((x['default_weight_grams'] as num).toDouble()/1000);
     return Card(child:ListTile(
      leading:const Icon(Icons.inventory_2_outlined),
      title:Text(x['unit_name'].toString()),
      subtitle:Text('${kg.toStringAsFixed(3)} ${tr('كيلو')} • ${isBase?tr('الوحدة الافتراضية'):''}'),
      trailing:Wrap(spacing:0,children:[
       IconButton(tooltip: tr('تعديل'),onPressed:()=>editUnit(x),icon:Icon(Icons.edit_outlined)),
       if(!isBase)IconButton(tooltip: tr('حذف'),onPressed:()=>remove(x),icon:Icon(Icons.delete_outline)),
      ]),
     ));
    }),
   ]);
  }),
 );
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
  if(supplierId==null||grams<=0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('اختر المورد وأدخل وزناً صحيحاً'))));return;}
  try{
   await ShopDb.instance.saveSupplierProductUnit(
    supplierId:supplierId!,productId:(widget.product['id'] as num).toInt(),
    unitName:unitName,weightGrams:grams,
   );
   weight.clear();
   if(mounted)setState((){});
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تم حفظ وزن العبوة لهذا المورد'))));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر الحفظ: ')+e.toString())));}
 }
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text('${tr('أوزان الموردين')} • ${widget.product['name']}')),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    Align(alignment:Alignment.centerRight,child:Text(tr('إضافة وزن عبوة خاص بمورد'),style:TextStyle(fontWeight:FontWeight.bold))),
    const SizedBox(height:10),
    FutureBuilder<List<Map<String,Object?>>>(future:suppliers,builder:(c,s){
     if(!s.hasData)return const LinearProgressIndicator();
     return DropdownButtonFormField<int>(
      value:supplierId,decoration:InputDecoration(labelText: tr('المورد')),
      items:s.data!.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text(x['name'] as String))).toList(),
      onChanged:(v)=>setState(()=>supplierId=v),
     );
    }),
    const SizedBox(height:8),
    FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.getProductUnits((widget.product['id'] as num).toInt()),builder:(c,unitSnapshot){
     final configured=unitSnapshot.data??[];
     final names=configured.isEmpty?const ['جوان','كيس','سحارة','حزمة','صندوق','كرتون','كيلو']:configured.map((x)=>x['unit_name'].toString()).toList();
     final value=names.contains(unitName)?unitName:names.first;
     return DropdownButtonFormField<String>(
      value:value,decoration:InputDecoration(labelText: tr('نوع العبوة')),
      items:names.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
      onChanged:(v){if(v!=null)setState(()=>unitName=v);},
     );
    }),
    const SizedBox(height:8),
    field(weight,'وزن العبوة بالكيلو',number:true),
    const SizedBox(height:8),
    SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:save,icon:Icon(Icons.save),label:Text(tr('حفظ وزن المورد')))),
   ]))),
   Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text(tr('الأوزان المسجلة حسب المورد'),style:TextStyle(fontWeight:FontWeight.bold))),
   FutureBuilder<List<Map<String,Object?>>>(future:units,builder:(c,s){
    if(s.hasError)return Text(tr('تعذر تحميل الأوزان: ')+s.error.toString());
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return Text(tr('لا توجد أوزان خاصة مسجلة بعد.'));
    return Card(child:Column(children:s.data!.map((x)=>ListTile(
     leading:const Icon(Icons.scale_outlined),
     title:Text('${x['supplier_name']} • ${x['unit_name']}'),
     subtitle:Text('${tr('وزن العبوة: ')}${((x['weight_grams'] as num).toDouble()/1000).toStringAsFixed(3)} ${tr('كيلو')}'),
    )).toList()));
   }),
  ]),
 );
}

class PartiesPage extends StatefulWidget {final String type;const PartiesPage({super.key,required this.type});@override State<PartiesPage> createState()=>_PartiesPageState();}
class _PartiesPageState extends State<PartiesPage>{
 Future<num> partyBalance(int id) =>
  ShopDb.instance.getPartyBalance(type:widget.type,partyId:id);

 Future<void> edit(Map<String,Object?>? party)async{
  final n=TextEditingController(text:(party?['name']??'').toString()),phone=TextEditingController(text:(party?['phone']??'').toString());
  final customer=widget.type=='customer';
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr(party==null?(customer?'إضافة زبون':'إضافة مورد'):(customer?'تعديل بيانات الزبون':'تعديل بيانات المورد'))),
   content:Column(mainAxisSize:MainAxisSize.min,children:[field(n,'الاسم'),field(phone,'الهاتف')]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حفظ')))]));
  if(ok!=true)return;
  if(n.text.trim().isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('اكتب الاسم أولاً'))));return;}
  try{
   if(party==null)await ShopDb.instance.addParty(widget.type,n.text,phone.text);
   else await ShopDb.instance.updateParty(widget.type,party['id'] as int,n.text,phone.text);
   if(mounted)setState((){});
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر حفظ البيانات: ')+e.toString())));}
 }
 Future<void> archive(Map<String,Object?> party)async{
  final customer=widget.type=='customer';
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:Text(tr(customer?'حذف الزبون؟':'حذف المورد؟')),
   content:Text('${tr('سيختفي')} «${party['name']}» ${tr('من قوائم الاختيار، مع الاحتفاظ بفواتيره وكشف حسابه.')}'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('حذف')))]));
  if(ok==true){await ShopDb.instance.deactivateParty(widget.type,party['id'] as int);if(mounted)setState((){});}
 }
 @override Widget build(BuildContext c){
  final table=widget.type=='supplier'?'suppliers':'customers';
  final customer=widget.type=='customer';
  return Scaffold(appBar:AppBar(title:Text(tr(customer?'إدارة الزبائن':'إدارة الموردين'))),
   body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.db.query(table,where:'active=1',orderBy:'name'),builder:(c,s){
    if(s.hasError)return Center(child:Text(tr('تعذر تحميل القائمة: ')+s.error.toString()));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    if(s.data!.isEmpty)return Center(child:Text(tr(customer?'لا يوجد زبائن مسجلون':'لا يوجد موردون مسجلون')));
    return ListView(children:s.data!.map((x)=>ListTile(
     leading:const Icon(Icons.person_outline),
     title:Text(x['name'] as String),
     subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
       FutureBuilder<num>(future:partyBalance((x['id'] as num).toInt()),builder:(context,balanceSnap){
        if(!balanceSnap.hasData)return Text(tr('حالة الحساب: جارٍ الحساب…'),style:TextStyle(fontSize:12));
        final balance=balanceSnap.data!;
        final label=balance==0?tr('صفر • الحساب مسدد'):
          customer?(balance>0?tr('مدين • عليه للمحل'):tr('دائن • للمحل عليه')):
          (balance>0?tr('مستحق للمورد • على المحل'):tr('رصيد دائن • للمحل عند المورد'));
        final color=balance==0?Colors.grey:(balance>0?Colors.red:Colors.green);
        return Text('${tr('حالة الحساب: ')}$label  |  ${tr('الرصيد: ')}${money(balance.abs())}',
          style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:color));
       }),
       if((x['phone']??'').toString().isNotEmpty)Text(x['phone'].toString()),
      ]),
     trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?edit(x):archive(x),itemBuilder:(_)=>[
      PopupMenuItem(value:'edit',child:Text(tr('تعديل الاسم والهاتف'))),
      PopupMenuItem(value:'delete',child:Text(tr('حذف'))),
     ]),
     onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>PartyStatementPage(type:widget.type,partyId:x['id'] as int))).then((_) {if(mounted)setState((){});}),
    )).toList());
   }),
   floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(null),icon:const Icon(Icons.add),label:Text(tr(customer?'إضافة زبون':'إضافة مورد'))));
 }
}
Future<void> _showPaymentReceipt(BuildContext context,{required String type,required int paymentId,required String partyName,required int amount,required String note}) async {
 final customer=type=='customer';
 final md='''# NaeemSoft POS\n\n## ${tr(customer?'سند قبض من زبون':'سند سداد مورد')}\n\n- ${tr('رقم السند: ')}$paymentId\n- ${tr('التاريخ: ')}${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n- ${tr(customer?'الزبون: ':'المورد: ')}$partyName\n- ${tr('المبلغ: ')}${money(amount)}\n- ${tr('البيان: ')}${note.isEmpty?tr('سداد حساب'):note}\n\n${tr('تم تسجيل العملية بنجاح.')}''';
 final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title:'${tr(customer?'سند قبض':'سند سداد')} $paymentId',author:'NaeemSoft POS',markdown:md));
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
 String dateText(DateTime? d)=>d==null?tr('من البداية'):DateFormat('yyyy-MM-dd').format(d);
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
   title:Text(tr(widget.type=='customer'?'تسجيل دفعة من الزبون':'تسجيل دفعة للمورد')),
   content:Column(mainAxisSize:MainAxisSize.min,children:[field(amount,'المبلغ',number:true),field(note,'ملاحظة')]),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(tr('تسجيل')))],
  ));
  final value=int.tryParse(amount.text.trim())??0;
  if(ok!=true||value<=0)return;
  setState(()=>saving=true);
  try{
   final savedPaymentId=await ShopDb.instance.recordPartyPayment(
    type:widget.type,partyId:widget.partyId,amount:value,note:note.text.trim(),
   );
   if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تم تسجيل السداد وتوزيعه على أقدم الفواتير المستحقة')))); await _showPaymentReceipt(context,type:widget.type,paymentId:savedPaymentId,partyName:(await ShopDb.instance.db.query(widget.type=='customer'?'customers':'suppliers',where:'id=?',whereArgs:[widget.partyId],limit:1)).first['name'].toString(),amount:value,note:note.text.trim());}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تعذر تسجيل الدفعة: ')+e.toString())));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 Future<void> export(Map<String,Object?> data) async {
  final party=data['party'] as Map<String,Object?>,tx=data['transactions'] as List<Map<String,Object?>>;
  final customer=widget.type=='customer';
  final out=StringBuffer()..writeln('# NaeemSoft POS')..writeln('## '+tr(customer?'كشف حساب زبون':'كشف حساب مورد'))..writeln('**'+tr('الاسم: ')+'** '+party['name'].toString())..writeln('**'+tr('الفترة: ')+'** '+dateText(fromDate)+tr(' إلى ')+dateText(toDate))..writeln('**'+tr('الرصيد المرحل: ')+'** '+money(data['opening'] as num))..writeln('')..writeln('| '+tr('التاريخ')+' | '+tr('البيان')+' | '+tr('مدين')+' | '+tr('دائن')+' | '+tr('الرصيد')+' |')..writeln('|---|---|---:|---:|---:|');
  for(final x in tx){
   final amount=x['amount'] as num,dir=x['direction'] as int;
   final debit=(customer?dir>0:dir<0)?amount:0,credit=(customer?dir<0:dir>0)?amount:0;
   out.writeln('| '+x['date'].toString()+' | '+trStatementLabel(x['label'].toString())+' | '+money(debit)+' | '+money(credit)+' | '+money(x['balance'] as num)+' |');
  }
  out..writeln('')..writeln('**'+tr('الرصيد الافتتاحي للفترة: ')+'** '+money(data['opening'] as num))..writeln('**'+tr('الرصيد الختامي: ')+'** '+money(data['balance'] as num));
  final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title: tr('كشف حساب ')+party['name'].toString(),author:'NaeemSoft POS',markdown:out.toString()));
  if(mounted)await Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(tr(widget.type=='customer'?'كشف حساب زبون':'كشف حساب مورد'))),
  floatingActionButton:FloatingActionButton.extended(onPressed:saving?null:addPayment,icon:Icon(Icons.payments),label:Text(tr('تسجيل دفعة'))),
  body:FutureBuilder<Map<String,Object?>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(16),child:Text(tr('تعذر تحميل الكشف: ')+s.error.toString())));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final data=s.data!,party=data['party'] as Map<String,Object?>;
   final tx=data['transactions'] as List<Map<String,Object?>>,balance=data['balance'] as num,opening=data['opening'] as num;
   final customer=widget.type=='customer';
   return ListView(padding:const EdgeInsets.all(12),children:[
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(party['name'] as String,style:Theme.of(c).textTheme.titleLarge),Text((party['phone']??'').toString()),const SizedBox(height:8),
     Text(tr('الرصيد الافتتاحي للفترة: ')+money(opening)),
     Text(tr('الرصيد ')+(balance<0?tr('الدائن'):tr('المستحق'))+': '+money(balance.abs()),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
    ]))),
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
     Align(alignment:Alignment.centerRight,child:Text(tr('تصفية الكشف حسب الفترة'),style:TextStyle(fontWeight:FontWeight.bold))),
     Row(children:[
      Expanded(child:OutlinedButton.icon(onPressed:()=>chooseDate(true),icon:const Icon(Icons.calendar_month),label:Text(tr('من: ')+dateText(fromDate)))),
      const SizedBox(width:8),
      Expanded(child:OutlinedButton.icon(onPressed:()=>chooseDate(false),icon:const Icon(Icons.calendar_month),label:Text(tr('إلى: ')+dateText(toDate)))),
     ]),
     TextButton.icon(onPressed:()=>setState((){fromDate=null;toDate=null;}),icon:Icon(Icons.clear),label:Text(tr('عرض كل الفترة'))),
    ]))),
    SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>export(data),icon:Icon(Icons.picture_as_pdf),label:Text(tr('حفظ / مشاركة كشف الحساب PDF')))),
    if(tx.isEmpty)Padding(padding:EdgeInsets.all(24),child:Text(tr('لا توجد حركات في الفترة المحددة'),textAlign:TextAlign.center)),
    if(tx.isNotEmpty)SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
     columns:[DataColumn(label:Text(tr('التاريخ'))),DataColumn(label:Text(tr('البيان'))),DataColumn(label:Text(tr('مدين'))),DataColumn(label:Text(tr('دائن'))),DataColumn(label:Text(tr('الرصيد')))],
     rows:[
      DataRow(cells:[DataCell(Text('—')),DataCell(Text(tr('رصيد مرحل'))),DataCell(Text(customer?money(opening.abs()):'—')),DataCell(Text(customer?'—':money(opening.abs()))),DataCell(Text(money(opening)))]),
      ...tx.map((x){
       final amount=x['amount'] as num,dir=x['direction'] as int;
       final debit=(customer?dir>0:dir<0)?amount:0,credit=(customer?dir<0:dir>0)?amount:0;
       final dt=DateTime.tryParse(x['date'].toString())?.toLocal();
       return DataRow(cells:[
        DataCell(Text(dt==null?x['date'].toString():DateFormat('yyyy-MM-dd').format(dt))),DataCell(Text(trStatementLabel(x['label'] as String))),
        DataCell(Text(debit==0?'—':money(debit))),DataCell(Text(credit==0?'—':money(credit))),
        DataCell(Text(money(x['balance'] as num),style:const TextStyle(fontWeight:FontWeight.bold))),
       ]);
      }),
     ],
    )),
    Card(child:ListTile(
     title:Text(tr(customer?'حالة حساب الزبون':'حالة حساب المورد')),
     subtitle:Text(tr(balance>0?'مدين • عليه للمحل':balance<0?'دائن • للمحل عليه':'صفر • الحساب مسدد')),
     trailing:Text(money(balance.abs()),style:TextStyle(fontWeight:FontWeight.bold,fontSize:18,color:balance>0?Colors.red:balance<0?Colors.green:null)),
    )),
   ]);
  }),
 );
}

class InvoicesPage extends StatelessWidget {
 const InvoicesPage({super.key});
 @override Widget build(BuildContext c)=>Scaffold(
  appBar:AppBar(title:Text(tr('الفواتير'))),
  body:FutureBuilder<List<List<Map<String,Object?>>>>(
   future:Future.wait([rows('sales'),rows('purchases')]),
   builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final all=<Map<String,Object?>>[
     ...s.data![0].map((x)=>{...x,'kind':'بيع'}),
     ...s.data![1].map((x)=>{...x,'kind':'توريد'})
    ]..sort((a,b)=>(b['id'] as int).compareTo(a['id'] as int));
    if(all.isEmpty)return Center(child:Text(tr('لا توجد فواتير محفوظة بعد')));
    return ListView.separated(
     itemCount:all.length,separatorBuilder:(_,__)=>const Divider(height:1),
     itemBuilder:(c,i){
      final x=all[i],sale=x['kind']=='بيع';
      return ListTile(
       leading:CircleAvatar(child:Icon(sale?Icons.point_of_sale:Icons.local_shipping_outlined)),
       title:Text(tr(sale?'فاتورة بيع رقم ':'فاتورة مورد رقم ')+x['id'].toString()),
       subtitle:Text(x['date'].toString()+' • '+money(x['paid'] as num)+' '+tr('مدفوع')+' • '+money((x['total'] as num)-(x['paid'] as num))+' '+tr('متبقٍ')),
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
  }catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(tr('تعذر تجهيز صورة الفاتورة: ')+e.toString())));}
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(tr('مراجعة فاتورة البيع قبل الترحيل'))),body:ListView(padding:EdgeInsets.all(12),children:[
  ReceiptShareCard(items:items,total:total,paid:paid,party:party),const SizedBox(height:12),
  Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>Share.share(receiptText,subject:'فاتورة بيع'),icon:Icon(Icons.share),label:Text(tr('مشاركة التفاصيل')))),SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>shareImage(c),icon:Icon(Icons.image),label:Text(tr('مشاركة صورة'))))]),
  SizedBox(height:8),FilledButton.icon(onPressed:()=>Navigator.pop(c,true),icon:Icon(Icons.check_circle),label:Text(tr('تأكيد وترحيل الفاتورة'))),
  TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(tr('رجوع للتعديل')))
 ]));
}
class ReceiptShareCard extends StatelessWidget {
 final List<Map<String,dynamic>> items;final int total,paid;final String party;
 const ReceiptShareCard({super.key,required this.items,required this.total,required this.paid,required this.party});
 @override Widget build(BuildContext c)=>Container(width:360,padding:const EdgeInsets.all(18),color:Colors.white,child:DefaultTextStyle(style:const TextStyle(color:Colors.black,fontSize:13),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
  const Text('NaeemSoft POS',textAlign:TextAlign.center,style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Text(tr('فاتورة بيع'),textAlign:TextAlign.center,style:TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const Divider(thickness:2),
  Text(tr('الزبون: ')+party),Text(tr('التاريخ: ')+DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),Divider(),Text(tr('تفاصيل الأصناف'),style:TextStyle(fontWeight:FontWeight.bold)),
  Row(children:[Expanded(child:Text(tr('اسم الصنف'),style:TextStyle(fontWeight:FontWeight.bold))),Text(tr('الكمية'),style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(width:12),Text(tr('إجمالي الصنف'),style:TextStyle(fontWeight:FontWeight.bold))]),
  const Divider(),
  ...items.map((x){final g=x['grams'] as int,p=x['price_per_kg'] as int;return Padding(padding:EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(x['name'].toString(),style:TextStyle(fontWeight:FontWeight.bold))),Text('${(g/1000).toStringAsFixed(3)} ${tr('كيلو')}'),SizedBox(width:12),Text(money((g*p/1000).round()),style:TextStyle(fontWeight:FontWeight.bold))]));}),
  _receiptRow(tr('الإجمالي'),money(total),strong:true),_receiptRow(tr('المدفوع'),money(paid)),_receiptRow(tr('المتبقي'),money(total-paid),strong:true),const SizedBox(height:8),Text(tr('شكراً لتعاملكم معنا'),textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.bold))
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
  PdfSection.h2(tr(sale?'فاتورة بيع':'فاتورة توريد')),
  PdfSection.paragraph(tr('رقم الفاتورة: ') + invoiceId.toString()),
  PdfSection.paragraph(tr('التاريخ: ') + invoiceDate),
  PdfSection.paragraph(tr(sale?'الزبون: ':'المورد: ') + party),
  PdfSection.divider(),
  PdfSection.h2(tr('تفاصيل الأصناف')),
 ];
 for(var i=0;i<lines.length;i++){
  final x=lines[i];
  final name=(x['product_name']??'صنف محذوف').toString();
  final quantity=sale
    ? '${tr('الكمية: ')}${((x['quantity_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كيلو')}'
    : '${tr('الكمية: ')}${x['packages']} ${tr('عبوة، وزن العبوة')} ${x['weight_each']} ${tr('كيلو')}';
  sections.add(PdfSection.paragraph(
    '$name\n$quantity\n${tr('إجمالي الصنف: ')}${money(x['line_total'] as num)}'
  ));
  sections.add(PdfSection.divider());
 }
 sections.addAll([
  PdfSection.h2(tr('ملخص الحساب')),
  PdfSection.paragraph(tr('الإجمالي: ') + money(total)),
  PdfSection.paragraph(tr('المدفوع: ') + money(paid)),
  PdfSection.paragraph(tr('المتبقي: ') + money(total-paid)),
  PdfSection.paragraph(tr('شكراً لتعاملكم معنا')),
 ]);
 return PdfBuilder.generate(PdfDocumentData(
  title:'${tr(sale?'فاتورة بيع':'فاتورة توريد')} $invoiceId',
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
  appBar:AppBar(title:Text(tr('معاينة الفاتورة PDF'))),
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
  appBar:AppBar(title:Text(tr(type=='sale'?'فاتورة بيع #':'فاتورة مورد #')+invoiceId.toString())),
  body:FutureBuilder<Map<String,Object?>>(future:load(),builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر فتح الفاتورة: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final h=s.data!['header'] as Map<String,Object?>;
   final lines=s.data!['lines'] as List<Map<String,Object?>>;
   final sale=type=='sale',total=h['total'] as num,paid=h['paid'] as num,returnCredit=s.data!['return_credit'] as num,remaining=total-paid-returnCredit;
   return ListView(padding:const EdgeInsets.all(12),children:[
     SizedBox(width:double.infinity,child:FilledButton.icon(
      icon:const Icon(Icons.picture_as_pdf),
      label:Text(tr('طباعة / مشاركة / حفظ PDF')),
      onPressed:() async {
       try{
        final file=await _buildInvoicePdf(type:type,invoiceId:invoiceId,header:h,lines:lines,party:s.data!['party'].toString());
        if(c.mounted)await Navigator.push(c,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
       }catch(e){
        if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(tr('تعذر إنشاء PDF: ')+e.toString())));
       }
      },
     )),
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(tr(sale?'فاتورة مبيعات':'فاتورة توريد'),style:Theme.of(c).textTheme.titleLarge),
     Text(tr('رقم الفاتورة: ')+invoiceId.toString()),
     Text(tr('التاريخ: ')+h['date'].toString()),
     Text(tr(sale?'الزبون: ':'المورد: ')+s.data!['party'].toString()),
    ]))),
    Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text(tr('تفاصيل الأصناف'),style:TextStyle(fontWeight:FontWeight.bold))),
    if(lines.isNotEmpty)SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
     columns: [
      DataColumn(label:Text(tr('اسم الصنف'))),
      DataColumn(label:Text(tr('الكمية'))),
      DataColumn(label:Text(tr('إجمالي الصنف'))),
     ],
     rows:lines.map((x){
      final quantity=sale
       ? '${((x['quantity_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كجم')}'
       : '${x['packages']} ${x['unit']} • ${x['weight_each']} ${tr('كجم/وحدة')}';
      return DataRow(cells:[
       DataCell(Text((x['product_name']??tr('صنف محذوف')).toString())),
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
    Text(tr(sale?'تم خصم الكمية من مخزون الصنف.':'تمت إضافة الكمية إلى مخزون صنف المبيعات المرتبط.')),
   ]);
  }));
}

Widget _invoiceAmount(String label,num amount)=>Padding(
 padding:const EdgeInsets.symmetric(vertical:4),
 child:Row(children:[Expanded(child:Text(tr(label))),Text(money(amount),style:const TextStyle(fontWeight:FontWeight.bold))]));



Future<void> _showReturnReceipt(BuildContext context,{required String type,required int returnId,required String partyName,required int amount}) async {
 final customer=type=='customer';
 final md='''# NaeemSoft POS\n\n## ${tr(customer?'سند مرتجع زبون':'سند إرجاع إلى المورد')}\n\n- ${tr('رقم السند: ')}$returnId\n- ${tr('التاريخ: ')}${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n- ${tr(customer?'الزبون: ':'المورد: ')}$partyName\n- ${tr('قيمة المرتجع: ')}${money(amount)}\n\n${tr('تم تسجيل المرتجع وتحديث الحساب والمخزون.')}''';
 final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(title:'${tr(customer?'مرتجع زبون':'مرتجع مورد')} $returnId',author:'NaeemSoft POS',markdown:md));
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
  if(invoiceId==null){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('اختر الفاتورة الأصلية'))));return;}
  final selected=<Map<String,dynamic>>[];
  for(final x in invoiceItems){
   final id=x['source_item_id'] as int;
   final kilos=double.tryParse((quantities[id]?.text??'0').trim().replaceAll(',', '.'))??0;
   final grams=(kilos*1000).round();
   if(grams>0)selected.add({'source_item_id':id,'grams':grams,'unit_price':(x['unit_price'] as num).toInt()});
  }
  if(selected.isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('أدخل كمية مرتجعة لصنف واحد على الأقل'))));return;}
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
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr('تم حفظ المرتجع رقم ')+id.toString())));
   await _showReturnReceipt(context,type:type,returnId:id,partyName:partyName,amount:returnTotal);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(tr('مرتجعات الزبائن والموردين'))),
  body:ListView(padding:const EdgeInsets.all(12),children:[
   SegmentedButton<String>(segments:[
    ButtonSegment(value:'customer',label:Text(tr('مرتجع زبون')),icon:Icon(Icons.assignment_return)),
    ButtonSegment(value:'supplier',label:Text(tr('مرتجع للمورد')),icon:Icon(Icons.local_shipping_outlined)),
   ],selected:{type},onSelectionChanged:(v)=>changeType(v.first)),
   const SizedBox(height:12),
   FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.returnableInvoices(type),builder:(c,s){
    if(!s.hasData)return const LinearProgressIndicator();
    return DropdownButtonFormField<int>(
     value:invoiceId,decoration:InputDecoration(labelText: tr('اختر الفاتورة الأصلية'),border:OutlineInputBorder()),
     items:s.data!.map((x)=>DropdownMenuItem<int>(value:x['id'] as int,child:Text('#'+x['id'].toString()+' • '+(x['party_name']??tr('بدون اسم')).toString()+' • '+money(x['total'] as num)))).toList(),
     onChanged:(v){if(v!=null){setState(()=>invoiceId=v);loadItems(v);}},
    );
   }),
   const SizedBox(height:12),
   if(invoiceId!=null && invoiceItems.isEmpty) Text(tr('لا توجد كميات متبقية للإرجاع في هذه الفاتورة')),
   ...invoiceItems.map((x){
    final id=x['source_item_id'] as int;
    return Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(x['product_name'] as String,style:const TextStyle(fontWeight:FontWeight.bold)),
     Text(tr('المتاح للإرجاع: ')+kg(x['remaining_grams'] as num)+' • '+tr('سعر الوحدة: ')+money(x['unit_price'] as num)),
     TextField(controller:quantities[id],keyboardType:TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText: tr('الكمية المرتجعة بالكيلو'),hintText: tr('مثال: 1 أو 0.5'),border:OutlineInputBorder(),isDense:true)),
    ])));
   }),
   if(type=='customer')field(cash,'المبلغ الذي أُعيد نقداً للزبون',number:true),
   const SizedBox(height:8),
   FilledButton.icon(onPressed:saving?null:submit,icon:const Icon(Icons.save),label:Text(saving?tr('جارٍ الحفظ...'):tr('حفظ المرتجع وتحديث الحساب'))),
   Padding(padding:EdgeInsets.only(top:12),child:Text(tr('يجب اختيار الفاتورة الأصلية. لا يسمح النظام بإرجاع كمية أكبر من المتبقي من الصنف. يُخصم صافي المرتجع من حساب الزبون أو المورد المرتبط بالفاتورة.'),style:TextStyle(height:1.5))),
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
  appBar:AppBar(title:Text(tr('ملخص الحسابات'))),
  body:FutureBuilder<List<num>>(future:load(),builder:(context,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل الحسابات: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   final v=s.data!;
   Widget item(String title,num amount,IconData icon)=>Card(child:ListTile(leading:Icon(icon),title:Text(tr(title)),trailing:Text(money(amount),style:const TextStyle(fontWeight:FontWeight.bold))));
   return ListView(padding:const EdgeInsets.all(12),children:[
    item('مستحقات الزبائن بعد المرتجعات',v[0],Icons.account_balance_wallet_outlined),
    item('مستحقات الموردين بعد المرتجعات',v[1],Icons.local_shipping_outlined),
    item('إجمالي فواتير البيع',v[2],Icons.point_of_sale),
    item('إجمالي فواتير التوريد',v[3],Icons.shopping_basket_outlined),
    Text(tr('هذا ملخص للأرصدة والفواتير، وليس تقرير صافي ربح. حساب الربح يتطلب تكلفة فعلية ومصروفات مسجلة.'),style:TextStyle(height:1.5)),
   ]);
  }),
);
}

class ReportsPage extends StatefulWidget {
 const ReportsPage({super.key});
 @override State<ReportsPage> createState()=>_ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
 late DateTimeRange range;
 String reportType='sales';
 @override void initState(){
  super.initState();
  final now=DateTime.now();
  final today=DateTime(now.year,now.month,now.day);
  range=DateTimeRange(start:today,end:today);
 }
 String day(DateTime value)=>DateFormat('yyyy-MM-dd').format(value);
 Future<void> chooseRange() async {
  final picked=await showDateRangePicker(
   context:context,firstDate:DateTime(2000),lastDate:DateTime(2100),
   initialDateRange:range,
  );
  if(picked!=null&&mounted)setState(()=>range=picked);
 }
 Future<Map<String,Object?>> load() async {
  final db=ShopDb.instance.db;
  if(reportType=='inventory'){
   final products=await db.query('products',where:"product_type='sale' AND active=1",orderBy:'name');
   final totalGrams=products.fold<int>(0,(sum,x)=>sum+(x['stock_grams'] as num).toInt());
   final totalValue=products.fold<int>(0,(sum,x)=>sum+((x['inventory_value_djf'] as num?)?.toInt()??0));
   return {'products':products,'total_grams':totalGrams,'total_value':totalValue};
  }
  final from=day(range.start),to=day(range.end);
  final sales=await db.rawQuery(
   "SELECT s.id,s.date,s.total,s.paid,COALESCE(c.name,?) customer_name FROM sales s LEFT JOIN customers c ON c.id=s.customer_id WHERE s.status='posted' AND substr(s.date,1,10) BETWEEN ? AND ? ORDER BY s.date,s.id",
   [tr('نقدي / غير مسجل'),from,to]);
  final purchases=await db.rawQuery(
   "SELECT COALESCE(SUM(total),0) total,COALESCE(SUM(paid),0) paid FROM purchases WHERE status='posted' AND substr(date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final customerReturns=await db.rawQuery(
   "SELECT COALESCE(SUM(total),0) total,COALESCE(SUM(cash_paid),0) cash FROM returns WHERE return_type='customer' AND substr(date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final supplierReturns=await db.rawQuery(
   "SELECT COALESCE(SUM(total),0) total FROM returns WHERE return_type='supplier' AND substr(date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final margin=await db.rawQuery(
   "SELECT COALESCE(SUM(si.line_total-si.cost_total_djf),0) value FROM sale_items si JOIN sales s ON s.id=si.sale_id WHERE s.status='posted' AND substr(s.date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final returnMargin=await db.rawQuery(
   "SELECT COALESCE(SUM(ri.line_total-ROUND(ri.quantity_grams*ri.cost_per_kg/1000.0)),0) value FROM return_items ri JOIN returns r ON r.id=ri.return_id WHERE r.return_type='customer' AND substr(r.date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final expenses=await db.rawQuery(
   "SELECT COALESCE(SUM(amount),0) value FROM expenses WHERE substr(expense_date,1,10) BETWEEN ? AND ?",
   [from,to]);
  final salesTotal=sales.fold<num>(0,(sum,x)=>sum+(x['total'] as num));
  final salesPaid=sales.fold<num>(0,(sum,x)=>sum+(x['paid'] as num));
  final returnTotal=(customerReturns.first['total'] as num);
  final supplierReturnTotal=(supplierReturns.first['total'] as num);
  final grossProfit=(margin.first['value'] as num)-(returnMargin.first['value'] as num);
  final expenseTotal=(expenses.first['value'] as num);
  return {
   'sales':sales,'sales_total':salesTotal,'sales_paid':salesPaid-(customerReturns.first['cash'] as num),
   'sales_due':salesTotal-salesPaid-(returnTotal-(customerReturns.first['cash'] as num)),'customer_returns':returnTotal,
   'net_sales':salesTotal-returnTotal,
   'purchase_total':(purchases.first['total'] as num),
   'purchase_paid':(purchases.first['paid'] as num),
   'supplier_returns':supplierReturnTotal,
   'net_purchases':(purchases.first['total'] as num)-supplierReturnTotal,
   'purchase_due':(purchases.first['total'] as num)-(purchases.first['paid'] as num)-supplierReturnTotal,
   'gross_profit':grossProfit,'expenses':expenseTotal,
   'net_profit':grossProfit-expenseTotal,
   'customer_refunds':(customerReturns.first['cash'] as num),
  };
 }
 Future<void> exportPdf(Map<String,Object?> data) async {
  final inventory=reportType=='inventory';
  final sales=reportType=='sales';
  final title=tr(inventory?'تقرير المخزون':sales?'تقرير المبيعات اليومية':'تقرير الأرباح والخسائر');
  final out=StringBuffer()
   ..writeln('# NaeemSoft POS')
   ..writeln('## $title')
   ..writeln('**${tr('الفترة: ')}** ${day(range.start)} — ${day(range.end)}')
   ..writeln('');
  if(inventory){
   out.writeln('| ${tr('اسم الصنف')} | ${tr('الكمية')} | ${tr('قيمة المخزون')} |');
   out.writeln('|---|---:|---:|');
   for(final p in data['products'] as List<Map<String,Object?>>){
    out.writeln('| ${p['name']} | ${((p['stock_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كجم')} | ${money((p['inventory_value_djf'] as num?)??0)} |');
   }
   out.writeln('\n**${tr('إجمالي الكمية: ')}** ${((data['total_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كجم')}');
   out.writeln('\n**${tr('قيمة المخزون: ')}** ${money(data['total_value'] as num)}');
  }else{
   out.writeln('| ${tr('المؤشر')} | ${tr('القيمة')} |');
   out.writeln('|---|---:|');
   final keys=sales
    ? <String>['sales_total','customer_returns','net_sales','sales_paid','sales_due','purchase_total','supplier_returns','purchase_due']
    : <String>['sales_total','customer_returns','gross_profit','expenses','net_profit'];
   final labels={
    'sales_total':'إجمالي المبيعات','customer_returns':'مرتجعات الزبائن',
    'net_sales':'صافي المبيعات','sales_paid':'المقبوض الصافي من المبيعات',
    'sales_due':'المتبقي على الزبائن بعد المرتجعات','purchase_total':'إجمالي التوريد',
    'supplier_returns':'مرتجعات الموردين','purchase_due':'المتبقي للموردين بعد المرتجعات','gross_profit':'مجمل الربح بعد المرتجعات',
    'expenses':'المصروفات','net_profit':'صافي الربح التقديري',
   };
   for(final key in keys)out.writeln('| ${tr(labels[key]!)} | ${money(data[key] as num)} |');
   if(sales){
    out.writeln('\n### ${tr('تفاصيل فواتير البيع')}');
    out.writeln('| # | ${tr('التاريخ')} | ${tr('الزبون')} | ${tr('الإجمالي')} | ${tr('المدفوع')} |');
    out.writeln('|---:|---|---|---:|---:|');
    for(final x in data['sales'] as List<Map<String,Object?>>){
     out.writeln('| ${x['id']} | ${x['date']} | ${x['customer_name']} | ${money(x['total'] as num)} | ${money(x['paid'] as num)} |');
    }
   }
  }
  await FontResolver.preload(['تقرير المخزون','تقرير المبيعات اليومية','تقرير الأرباح والخسائر','إجمالي المبيعات','صافي الربح التقديري']);
  final file=await PdfBuilder.generate(PdfDocumentData.fromMarkdown(
   title:title,author:'NaeemSoft POS',markdown:out.toString(),
  ));
  if(mounted)await Navigator.push(context,MaterialPageRoute(builder:(_)=>InvoicePdfPreviewPage(file:file)));
 }
 Widget metric(String label,num value)=>Card(child:ListTile(
  title:Text(tr(label)),trailing:Text(money(value),style:const TextStyle(fontWeight:FontWeight.bold)),
 ));
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(tr('التقارير'))),
  body:Column(children:[
   Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    DropdownButtonFormField<String>(
     value:reportType,decoration:InputDecoration(labelText:tr('نوع التقرير')),
     items:[
      DropdownMenuItem(value:'sales',child:Text(tr('تقرير المبيعات اليومية'))),
      DropdownMenuItem(value:'inventory',child:Text(tr('تقرير المخزون'))),
      DropdownMenuItem(value:'profit',child:Text(tr('تقرير الأرباح والخسائر'))),
     ],
     onChanged:(v){if(v!=null)setState(()=>reportType=v);},
    ),
    if(reportType!='inventory')Padding(
     padding:const EdgeInsets.only(top:8),
     child:OutlinedButton.icon(
      onPressed:chooseRange,icon:const Icon(Icons.date_range),
      label:Text('${day(range.start)} — ${day(range.end)}'),
     ),
    ),
   ])),
   Expanded(child:FutureBuilder<Map<String,Object?>>(
    future:load(),builder:(context,s){
     if(s.hasError)return Center(child:Text(tr('تعذر تحميل التقرير: ')+s.error.toString()));
     if(!s.hasData)return const Center(child:CircularProgressIndicator());
     final d=s.data!;
     final inventory=reportType=='inventory',sales=reportType=='sales';
     return ListView(padding:const EdgeInsets.fromLTRB(12,0,12,12),children:[
      if(inventory)...[
       metric('عدد الأصناف', (d['products'] as List).length),
       metric('إجمالي الكمية',((d['total_grams'] as num)/1000)),
       metric('قيمة المخزون',d['total_value'] as num),
       ...(d['products'] as List<Map<String,Object?>>).map((p)=>ListTile(
        title:Text(p['name'] as String),
        subtitle:Text('${((p['stock_grams'] as num)/1000).toStringAsFixed(3)} ${tr('كجم')}'),
        trailing:Text(money((p['inventory_value_djf'] as num?)??0)),
       )),
      ]else if(sales)...[
       metric('إجمالي المبيعات',d['sales_total'] as num),
       metric('مرتجعات الزبائن',d['customer_returns'] as num),
       metric('صافي المبيعات',d['net_sales'] as num),
       metric('المقبوض الصافي من المبيعات',d['sales_paid'] as num),
       metric('المتبقي على الزبائن بعد المرتجعات',d['sales_due'] as num),
       const Divider(),
       ...((d['sales'] as List<Map<String,Object?>>).map((x)=>ListTile(
        title:Text('${tr('فاتورة بيع رقم ')}${x['id']}'),
        subtitle:Text('${x['date']} • ${x['customer_name']}'),
        trailing:Text(money(x['total'] as num)),
       ))),
      ]else...[
       metric('إجمالي المبيعات',d['sales_total'] as num),
       metric('مرتجعات الزبائن',d['customer_returns'] as num),
       metric('مجمل الربح بعد المرتجعات',d['gross_profit'] as num),
       metric('المصروفات',d['expenses'] as num),
       metric('صافي الربح التقديري',d['net_profit'] as num),
       Text(tr('صافي الربح التقديري يساوي مجمل الربح بعد المرتجعات ناقص المصروفات المسجلة للفترة.'),style:const TextStyle(height:1.5)),
      ],
      const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>exportPdf(d),icon:const Icon(Icons.picture_as_pdf),label:Text(tr('معاينة / طباعة / مشاركة PDF'))),
     ]);
    },
   )),
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
  appBar:AppBar(title:Text(tr(widget.type=='sale'?'مسودات البيع':widget.type=='purchase'?'مسودات التوريد':'مسودات الفواتير'))),
  body:FutureBuilder<List<Map<String,Object?>>>(future:ShopDb.instance.getDrafts(type:widget.type),builder:(c,s){
   if(s.hasError)return Center(child:Text(tr('تعذر تحميل المسودات: ')+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   if(s.data!.isEmpty)return Center(child:Text(tr('لا توجد مسودات محفوظة')));
   return ListView(children:s.data!.map<Widget>((d){
    final isSale=d['invoice_type']=='sale';
    final dt=DateTime.tryParse(d['updated_at'] as String);
    return Card(child:ListTile(
     leading:Icon(isSale?Icons.point_of_sale:Icons.local_shipping),
     title:Text(tr(isSale?'مسودة بيع #':'مسودة توريد #')+d['id'].toString()),
     subtitle:Text((dt?.toLocal().toString().substring(0,16)??'')+' • '+money(d['total'] as num)),
     trailing:PopupMenuButton<String>(onSelected:(v)async{
      if(v=='delete'){await remove(d['id'] as int);}
      else{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);}
     },itemBuilder:(_)=>[
      PopupMenuItem(value:'open',child:Text(tr('استعادة المسودة'))),
      PopupMenuItem(value:'delete',child:Text(tr('حذف المسودة'))),
     ]),
     onTap:()async{final full=await ShopDb.instance.getDraft(d['id'] as int);if(context.mounted)Navigator.pop(context,full);},
    ));
   }).toList());
  }),
 );
}
