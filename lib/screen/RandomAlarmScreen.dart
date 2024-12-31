import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:numberpicker/numberpicker.dart';

class RandomAlarmScreen extends StatefulWidget {
  const RandomAlarmScreen({super.key});

  @override
  _RandomAlarmScreenState createState() => _RandomAlarmScreenState();
}

class _RandomAlarmScreenState extends State<RandomAlarmScreen>
    with SingleTickerProviderStateMixin {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isAlarmStarted = false; // Tracks alarm state
  late AnimationController _animationController;
  int _selectedAlarmsCount = 1; // Default value for the number of alarms

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones(); // Initialize timezone database
    _initializeNotifications();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _initializeNotifications() async {
    // Request notification permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'random_alarm_channel1',
      'Random Alarm Notifications1',
      description: 'Channel for random alarm notifications',
      importance: Importance.high,
      playSound: true,
    );

    final androidFlutterPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidFlutterPlugin != null) {
      await androidFlutterPlugin.createNotificationChannel(androidChannel);
    }
  }

  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  void _startOrStopAlarms() {
    if (_isAlarmStarted) {
      // Stop the alarm
      setState(() {
        _isAlarmStarted = false;
      });
      _animationController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarms stopped.')),
      );
    } else {
      // Validate inputs and start the alarm
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end times.')),
        );
        return;
      }

      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      setState(() {
        _isAlarmStarted = true;
      });

      _startRandomAlarms(startMinutes, endMinutes, _selectedAlarmsCount);
    }
  }

  void _startRandomAlarms(int startMinutes, int endMinutes, int alarmCount) {
    final randomTimes = List.generate(
      alarmCount,
      (_) => startMinutes + Random().nextInt(endMinutes - startMinutes),
    );

    randomTimes.sort(); // Ensure alarms are in chronological order

    for (final minutes in randomTimes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      final scheduleTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      );

      if (scheduleTime.isAfter(DateTime.now())) {
        _scheduleAlarm(scheduleTime);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alarms started successfully.')),
    );
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  Future<void> _scheduleAlarm(DateTime scheduleTime) async {
    final androidDetails = AndroidNotificationDetails(
      'random_alarm_channel1',
      'Random Alarm Notifications1',
      channelDescription: 'Channel for random alarm notifications',
      priority: Priority.high,
      importance: Importance.high,
      playSound: true,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      scheduleTime.millisecondsSinceEpoch ~/ 1000,
      'Random Alarm',
      'Alarm scheduled at ${scheduleTime.hour}:${scheduleTime.minute}',
      _convertToTZDateTime(scheduleTime),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Trigger the animation when the alarm is scheduled
    Timer(scheduleTime.difference(DateTime.now()), () {
      _animationController.repeat(reverse: true);
      Timer(const Duration(seconds: 3), () {
        _animationController.stop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF353535),
                  Color(0xFF555555),
                  Color(0xFF888888),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + (_animationController.value * 0.2),
                      child: Transform.translate(
                        offset: Offset(
                          _animationController.value * 10,
                          0,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(Icons.alarm, size: 100, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _selectStartTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: Text(
                        _startTime == null
                            ? 'Start Time'
                            : 'Start: ${_startTime!.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectEndTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: Text(
                        _endTime == null
                            ? 'End Time'
                            : 'End: ${_endTime!.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    const Text(
                      'Number of Alarms',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: NumberPicker(
                        value: _selectedAlarmsCount,
                        minValue: 1,
                        maxValue: 5,
                        step: 1,
                        axis: Axis.horizontal,
                        selectedTextStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white, width: 1),
                            right: BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedAlarmsCount = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startOrStopAlarms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAlarmStarted
                        ? const Color(0xFF8B0000) // Dark Red
                        : Colors.orangeAccent,
                  ),
                  child: Text(
                    _isAlarmStarted
                        ? 'Alarm Started: Click to Stop'
                        : 'Start Random Alarms',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
