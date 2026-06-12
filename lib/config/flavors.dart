/// Build flavors. Qalbee has no backend, so flavors only gate
/// development-time affordances (e.g. the widget gallery route).
enum Flavor {
  dev,
  prod;

  static Flavor current = const bool.fromEnvironment('dart.vm.product')
      ? Flavor.prod
      : Flavor.dev;

  bool get isDev => this == Flavor.dev;
}
