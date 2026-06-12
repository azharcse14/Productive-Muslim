import '../../../../core/utils/result.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/prayer_day.dart';
import '../repositories/prayer_day_repository.dart';

final class GetPrayerDay {
  const GetPrayerDay(this._repository);

  final PrayerDayRepository _repository;

  Result<PrayerDay> call({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) =>
      _repository.prayerDay(location: location, params: params, date: date);
}
