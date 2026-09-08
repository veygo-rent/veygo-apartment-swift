import Foundation

/// Discounts on the estimated charges before tax. Duration has already had
/// reward hours deducted; a promo cannot reduce mileage or insurance charges.
struct PricingDiscounts {
    let promoDiscount: Decimal
    let manualDiscount: Decimal
    let subtotalBeforeTax: Decimal

    init(
        durationSubtotal: Decimal,
        mileageSubtotal: Decimal,
        insuranceSubtotal: Decimal,
        promoAmount: Decimal = .zero,
        manualDiscountAmount: Decimal = .zero
    ) {
        let duration = max(.zero, durationSubtotal)
        promoDiscount = min(duration, max(.zero, promoAmount))
        let subtotalAfterPromo = duration - promoDiscount
            + max(.zero, mileageSubtotal) + max(.zero, insuranceSubtotal)
        manualDiscount = min(subtotalAfterPromo, max(.zero, manualDiscountAmount))
        subtotalBeforeTax = subtotalAfterPromo - manualDiscount
    }
}
