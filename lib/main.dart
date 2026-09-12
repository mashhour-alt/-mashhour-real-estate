import 'package:flutter/material.dart';
import 'app_store.dart';
import 'models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarpetShopApp());
}

class CarpetShopApp extends StatelessWidget {
  const CarpetShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة الموكيت',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174f4b)),
        scaffoldBackgroundColor: const Color(0xfff5f6f2),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.symmetric(vertical: 5)),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: FutureBuilder<void>(
        future: appStore.load(),
        builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
            ? const RoleEntryScreen()
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class RoleEntryScreen extends StatelessWidget {
  const RoleEntryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        const CircleAvatar(radius: 42, child: Icon(Icons.texture_rounded, size: 44)),
        const SizedBox(height: 18),
        Text('إدارة الموكيت', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const Text('المبيعات والمخزون والحسابات في مكان واحد', textAlign: TextAlign.center),
        const SizedBox(height: 34),
        const Text('الدخول كـ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.45, physics: const NeverScrollableScrollPhysics(),
          children: UserRole.values.map((role) => Card(child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MainShell(role: role))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_roleIcon(role), size: 32), const SizedBox(height: 8), Text(role.label, style: const TextStyle(fontWeight: FontWeight.bold))]),
          ))).toList(),
        ),
        const Spacer(flex: 2),
        const Text('نسخة محلية تجريبية • البيانات محفوظة على الجهاز', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    )));
  }
}

IconData _roleIcon(UserRole role) => switch (role) {
  UserRole.owner => Icons.storefront,
  UserRole.accountant => Icons.calculate,
  UserRole.seller => Icons.point_of_sale,
  UserRole.driver => Icons.local_shipping,
};

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.role});
  final UserRole role;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  void initState() { super.initState(); appStore.addListener(_refresh); }
  @override
  void dispose() { appStore.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.driver) return const DriverHome();
    final pages = <Widget>[Dashboard(role: widget.role), SaleScreen(role: widget.role), const InventoryScreen(), AccountsScreen(role: widget.role), MoreScreen(role: widget.role)];
    return Scaffold(
      appBar: AppBar(title: Text(widget.role.label), actions: [IconButton(tooltip: 'تغيير الحساب', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.switch_account))]),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'بيع'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'المخزن'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'الحسابات'),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: 'المزيد'),
      ]),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    final monthSales = appStore.sales.where(_isThisMonth).toList();
    final revenue = monthSales.fold<double>(0, (a, s) => a + s.total);
    final commissions = monthSales.fold<double>(0, (a, s) => a + sellerCommissionFor(s, appStore.sellerById(s.sellerId)));
    final profit = monthSales.fold<double>(0, (a, s) => a + storeProfitFor(s, appStore.sellerById(s.sellerId)));
    final cards = [('مبيعات الشهر', money(revenue), Icons.payments_outlined), ('عمولات البياعين', money(commissions), Icons.people_alt_outlined), ('ربح المؤسسة', money(profit), Icons.trending_up), ('مخزون منخفض', '${appStore.carpets.where((c) => c.lengthMeters < 25).length}', Icons.warning_amber_rounded)];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('ملخص الشهر', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.3, crossAxisSpacing: 10, mainAxisSpacing: 10, children: cards.map((c) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(c.$3), Text(c.$1), FittedBox(child: Text(c.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))])))).toList()),
      const SizedBox(height: 18),
      const Text('آخر المبيعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (appStore.sales.isEmpty) const EmptyCard('لا توجد مبيعات حتى الآن.'),
      ...appStore.sales.take(6).map((s) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.receipt_long)), title: Text('${s.carpetName} - ${s.color}'), subtitle: Text('${s.sellerName} • ${s.length.toStringAsFixed(1)}م • ${appStore.shopById(s.shopId).name}'), trailing: Text(money(s.total), style: const TextStyle(fontWeight: FontWeight.bold))))),
    ]);
  }
}

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key, required this.role});
  final UserRole role;
  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  CarpetItem? carpet;
  Seller? seller;
  Driver? driver;
  String customerPayment = 'كاش';
  String driverPayment = 'كاش';
  final lengthC = TextEditingController(), priceC = TextEditingController();
  final installationC = TextEditingController(text: '0'), glueC = TextEditingController(text: '0'), ironC = TextEditingController(text: '0'), driverFeeC = TextEditingController(text: '0');
  double _n(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  double get length => _n(lengthC);
  double get area => length * (carpet?.widthMeters ?? 0);
  double get total => area * _n(priceC) + _n(installationC) + _n(glueC) + _n(ironC) + _n(driverFeeC);
  @override
  void dispose() { for (final c in [lengthC, priceC, installationC, glueC, ironC, driverFeeC]) { c.dispose(); } super.dispose(); }

  Future<void> _save() async {
    if (carpet == null || seller == null || length <= 0 || _n(priceC) <= 0) { _snack('أكمل القطعة والبائع والطول وسعر البيع'); return; }
    if (length > carpet!.lengthMeters) { _snack('الطول المطلوب أكبر من المتاح بالمخزن'); return; }
    final fee = total * appStore.feeRate(customerPayment);
    final sale = Sale(id: appStore.newId(), createdAt: DateTime.now(), shopId: seller!.shopId, carpetId: carpet!.id, carpetName: carpet!.name, color: carpet!.color, sellerId: seller!.id, sellerName: seller!.name, driverId: driver?.id, driverName: driver?.name, length: length, width: carpet!.widthMeters, salePricePerSqm: _n(priceC), supplierPricePerSqm: carpet!.supplierPricePerSqm, overheadPerSqm: carpet!.overheadPerSqm, installation: _n(installationC), glue: _n(glueC), iron: _n(ironC), driverFee: _n(driverFeeC), customerPayment: customerPayment, driverPayment: driverPayment, paymentFee: fee);
    await appStore.addSale(sale);
    if (!mounted) return;
    _snack('تم حفظ البيعة وخصم ${length.toStringAsFixed(1)} متر من المخزون');
    setState(() { lengthC.clear(); priceC.clear(); installationC.text = '0'; glueC.text = '0'; ironC.text = '0'; driverFeeC.text = '0'; });
  }
  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.accountant) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('إدخال المبيعات متاح لصاحب المؤسسة والبائع. المحاسب يراجع الحسابات والتسويات.')));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('بيع جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      DropdownButtonFormField<CarpetItem>(initialValue: carpet, decoration: const InputDecoration(labelText: 'الصنف واللون'), items: appStore.carpets.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} - ${c.color} (${c.lengthMeters.toStringAsFixed(1)}م)'))).toList(), onChanged: (v) => setState(() => carpet = v)),
      gap,
      DropdownButtonFormField<Seller>(initialValue: seller, decoration: const InputDecoration(labelText: 'البائع والمحل'), items: appStore.sellers.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} - ${appStore.shopById(s.shopId).name}'))).toList(), onChanged: (v) => setState(() => seller = v)),
      gap,
      Row(children: [Expanded(child: NumField(controller: lengthC, label: 'الطول بالمتر', onChanged: _redraw)), const SizedBox(width: 8), Expanded(child: InputDecorator(decoration: const InputDecoration(labelText: 'المساحة'), child: Text('${area.toStringAsFixed(2)} م²')))]),
      gap,
      NumField(controller: priceC, label: 'سعر بيع المتر المربع', onChanged: _redraw),
      gap,
      Row(children: [Expanded(child: NumField(controller: installationC, label: 'التركيب', onChanged: _redraw)), const SizedBox(width: 8), Expanded(child: NumField(controller: glueC, label: 'الغراء', onChanged: _redraw))]),
      gap,
      Row(children: [Expanded(child: NumField(controller: ironC, label: 'الحديد', onChanged: _redraw)), const SizedBox(width: 8), Expanded(child: NumField(controller: driverFeeC, label: 'حساب السائق', onChanged: _redraw))]),
      gap,
      DropdownButtonFormField<Driver>(initialValue: driver, decoration: const InputDecoration(labelText: 'السائق (اختياري)'), items: appStore.drivers.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(), onChanged: (v) => setState(() => driver = v)),
      gap,
      Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: customerPayment, decoration: const InputDecoration(labelText: 'دفع العميل'), items: ['كاش', 'شبكة', 'فيزا', 'تابي', 'تمارا'].map(_paymentItem).toList(), onChanged: (v) => setState(() => customerPayment = v!))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<String>(initialValue: driverPayment, decoration: const InputDecoration(labelText: 'دفع السائق'), items: ['كاش', 'تحويل بنكي'].map(_paymentItem).toList(), onChanged: (v) => setState(() => driverPayment = v!)))]),
      gap,
      Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [ValueRow('المساحة', '${area.toStringAsFixed(2)} م²'), ValueRow('إجمالي العميل', money(total), bold: true), ValueRow('رسوم الدفع', money(total * appStore.feeRate(customerPayment)))]))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Padding(padding: EdgeInsets.all(14), child: Text('حفظ البيعة'))),
    ]);
  }
  void _redraw(String _) => setState(() {});
  DropdownMenuItem<String> _paymentItem(String p) => DropdownMenuItem(value: p, child: Text(p));
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('المخزون', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const Text('سعر الجملة = سعر المورد + نصيب مصروفات المؤسسة'),
      const SizedBox(height: 10),
      if (appStore.carpets.isEmpty) const EmptyCard('أضف أول صنف للمخزون.'),
      ...appStore.carpets.map((c) => Card(child: ListTile(leading: CircleAvatar(child: Text(c.color.isEmpty ? '؟' : c.color.characters.first)), title: Text('${c.name} - ${c.color}'), subtitle: Text('${c.supplier}\nالمورد ${money(c.supplierPricePerSqm)} + مصروفات ${money(c.overheadPerSqm)} = جملة ${money(c.wholesalePricePerSqm)} /م²'), isThreeLine: true, trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${c.lengthMeters.toStringAsFixed(1)}م', style: const TextStyle(fontWeight: FontWeight.bold)), if (c.lengthMeters < 25) const Icon(Icons.warning_amber, size: 18, color: Colors.orange)]), onTap: () => _stockDialog(context, c)))),
      const SizedBox(height: 80),
    ]), floatingActionButton: FloatingActionButton.extended(onPressed: () => _addCarpetDialog(context), icon: const Icon(Icons.add), label: const Text('صنف جديد')));
  }
}

Future<void> _addCarpetDialog(BuildContext context) async {
  final name = TextEditingController(), color = TextEditingController(), supplier = TextEditingController();
  final length = TextEditingController(), width = TextEditingController(text: '4'), cost = TextEditingController(), overhead = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('إضافة صنف'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الصنف')), gap, TextField(controller: color, decoration: const InputDecoration(labelText: 'اللون')), gap, TextField(controller: supplier, decoration: const InputDecoration(labelText: 'المورد')), gap, NumField(controller: length, label: 'الطول المتاح'), gap, NumField(controller: width, label: 'عرض الرول'), gap, NumField(controller: cost, label: 'سعر المورد /م²'), gap, NumField(controller: overhead, label: 'مصاريف المؤسسة /م²')])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { final values = [length, width, cost, overhead].map((c) => double.tryParse(c.text) ?? 0).toList(); if (name.text.trim().isEmpty || values[0] <= 0 || values[1] <= 0) return; appStore.carpets.add(CarpetItem(id: appStore.newId(), name: name.text.trim(), color: color.text.trim(), supplier: supplier.text.trim(), lengthMeters: values[0], widthMeters: values[1], supplierPricePerSqm: values[2], overheadPerSqm: values[3])); await appStore.changed(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('حفظ'))]));
}

Future<void> _stockDialog(BuildContext context, CarpetItem carpet) async {
  final qty = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text('إضافة مخزون - ${carpet.name}'), content: NumField(controller: qty, label: 'الطول المضاف بالمتر'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { final n = double.tryParse(qty.text) ?? 0; if (n <= 0) return; carpet.lengthMeters += n; await appStore.changed(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('إضافة'))]));
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key, required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Column(children: [const TabBar(tabs: [Tab(text: 'البياعين'), Tab(text: 'السائقون')]), Expanded(child: TabBarView(children: [
      ListView(padding: const EdgeInsets.all(16), children: [const Text('تصفية الشهر الحالي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ...appStore.sellers.map((s) {
        final sales = appStore.sales.where((x) => x.sellerId == s.id && _isThisMonth(x)).toList();
        final commission = sales.fold<double>(0, (a, x) => a + sellerCommissionFor(x, s));
        final entries = appStore.ledger.where((e) => e.personType == 'seller' && e.personId == s.id && _isThisMonth(e.createdAt)).toList();
        return Card(child: ExpansionTile(title: Text(s.name), subtitle: Text('${appStore.shopById(s.shopId).name} • ${s.plan.label}'), trailing: Text(money(appStore.sellerBalance(s)), style: const TextStyle(fontWeight: FontWeight.bold)), childrenPadding: const EdgeInsets.all(16), children: [ValueRow('الراتب', money(s.plan == SellerPlan.commission ? 0 : s.salary)), ValueRow('العمولات', money(commission)), ...entries.map((e) => ValueRow('${e.kind}: ${e.note}', '- ${money(e.amount)}')), const Divider(), ValueRow('صافي المستحق', money(appStore.sellerBalance(s)), bold: true), if (role != UserRole.seller) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _ledgerDialog(context, 'seller', s.id), icon: const Icon(Icons.add), label: const Text('مسحوب أو مصروف')))]));
      })]),
      ListView(padding: const EdgeInsets.all(16), children: [const Text('حساب السائقين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ...appStore.drivers.map((d) {
        final trips = appStore.sales.where((s) => s.driverId == d.id && _isThisMonth(s)).toList();
        return Card(child: ExpansionTile(title: Text(d.name), subtitle: Text('${trips.length} مشاوير هذا الشهر'), trailing: Text(money(appStore.driverBalance(d)), style: const TextStyle(fontWeight: FontWeight.bold)), childrenPadding: const EdgeInsets.all(16), children: [...trips.map((s) => ValueRow('${appStore.shopById(s.shopId).name} • ${s.sellerName}', money(s.driverFee))), const Divider(), ValueRow('المتبقي', money(appStore.driverBalance(d)), bold: true), if (role != UserRole.seller) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _ledgerDialog(context, 'driver', d.id), icon: const Icon(Icons.payments), label: const Text('تسجيل دفعة')))]));
      })]),
    ]))]));
  }
}

Future<void> _ledgerDialog(BuildContext context, String personType, String personId) async {
  String kind = personType == 'driver' ? 'دفعة' : 'مسحوب', payment = 'كاش';
  final amount = TextEditingController(), note = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(title: Text(personType == 'driver' ? 'دفعة للسائق' : 'حركة حساب بائع'), content: Column(mainAxisSize: MainAxisSize.min, children: [if (personType == 'seller') DropdownButtonFormField<String>(initialValue: kind, decoration: const InputDecoration(labelText: 'النوع'), items: ['مسحوب', 'مصروف'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setLocal(() => kind = v!)), if (personType == 'seller') gap, NumField(controller: amount, label: 'المبلغ'), gap, TextField(controller: note, decoration: const InputDecoration(labelText: 'ملاحظة')), gap, DropdownButtonFormField<String>(initialValue: payment, decoration: const InputDecoration(labelText: 'طريقة الدفع'), items: ['كاش', 'تحويل بنكي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setLocal(() => payment = v!))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { final n = double.tryParse(amount.text) ?? 0; if (n <= 0) return; appStore.ledger.insert(0, LedgerEntry(id: appStore.newId(), createdAt: DateTime.now(), personType: personType, personId: personId, kind: kind, amount: n, note: note.text.trim(), paymentMethod: payment)); await appStore.changed(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('حفظ'))])));
}

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  Driver? selected;
  @override
  void initState() { super.initState(); if (appStore.drivers.isNotEmpty) selected = appStore.drivers.first; appStore.addListener(_refresh); }
  @override
  void dispose() { appStore.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  Widget build(BuildContext context) {
    final trips = selected == null ? <Sale>[] : appStore.sales.where((s) => s.driverId == selected!.id).toList();
    return Scaffold(appBar: AppBar(title: const Text('حساب السائق'), actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.logout))]), body: ListView(padding: const EdgeInsets.all(16), children: [DropdownButtonFormField<Driver>(initialValue: selected, decoration: const InputDecoration(labelText: 'اختار السائق'), items: appStore.drivers.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(), onChanged: (v) => setState(() => selected = v)), const SizedBox(height: 18), if (selected != null) Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(16), child: ValueRow('المتبقي هذا الشهر', money(appStore.driverBalance(selected!)), bold: true))), const SizedBox(height: 12), const Text('مشاويري', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), if (trips.isEmpty) const EmptyCard('لا توجد مشاوير مسجلة.'), ...trips.map((s) => Card(child: ListTile(leading: const Icon(Icons.local_shipping), title: Text(appStore.shopById(s.shopId).name), subtitle: Text('البائع: ${s.sellerName}\n${s.carpetName} - ${s.color} • ${s.driverPayment}'), isThreeLine: true, trailing: Text(money(s.driverFee), style: const TextStyle(fontWeight: FontWeight.bold)))))]));
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('الإدارة والتقارير', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Card(child: ListTile(leading: const Icon(Icons.bar_chart), title: const Text('تقرير الشهر'), subtitle: const Text('المبيعات والربح حسب المحل والبائع'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.store), title: const Text('المحلات'), subtitle: Text('${appStore.shops.length} محل'), trailing: const Icon(Icons.add), onTap: () => _simpleEntityDialog(context, 'shop'))),
      Card(child: ListTile(leading: const Icon(Icons.badge), title: const Text('البياعين'), subtitle: Text('${appStore.sellers.length} بائع'), trailing: const Icon(Icons.add), onTap: () => _addSellerDialog(context))),
      Card(child: ListTile(leading: const Icon(Icons.local_shipping), title: const Text('السائقون'), subtitle: Text('${appStore.drivers.length} سائق'), trailing: const Icon(Icons.add), onTap: () => _simpleEntityDialog(context, 'driver'))),
      Card(child: ExpansionTile(leading: const Icon(Icons.settings), title: const Text('رسوم طرق الدفع'), childrenPadding: const EdgeInsets.all(16), children: [ValueRow('فيزا', '${(appStore.visaFee * 100).toStringAsFixed(1)}%'), ValueRow('تابي', '${(appStore.tabbyFee * 100).toStringAsFixed(1)}%'), ValueRow('تمارا', '${(appStore.tamaraFee * 100).toStringAsFixed(1)}%')])),
      const AboutListTile(icon: Icon(Icons.info_outline), applicationName: 'إدارة الموكيت', applicationVersion: '0.2.0', applicationLegalese: 'نسخة MVP محلية'),
    ]);
  }
}

Future<void> _simpleEntityDialog(BuildContext context, String type) async {
  final name = TextEditingController(), phone = TextEditingController();
  await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(type == 'shop' ? 'إضافة محل' : 'إضافة سائق'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')), if (type == 'driver') gap, if (type == 'driver') TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; if (type == 'shop') { appStore.shops.add(Shop(id: appStore.newId(), name: name.text.trim())); } else { appStore.drivers.add(Driver(id: appStore.newId(), name: name.text.trim(), phone: phone.text.trim())); } await appStore.changed(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('حفظ'))]));
}

Future<void> _addSellerDialog(BuildContext context) async {
  final name = TextEditingController(), phone = TextEditingController(), salary = TextEditingController(text: '0'), commission = TextEditingController(text: '50');
  Shop? shop = appStore.shops.isEmpty ? null : appStore.shops.first;
  SellerPlan plan = SellerPlan.commission;
  await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(title: const Text('إضافة بائع'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')), gap, TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'الهاتف')), gap, DropdownButtonFormField<Shop>(initialValue: shop, decoration: const InputDecoration(labelText: 'المحل'), items: appStore.shops.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (v) => setLocal(() => shop = v)), gap, DropdownButtonFormField<SellerPlan>(initialValue: plan, decoration: const InputDecoration(labelText: 'نظام العمل'), items: SellerPlan.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(), onChanged: (v) => setLocal(() => plan = v!)), gap, if (plan != SellerPlan.commission) NumField(controller: salary, label: 'الراتب الشهري'), if (plan != SellerPlan.salary) gap, if (plan != SellerPlan.salary) NumField(controller: commission, label: 'نسبة العمولة من فرق السعر %')])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty || shop == null) return; appStore.sellers.add(Seller(id: appStore.newId(), name: name.text.trim(), phone: phone.text.trim(), shopId: shop!.id, plan: plan, salary: double.tryParse(salary.text) ?? 0, commissionRate: (double.tryParse(commission.text) ?? 0) / 100)); await appStore.changed(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('حفظ'))])));
}

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sales = appStore.sales.where(_isThisMonth).toList();
    return Scaffold(appBar: AppBar(title: const Text('تقرير الشهر الحالي')), body: ListView(padding: const EdgeInsets.all(16), children: [
      ...appStore.shops.map((shop) { final list = sales.where((s) => s.shopId == shop.id).toList(); final revenue = list.fold<double>(0, (a, s) => a + s.total); final profit = list.fold<double>(0, (a, s) => a + storeProfitFor(s, appStore.sellerById(s.sellerId))); return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(shop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(), ValueRow('عدد المبيعات', '${list.length}'), ValueRow('إجمالي التحصيل', money(revenue)), ValueRow('ربح المؤسسة قبل المصروفات العامة', money(profit), bold: true)]))); }),
      const SizedBox(height: 14),
      const Text('أداء البياعين', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ...appStore.sellers.map((seller) { final list = sales.where((s) => s.sellerId == seller.id).toList(); return Card(child: ListTile(title: Text(seller.name), subtitle: Text('${list.length} مبيعات • ${seller.plan.label}'), trailing: Text(money(list.fold<double>(0, (a, s) => a + s.total))))); }),
    ]));
  }
}

class NumField extends StatelessWidget {
  const NumField({super.key, required this.controller, required this.label, this.onChanged});
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: onChanged, decoration: InputDecoration(labelText: label));
}

class ValueRow extends StatelessWidget {
  const ValueRow(this.label, this.value, {super.key, this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null))), const SizedBox(width: 8), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null))]));
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(text)));
}

const gap = SizedBox(height: 10);
String money(double value) => '${value.toStringAsFixed(2)} ر.س';
bool _isThisMonth(dynamic item) {
  final DateTime date = item is Sale ? item.createdAt : item as DateTime;
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}
