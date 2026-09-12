import 'package:carpet_shop_manager/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sale = Sale(
    id: '1',
    createdAt: DateTime(2026, 9, 12),
    shopId: 'shop',
    carpetId: 'carpet',
    carpetName: 'رويال',
    color: 'بيج',
    sellerId: 'seller',
    sellerName: 'أحمد',
    length: 3,
    width: 4,
    salePricePerSqm: 35,
    supplierPricePerSqm: 20,
    overheadPerSqm: 5,
    installation: 100,
    glue: 0,
    iron: 0,
    driverFee: 50,
    customerPayment: 'كاش',
    driverPayment: 'كاش',
    paymentFee: 0,
  );

  test('calculates area and totals', () {
    expect(sale.area, 12);
    expect(sale.carpetTotal, 420);
    expect(sale.wholesaleTotal, 300);
    expect(sale.total, 570);
  });

  test('commission plan splits price difference', () {
    final seller = Seller(id: 'seller', name: 'أحمد', phone: '', shopId: 'shop', plan: SellerPlan.commission, commissionRate: .5);
    expect(sellerCommissionFor(sale, seller), 60);
    expect(storeProfitFor(sale, seller), 120);
  });

  test('salary-only plan receives no commission', () {
    final seller = Seller(id: 'seller', name: 'أحمد', phone: '', shopId: 'shop', plan: SellerPlan.salary, salary: 3000);
    expect(sellerCommissionFor(sale, seller), 0);
    expect(storeProfitFor(sale, seller), 180);
  });
}
