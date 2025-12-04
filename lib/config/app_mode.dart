class AppMode {
  AppMode._();

  /// Enables the stripped-down experience where admin features are hidden.
  static const bool isClientMode = bool.fromEnvironment(
    'TPAY_CLIENT_MODE',
    defaultValue: true,
  );
}
