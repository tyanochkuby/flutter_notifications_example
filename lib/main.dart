import 'dart:convert';

import 'package:camera_app/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:workmanager/workmanager.dart';
import 'notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    Notifications.init();
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    requestNotificationPermissions();
    tz.initializeTimeZones();
    listenNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 300,),
            ElevatedButton(
                onPressed: (){
                  fetchForecast().then((value) =>
                  Notifications.showNotification(
                      title: "Hey, here's the forecast!",
                      body: "It's forecasted $value degrees today.",
                      payload: "Payload"
                  )
                  );
                },
                child: const Text("Simple Notification")),
            ElevatedButton(
                onPressed: () async{
                  final perm_handler.PermissionStatus status =
                      await perm_handler.Permission.notification.request();
                  if (status.isGranted) {
                    TimeOfDay? selectedTime = null;
                    while (selectedTime == null) {
                      selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    }
                    Notifications.registerDailyForecastNotifications(
                        time: selectedTime);
                  }
                },
                child: const Text("Subscribe to notifications with workmanager")
            ), //If you hit the button, you will need to pick the time the notification will be sent
          ],
        ),
      ),
    );
  }
}

void listenNotifications() {
  Notifications.onNotification.stream.listen(onClickedNotification);
}

onClickedNotification(String? payload) => print(payload);

Future<void> requestNotificationPermissions() async {
  final perm_handler.PermissionStatus status = await perm_handler.Permission.notification.request();
  if (status.isGranted) {
    // Notification permissions granted
  } else if (status.isDenied) {
    // Notification permissions denied
  } else if (status.isPermanentlyDenied) {
    // Notification permissions permanently denied, open app settings
  }
}

Future<double> fetchForecast() async{
  http.Client client = http.Client();
  final response = await client.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=52.41&longitude=16.93&daily=temperature_2m_max&forecast_days=1&timezone=Europe%2FBerlin'));
  Map<String, dynamic> forecastMap = json.decode(response.body);
  double maxTemp = forecastMap['daily']['temperature_2m_max'][0];
  return maxTemp;
}
