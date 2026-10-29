/// One raw sensor sample pair, in the device coordinate system.
typedef SensorVectors = ({
  double ax,
  double ay,
  double az,
  double mx,
  double my,
  double mz,
});

/// Seam over sensors_plus so the store (and tests) never touch plugin
/// statics. Streams error on devices without the sensor.
abstract interface class CompassSensorSource {
  Stream<SensorVectors> vectors();
}
