class PriceConverterHelper {
  const PriceConverterHelper._();

  static double? convertWithDiscount(double? price, double? discount, String? discountType) {
    if (discountType == 'amount') {
      price = price! - discount!;
    } else if (discountType == 'percent' && (discount ?? 0) > 0) {
      price = price! - ((discount! / 100) * price);
    }
    return price;
  }
}
