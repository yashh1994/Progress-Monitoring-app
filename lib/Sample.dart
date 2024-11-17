import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class TimeTracker extends StatefulWidget {
  @override
  _TimeTrackerState createState() => _TimeTrackerState();
}

class _TimeTrackerState extends State<TimeTracker> with WidgetsBindingObserver {
  late SharedPreferences prefs;
  bool isSessionActive = false;
  int sessionTime = 0;
  int? sessionStartTime;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    _loadSessionState();
  }

  void _toggleSession() {
    setState(() {
      if (isSessionActive) {
        _stopSession();
      } else {
        _startSession();
      }
    });
  }

  void _startSession() {
    sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    isSessionActive = true;
    _saveSessionState();
    _startTimer();
  }

  void _stopSession() {
    //_addElapsedTime();
    _updateDailyProgress();
    isSessionActive = false;
    _saveSessionState();
    timer.cancel();
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (isSessionActive) {
          sessionTime++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _addElapsedTime() {
    if (isSessionActive && sessionStartTime != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      //sessionTime += (currentTime - sessionStartTime!);
      sessionStartTime = null;
      _updateDailyProgress();
    }
  }

  void _updateDailyProgress() {
    String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    Map<String, int> dailySessions = _getStoredSessions();
    dailySessions[today] = (dailySessions[today] ?? 0) + sessionTime;
    prefs.setString('sessions', jsonEncode(dailySessions));
  }

  Map<String, int> _getStoredSessions() {
    String? storedData = prefs.getString('sessions');
    if (storedData == null) return {};
    return Map<String, int>.from(jsonDecode(storedData));
  }

  Future<void> _loadSessionState() async {
    isSessionActive = prefs.getBool('isSessionActive') ?? false;
    sessionTime = prefs.getInt('sessionTime') ?? 0;
    int? lastSavedTime = prefs.getInt('lastSavedTime');
    if (isSessionActive && lastSavedTime != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      sessionTime += (currentTime - lastSavedTime);
      _startTimer();
    }
    setState(() {});
  }

  Future<void> _saveSessionState() async {
    await prefs.setBool('isSessionActive', isSessionActive);
    await prefs.setInt('sessionTime', sessionTime);
    if (isSessionActive) {
      await prefs.setInt(
          'lastSavedTime', DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    seconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer.cancel();
    _addElapsedTime();
    _saveSessionState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _addElapsedTime();
      _saveSessionState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Time Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isSessionActive ? Colors.green : Colors.deepPurple,
        elevation: 4,
      ),
      body: GestureDetector(
        onTap: _toggleSession,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSessionActive ? [Colors.green, Colors.greenAccent] : [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(sessionTime),
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Digital',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  isSessionActive ? 'Session Active' : 'Tap to Start Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
