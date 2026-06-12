import '../../../../core/utils/result.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

final class SearchCities {
  const SearchCities(this._repository);

  final CityRepository _repository;

  Future<Result<List<City>>> call(String query, {int limit = 30}) =>
      _repository.search(query, limit: limit);
}
