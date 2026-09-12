enum UserRole { owner, accountant, seller, driver }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.owner => 'صاحب المؤسسة',
        UserRole.accountant => 'المحاسب',
        UserRole.seller => 'البائع',
        UserRole.driver => 'السائق',
      };
}

enum SellerPlan { salary, commission, salaryAndCommission }

extension SellerPlanX on SellerPlan {
  String get label => switch (this) {
        SellerPlan.salary => 'راتب',
        SellerPlan.commission => 'عمولة',
        SellerPlan.salaryAndCommission => 'راتب + عمولة',
      };
}

class Shop {
  Shop({required this.id, required this.name});
  final String id;
  String name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Shop.fromJson(Map<String, dynamic> j) => Shop(id: j['id'], name: j['name']);
}

class CarpetItem {
  CarpetItem({required this.id, required this.name, required this.color, required this.supplier, required this.lengthMeters, required this.widthMeters, required this.supplierPricePerSqm, required this.overheadPerSqm});
  final String id;
  String name;
  String color;
  String supplier;
  double lengthMeters;
  double widthMeters;
  double supplierPricePerSqm;
  double overheadPerSqm;
  double get wholesalePricePerSqm => supplierPricePerSqm + overheadPerSqm;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'supplier': supplier, 'lengthMeters': lengthMeters, 'widthMeters': widthMeters, 'supplierPricePerSqm': supplierPricePerSqm, 'overheadPerSqm': overheadPerSqm};
  factory CarpetItem.fromJson(Map<String, dynamic> j) => CarpetItem(id: j['id'], name: j['name'], color: j['color'], supplier: j['supplier'], lengthMeters: (j['lengthMeters'] as num).toDouble(), widthMeters: (j['widthMeters'] as num).toDouble(), supplierPricePerSqm: (j['supplierPricePerSqm'] as num).toDouble(), overheadPerSqm: (j['overheadPerSqm'] as num).toDouble());
}

class Seller {
  Seller({required this.id, required this.name, required this.phone, required this.shopId, required this.plan, this.commissionRate = .5, this.salary = 0});
  final String id;
  String name;
  String phone;
  String shopId;
  SellerPlan plan;
  double commissionRate;
  double salary;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'shopId': shopId, 'plan': plan.name, 'commissionRate': commissionRate, 'salary': salary};
  factory Seller.fromJson(Map<String, dynamic> j) => Seller(id: j['id'], name: j['name'], phone: j['phone'], shopId: j['shopId'], plan: SellerPlan.values.byName(j['plan']), commissionRate: (j['commissionRate'] as num).toDouble(), salary: (j['salary'] as num).toDouble());
}

class Driver {
  Driver({required this.id, required this.name, required this.phone});
  final String id;
  String name;
  String phone;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
  factory Driver.fromJson(Map<String, dynamic> j) => Driver(id: j['id'], name: j['name'], phone: j['phone']);
}

class Sale {
  Sale({required this.id, required this.createdAt, required this.shopId, required this.carpetId, required this.carpetName, required this.color, required this.sellerId, required this.sellerName, this.driverId, this.driverName, required this.length, required this.width, required this.salePricePerSqm, required this.supplierPricePerSqm, required this.overheadPerSqm, required this.installation, required this.glue, required this.iron, required this.driverFee, required this.customerPayment, required this.driverPayment, required this.paymentFee});
  final String id;
  final DateTime createdAt;
  final String shopId;
  final String carpetId;
  final String carpetName;
  final String color;
  final String sellerId;
  final String sellerName;
  final String? driverId;
  final String? driverName;
  final double length;
  final double width;
  final double salePricePerSqm;
  final double supplierPricePerSqm;
  final double overheadPerSqm;
  final double installation;
  final double glue;
  final double iron;
  final double driverFee;
  final String customerPayment;
  final String driverPayment;
  final double paymentFee;
  double get area => length * width;
  double get carpetTotal => area * salePricePerSqm;
  double get total => carpetTotal + installation + glue + iron + driverFee;
  double get wholesaleTotal => area * (supplierPricePerSqm + overheadPerSqm);
  double get differenceProfit => carpetTotal - wholesaleTotal;
  Map<String, dynamic> toJson() => {'id': id, 'createdAt': createdAt.toIso8601String(), 'shopId': shopId, 'carpetId': carpetId, 'carpetName': carpetName, 'color': color, 'sellerId': sellerId, 'sellerName': sellerName, 'driverId': driverId, 'driverName': driverName, 'length': length, 'width': width, 'salePricePerSqm': salePricePerSqm, 'supplierPricePerSqm': supplierPricePerSqm, 'overheadPerSqm': overheadPerSqm, 'installation': installation, 'glue': glue, 'iron': iron, 'driverFee': driverFee, 'customerPayment': customerPayment, 'driverPayment': driverPayment, 'paymentFee': paymentFee};
  factory Sale.fromJson(Map<String, dynamic> j) => Sale(id: j['id'], createdAt: DateTime.parse(j['createdAt']), shopId: j['shopId'], carpetId: j['carpetId'], carpetName: j['carpetName'], color: j['color'], sellerId: j['sellerId'], sellerName: j['sellerName'], driverId: j['driverId'], driverName: j['driverName'], length: (j['length'] as num).toDouble(), width: (j['width'] as num).toDouble(), salePricePerSqm: (j['salePricePerSqm'] as num).toDouble(), supplierPricePerSqm: (j['supplierPricePerSqm'] as num).toDouble(), overheadPerSqm: (j['overheadPerSqm'] as num).toDouble(), installation: (j['installation'] as num).toDouble(), glue: (j['glue'] as num).toDouble(), iron: (j['iron'] as num).toDouble(), driverFee: (j['driverFee'] as num).toDouble(), customerPayment: j['customerPayment'], driverPayment: j['driverPayment'], paymentFee: (j['paymentFee'] as num).toDouble());
}

class LedgerEntry {
  LedgerEntry({required this.id, required this.createdAt, required this.personType, required this.personId, required this.kind, required this.amount, required this.note, required this.paymentMethod});
  final String id;
  final DateTime createdAt;
  final String personType;
  final String personId;
  final String kind;
  final double amount;
  final String note;
  final String paymentMethod;
  Map<String, dynamic> toJson() => {'id': id, 'createdAt': createdAt.toIso8601String(), 'personType': personType, 'personId': personId, 'kind': kind, 'amount': amount, 'note': note, 'paymentMethod': paymentMethod};
  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(id: j['id'], createdAt: DateTime.parse(j['createdAt']), personType: j['personType'], personId: j['personId'], kind: j['kind'], amount: (j['amount'] as num).toDouble(), note: j['note'], paymentMethod: j['paymentMethod']);
}

double sellerCommissionFor(Sale sale, Seller seller) {
  if (seller.plan == SellerPlan.salary) return 0;
  return sale.differenceProfit > 0 ? sale.differenceProfit * seller.commissionRate : 0;
}

double storeProfitFor(Sale sale, Seller seller) {
  final supplierCost = sale.area * sale.supplierPricePerSqm;
  return sale.carpetTotal - supplierCost - sellerCommissionFor(sale, seller) - sale.paymentFee;
}
