import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';
import 'login.dart';
import 'session_manager.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ApiService _apiService = ApiService('http://10.0.2.2:8000/api');
  final _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    // Initialize slider values from session manager
    temperatureValue = _sessionManager.temperatureThreshold;
    humidityValue = _sessionManager.humidityThreshold;
    pressureValue = _sessionManager.pressureThreshold;
  }

  late double temperatureValue;
  late double humidityValue;
  late double pressureValue;

  void _handleLogout() {
    _sessionManager.clearSession();
    _apiService.clearAuthToken();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _updateWarningThresholds() {
    _sessionManager.setWarningThresholds(
      temperature: temperatureValue,
      humidity: humidityValue,
      pressure: pressureValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6DD5FA),
              Color(0xFF2980F2),
              Color(0xFF8F6ED5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 32),
                    SizedBox(width: 10),
                    Text(
                      'Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('ACCOUNT', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                _glassInfoTile('Email', _sessionManager.userEmail ?? '', Icons.email),
                _glassInfoTile('Username', _sessionManager.username ?? '', Icons.person),
                const SizedBox(height: 24),
                Text('WARNING SETTINGS', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                _glassSliderTile(
                  'Temperature',
                  temperatureValue,
                  0,
                  100,
                  '°C',
                  Icons.thermostat,
                  (value) {
                    setState(() {
                      temperatureValue = value;
                      _updateWarningThresholds();
                    });
                  },
                ),
                _glassSliderTile(
                  'Humidity',
                  humidityValue,
                  0,
                  100,
                  '%',
                  Icons.water_drop,
                  (value) {
                    setState(() {
                      humidityValue = value;
                      _updateWarningThresholds();
                    });
                  },
                ),
                _glassSliderTile(
                  'Pressure',
                  pressureValue,
                  10000,
                  200000,
                  'Pa',
                  Icons.speed,
                  (value) {
                    setState(() {
                      pressureValue = value;
                      _updateWarningThresholds();
                    });
                  },
                ),
                const SizedBox(height: 24),
                _glassInfoTile('Log out', 'Log out of your account', Icons.logout, trailing: null, isLogout: true, onTap: _handleLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassInfoTile(String title, String value, IconData icon, {Widget? trailing, bool isLogout = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isLogout ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(icon, color: Colors.white, size: 24),
                radius: 22,
              ),
              title: Text(title, style: TextStyle(color: isLogout ? Colors.red[200] : Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: value.isNotEmpty ? Text(value, style: TextStyle(color: Colors.white70, fontSize: 14)) : null,
              trailing: trailing,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassSliderTile(String title, double value, double min, double max, String unit, IconData icon, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Icon(icon, color: Colors.white, size: 24),
                        radius: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${value.toStringAsFixed(1)}$unit',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                      valueIndicatorColor: Colors.white,
                      valueIndicatorTextStyle: TextStyle(color: Colors.black87),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: 100,
                      label: '${value.toStringAsFixed(1)}$unit',
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 