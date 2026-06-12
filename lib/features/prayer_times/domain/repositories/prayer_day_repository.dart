import '../../../../core/utils/result.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/prayer_day.dart';

/// Computes prayer times locally (no network — guide §1). Implemented in
/// the data layer over adhan_dart; all returned times are wall clock at
/// [location].
abstract interface class PrayerDayRepository {
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  });
}
