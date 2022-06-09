
import '../models/active_drivers.dart';

class GeoFireHelper
{
  static List<ActiveDrivers> activeDrivers = [];

  static void removeOfflineDriver(String driverId)
  {
    int indexNumber = activeDrivers.indexWhere((element) => element.driverId == driverId);
    activeDrivers.removeAt(indexNumber);
  }

  static void updateDriverLocation(ActiveDrivers movingDriver)
  {
    int index = activeDrivers.indexWhere((element) => element.driverId == movingDriver.driverId);

    activeDrivers[index].latitude = movingDriver.latitude;
    activeDrivers[index].longitude = movingDriver.longitude;
  }
}