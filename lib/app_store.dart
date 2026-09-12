import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  static const _key = 'carpet_shop_data_v2';
  double visaFee = .02;
  double tabbyFee = .06;
  double tamaraFee = .06;
  final List<Shop> shops = [];
  final List<CarpetItem> carpets = [];
  final List<Seller> sellers = [];
  final List<Driver> drivers = [];
  final List<Sale> sales = [];
  final List<LedgerEntry> ledger = [];

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _seed();
      await save();
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      visaFee = (j['visaFee'] as num?)?.toDouble() ?? .02;
      tabbyFee = (j['tabbyFee'] as num?)?.toDouble() ?? .06;
      tamaraFee = (j['tamaraFee'] as num?)?.toDouble() ?? .06;
      shops.addAll((j['shops'] as List).map((e) => Shop.fromJson(Map<String, dynamic>.from(e))));
      carpets.addAll((j['carpets'] as List).map((e) => CarpetItem.fromJson(Map<String, dynamic>.from(e))));
      sellers.addAll((j['sellers'] as List).map((e) => Seller.fromJson(Map<String, dynamic>.from(e))));
      drivers.addAll((j['drivers'] as List).map((e) => Driver.fromJson(Map<String, dynamic>.from(e))));
      sales.addAll((j['sales'] as List).map((e) => Sale.fromJson(Map<String, dynamic>.from(e))));
      ledger.addAll((j['ledger'] as List).map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e))));
    } catch (_) {
      shops.clear(); carpets.clear(); sellers.clear(); drivers.clear(); sales.clear(); ledger.clear();
      _seed();
    }
    notifyListeners();
  }

  void _seed() {
    shops.addAll([Shop(id: 'shop1', name: 'المحل الرئيسي'), Shop(id: 'shop2', name: 'الفرع الثاني')]);
    carpets.addAll([
      CarpetItem(id: 'c1', name: 'رويال', color: 'بيج', supplier: 'مورد الرياض', lengthMeters: 80, widthMeters: 4, supplierPricePerSqm: 20, overheadPerSqm: 5),
      CarpetItem(id: 'c2', name: 'كلاسيك', color: 'رمادي', supplier: 'مورد الخليج', lengthMeters: 46, widthMeters: 4, supplierPricePerSqm: 18, overheadPerSqm: 5),
    ]);
    sellers.addAll([
      Seller(id: 's1', name: 'أحمد محمد', phone: '0500000001', shopId: 'shop1', plan: SellerPlan.salaryAndCommission, salary: 3000, commissionRate: .5),
      Seller(id: 's2', name: 'خالد علي', phone: '0500000002', shopId: 'shop2', plan: SellerPlan.commission, commissionRate: .5),
    ]);
    drivers.add(Driver(id: 'd1', name: 'محمد سالم', phone: '0550000001'));
  }

  double feeRate(String payment) => switch (payment) {'فيزا' => visaFee, 'تابي' => tabbyFee, 'تمارا' => tamaraFee, _ => 0};
  Seller sellerById(String id) => sellers.firstWhere((e) => e.id == id);
  Shop shopById(String id) => shops.firstWhere((e) => e.id == id);

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'visaFee': visaFee, 'tabbyFee': tabbyFee, 'tamaraFee': tamaraFee, 'shops': shops.map((e) => e.toJson()).toList(), 'carpets': carpets.map((e) => e.toJson()).toList(), 'sellers': sellers.map((e) => e.toJson()).toList(), 'drivers': drivers.map((e) => e.toJson()).toList(), 'sales': sales.map((e) => e.toJson()).toList(), 'ledger': ledger.map((e) => e.toJson()).toList()}));
  }

  Future<void> changed() async { notifyListeners(); await save(); }

  Future<void> addSale(Sale sale) async {
    final carpet = carpets.firstWhere((e) => e.id == sale.carpetId);
    if (sale.length > carpet.lengthMeters) throw StateError('الكمية غير متاحة');
    carpet.lengthMeters -= sale.length;
    sales.insert(0, sale);
    await changed();
  }

  double sellerBalance(Seller seller) {
    final monthSales = sales.where((s) => s.sellerId == seller.id && _thisMonth(s.createdAt));
    final commission = monthSales.fold<double>(0, (sum, s) => sum + sellerCommissionFor(s, seller));
    final salary = seller.plan == SellerPlan.commission ? 0 : seller.salary;
    final debits = ledger.where((e) => e.personType == 'seller' && e.personId == seller.id && _thisMonth(e.createdAt)).fold<double>(0, (sum, e) => sum + e.amount);
    return salary + commission - debits;
  }

  double driverBalance(Driver driver) {
    final trips = sales.where((s) => s.driverId == driver.id && _thisMonth(s.createdAt)).fold<double>(0, (sum, s) => sum + s.driverFee);
    final paid = ledger.where((e) => e.personType == 'driver' && e.personId == driver.id && e.kind == 'دفعة' && _thisMonth(e.createdAt)).fold<double>(0, (sum, e) => sum + e.amount);
    return trips - paid;
  }

  bool _thisMonth(DateTime d) { final n = DateTime.now(); return d.year == n.year && d.month == n.month; }
}

final appStore = AppStore();
