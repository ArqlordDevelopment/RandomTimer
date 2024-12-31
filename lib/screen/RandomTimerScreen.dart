import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NumberSetter = void Function(int);

class RandomTimerScreen extends StatefulWidget {
  const RandomTimerScreen({super.key});

  @override
  _RandomTimerScreenState createState() => _RandomTimerScreenState();
}

class _RandomTimerScreenState extends State<RandomTimerScreen>
    with SingleTickerProviderStateMixin {
  int _totalDuration = 10;
  int _occurrences = 3;
  Timer? _timer;
  int _completedAlarms = 0;
  late AnimationController _animationController;
  bool _isTimerRunning = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });
  }

  void _initializeNotifications() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'chicken_alarm_channel',
      'Chicken Alarm',
      description: 'Channel for chicken alarm notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('chicken_alarm'),
      playSound: true,
    );

    final androidFlutterPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidFlutterPlugin?.createNotificationChannel(androidChannel);
  }

  void _startOrStopTimer() {
    if (_isTimerRunning) {
      _stopTimer();
    } else {
      _startRandomTimer();
    }
  }

  void _startRandomTimer() {
    if (_totalDuration <= 0 || _occurrences <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid duration and occurrences")),
      );
      return;
    }

    final interval = (_totalDuration * 1000) ~/ _occurrences;
    final randomDelays = List.generate(
      _occurrences,
      (_) => Random().nextInt(interval),
    );

    setState(() {
      _completedAlarms = 0;
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (_completedAlarms >= _occurrences) {
        timer.cancel();
        setState(() {
          _isTimerRunning = false;
        });
        return;
      }

      final randomDelay = randomDelays[_completedAlarms];

      Timer(Duration(milliseconds: randomDelay), () {
        _triggerNotification(_completedAlarms + 1);
      });

      setState(() {
        _completedAlarms++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  Future<void> _triggerNotification(int alarmNumber) async {
    const androidDetails = AndroidNotificationDetails(
      'chicken_alarm_channel',
      'Chicken Alarm',
      channelDescription: 'This is the chicken alarm sound',
      sound: RawResourceAndroidNotificationSound('chicken_alarm'),
      priority: Priority.high,
      importance: Importance.high,
      playSound: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        alarmNumber,
        'Random Timer Alarm',
        'Alarm #$alarmNumber triggered!',
        platformDetails,
        payload: 'Alarm #$alarmNumber',
      );

      // Start animation
      _animationController.forward();
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }

  Widget _buildNumberSelector(String label, int value, NumberSetter onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => onChanged(value - 1)),
              icon: const Icon(Icons.remove_circle, color: Colors.white),
            ),
            Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18)),
            IconButton(
              onPressed: () => setState(() => onChanged(value + 1)),
              icon: const Icon(Icons.add_circle, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
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
                    _buildNumberSelector(
                      "Total Duration (s)",
                      _totalDuration,
                      (value) => _totalDuration = value.clamp(1, 3600),
                    ),
                    _buildNumberSelector(
                      "Occurrences",
                      _occurrences,
                      (value) => _occurrences = value.clamp(1, 100),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startOrStopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTimerRunning
                        ? const Color(0xFF8B0000) // Dark red color
                        : Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    _isTimerRunning ? "Stop Timer" : "Start Random Timer",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_completedAlarms > 0)
                  Text("Alarms Triggered: $_completedAlarms",
                      style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
