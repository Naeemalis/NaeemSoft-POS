import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naeemsoft_pos/main.dart' as app;

void main() {
  test('main POS labels and quantity formatting support all three languages', () {
    final previousLocale = app.appLocale.value;
    addTearDown(() => app.appLocale.value = previousLocale);

    app.appLocale.value = const Locale('ar');
    expect(app.tr('الرئيسية'), 'الرئيسية');
    expect(app.tr('المبيعات'), 'المبيعات');
    expect(app.kg(1000), '1.000 كجم');

    app.appLocale.value = const Locale('en');
    expect(app.tr('الرئيسية'), 'Home');
    expect(app.tr('المبيعات'), 'Sales');
    expect(app.tr('التوريد'), 'Purchases');
    expect(app.tr('مستحق للمورد • على المحل'), 'Due to supplier • payable by shop');
    expect(app.kg(1000), '1.000 kg');

    app.appLocale.value = const Locale('fr');
    expect(app.tr('الرئيسية'), 'Accueil');
    expect(app.tr('المبيعات'), 'Ventes');
    expect(app.tr('التوريد'), 'Achats');
    expect(app.tr('مستحق للمورد • على المحل'), 'Dû au fournisseur • payable par le magasin');
    expect(app.kg(1000), '1.000 kg');
  });
}
