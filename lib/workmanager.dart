import 'package:camera_app/main.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case 'schedule_weather_notification_task':
        final maxTemp = await fetchForecast();
        Notifications.showNotification(
          title: "Here's the forecast from workmanager!",
          body: "It's forecasted $maxTemp degrees today.",
        );
        return Future.value(true);
        break;
      default:
        return Future.error('workmanager.dart: No such task defined');
    }
    return Future.value(true);
  });
}
