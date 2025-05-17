import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'session_manager.dart';
import 'warning_service.dart';

class HomePage extends StatefulWidget {

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService('http://10.0.2.2:8000/api');
  final SessionManager _sessionManager = SessionManager();
  late final WarningService _warningService;

  bool _isLoading = true;
  Map<String, dynamic> _sensorData = {
    'temperature': 'N/A',
    'humidity': 'N/A',
    'pressure': 'N/A',
    'lastUpdated': 'N/A'
  };

  @override
  void initState() {
    super.initState();
    _warningService = WarningService(_apiService, _sessionManager);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final weatherData = await _apiService.getWeatherDataDaily();
      if (weatherData.isNotEmpty) {
        final latestData = weatherData[0]; // Get the most recent data

        // Handle timestamp - it could be int (unix) or String (formatted)
        String formattedTimestamp = 'N/A';
        final timestamp = latestData['timestamp'];
        if (timestamp != null) {
          if (timestamp is int) {
            // Convert Unix timestamp (seconds) to DateTime and format
            final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            formattedTimestamp = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
          } else if (timestamp is String) {
            // Use the string directly if it's already formatted
            formattedTimestamp = timestamp;
          }
        }
        // Also check for 'formatted_timestamp' field if timestamp is not present or null
         else if (latestData['formatted_timestamp'] is String) {
            formattedTimestamp = latestData['formatted_timestamp'];
         }

        // Handle pressure value and unit scaling
        String pressureValue = 'N/A';
        final pressure = latestData['pressure']?.toDouble();
        if (pressure != null) {
          if (pressure >= 1000000) {
            pressureValue = '${(pressure / 1000000).toStringAsFixed(2)} MPa';
          } else if (pressure >= 1000) {
            pressureValue = '${(pressure / 1000).toStringAsFixed(1)} kPa';
          } else {
            pressureValue = '${pressure.toStringAsFixed(1)} hPa';
          }
        }


        setState(() {
          _sensorData = {
            'temperature': '${latestData['temp']?.toStringAsFixed(1) ?? 'N/A'}°C', // Use 'temp' field
            'humidity': '${latestData['humid']?.toStringAsFixed(1) ?? 'N/A'}%', // Use 'humid' field
            'pressure': pressureValue, // Use the dynamically formatted pressure value
            'lastUpdated': formattedTimestamp,
          };
        });

        // Check for warnings after updating the UI
        await _warningService.checkWeatherWarnings(weatherData);
      } else {
        // Clear data if no weather data is returned
         setState(() {
           _sensorData = {
             'temperature': 'N/A',
             'humidity': 'N/A',
             'pressure': 'N/A',
             'lastUpdated': 'N/A'
           };
         });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
       setState(() {
           _sensorData = {
             'temperature': 'Error',
             'humidity': 'Error',
             'pressure': 'Error',
             'lastUpdated': 'Error'
           };
         });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              Color(0xFF6DD5FA), // Light blue
              Color(0xFF2980F2), // Blue
              Color(0xFF8F6ED5), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sensor Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 36),
                      onPressed: _isLoading ? null : _fetchWeatherData,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : ListView(
                          children: [
                            _sensorCard(
                              'DHT11 Temperature',
                              _sensorData['temperature'],
                              _sensorData['lastUpdated'],
                              Icons.thermostat,
                            ),
                            _sensorCard(
                              'DHT11 Humidity',
                              _sensorData['humidity'],
                              _sensorData['lastUpdated'],
                              Icons.water_drop,
                            ),
                            _sensorCard(
                              'BMP180 Pressure',
                              _sensorData['pressure'],
                              _sensorData['lastUpdated'],
                              Icons.speed,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sensorCard(String name, String value, String date, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(icon, color: Colors.white, size: 28),
                radius: 28,
              ),
              title: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Last updated:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(date, style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
              trailing: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}