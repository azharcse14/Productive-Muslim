/// Builds the external Google Maps URL that searches for mosques around a
/// given coordinate. Pure (no plugins) so the URL shape is unit-testable.
///
/// The `/maps/search/<query>/@lat,lng,zoom` form is a universal link: on a
/// device with Google Maps installed it deep-links into the app centred on
/// the coordinate; otherwise it opens the same search in a browser.
abstract final class NearbyMosquesUrl {
  /// Default map zoom — close enough to show nearby streets, wide enough to
  /// surface several mosques at once.
  static const int _zoom = 15;

  /// Search keyword. English "mosque" is understood by Maps worldwide and
  /// matches more results than a transliteration would.
  static const String _query = 'mosque';

  /// A [Uri] that opens Google Maps searching for mosques near
  /// ([latitude], [longitude]).
  static Uri build({required double latitude, required double longitude}) {
    final lat = _format(latitude);
    final lng = _format(longitude);
    return Uri.parse(
      'https://www.google.com/maps/search/$_query/@$lat,$lng,${_zoom}z',
    );
  }

  /// Coordinates use a '.' decimal separator regardless of locale — `double`
  /// `toString()` already guarantees this, but trim noisy precision.
  static String _format(double value) =>
      value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
}
