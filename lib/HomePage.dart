import 'package:flutter/material.dart';
import 'package:progress_monitoring/SessionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';


void customPrint(String message){
  debugPrint('DEBUGYASH: ${message}');
}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isSessionActive = false;
  int sessionTime = 0;
  late SharedPreferences prefs;
  late Timer timer;
  int? sessionStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    customPrint("Start the State");
    _initializeStorage();
    _loadSessionState();
  }

  // Initialize SharedPreferences
  Future<void> _initializeStorage() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Load session state and elapsed time from SharedPreferences
  Future<void> _loadSessionState() async {
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    Map<String, int> dailySessions = _getStoredSessions();

    // Load the last session state
    // int? storedSessionTime = prefs.getInt('lastSessionTime') ?? 0;
    bool storedSessionStatus = prefs.getBool('isSessionActive') ?? false;
    int lastTimeToClose = prefs.getInt('timeToClose') ?? 0;
    sessionTime = dailySessions[today] ?? 0;

    int currentTimeInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (storedSessionStatus == true) {
      isSessionActive = true;
      sessionTime += (currentTimeInSeconds - lastTimeToClose);
    }
    _startTimer();
  }

  // Start or stop the session
  void _toggleSession() {
    setState(() {
      if (isSessionActive) {
        _saveSessionState();
      } else {
        _startTimer();
      }
      isSessionActive = !isSessionActive;
    });
    _saveSessionState();
  }

  // Periodically update the UI while the stopwatch is running
  void _startTimer() {
    sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (isSessionActive) {
          sessionTime += 1;
        }
        _saveSessionState();
      });
    });
  }


  // Save session state (whether it's active or not) to SharedPreferences
  Future<void> _saveSessionState() async {
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    Map<String, int> dailySessions = _getStoredSessions();
    dailySessions[today] = sessionTime;
    await prefs.setBool('isSessionActive', isSessionActive);
    await prefs.setString('timeToClose',
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString());
    await prefs.setString('sessions', jsonEncode(dailySessions));
  }

  // Get stored session data from SharedPreferences
  Map<String, int> _getStoredSessions() {
    String? storedData = prefs.getString('sessions');
    if (storedData == null) return {};
    return Map<String, int>.from(jsonDecode(storedData));
  }

  // Format the time (hours:minutes:seconds)
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    seconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      customPrint("State is Stopped");
      _saveSessionState(); // Save session when app goes to background
    }
  }

  @override
  void dispose() {
    timer.cancel();

    _saveSessionState();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SessionRecordsScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(sessionTime),
              style: TextStyle(
                fontSize: 48,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleSession,
              child: Text(isSessionActive ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
