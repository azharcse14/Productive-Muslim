import 'package:get_it/get_it.dart';

/// Global service locator. The ONLY place registrations happen
/// (guide §4 — single composition root). Widgets never call
/// `locator` directly; screen-level state objects resolve dependencies.
final GetIt locator = GetIt.instance;

/// Called in `main()` before `runApp`. Feature registrations are added
/// here phase by phase: data sources & repositories as lazySingleton,
/// use cases as factory/lazySingleton, presentation stores as factory.
Future<void> setupLocator() async {
  // Phase 2+: settings, location, prayer-times registrations land here.
}
