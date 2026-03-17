class MonetizationConfig {
  const MonetizationConfig._();

  static const String enableProPurchasesDefineName =
      'SKEDUX_ENABLE_PRO_PURCHASES';

  static const bool isProPurchaseEnabled = bool.fromEnvironment(
    enableProPurchasesDefineName,
    defaultValue: false,
  );
}