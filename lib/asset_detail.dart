import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';

class AssetDetailPage extends StatefulWidget {

  const AssetDetailPage({Key? key}) : super(key: key);

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  final ApiService _apiService = ApiService('http://10.0.2.2:8000/api');

  bool _isLoading = true;
  List<dynamic> _weatherData = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _apiService.getWeatherDataDaily();
      setState(() {
        _weatherData = data;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('Không có dữ liệu nào thuộc hôm nay')) {
           _errorMessage = 'No data available for today';
        } else {
           _errorMessage = 'Error fetching data: ${e.toString()}';
        }
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
              Color(0xFF6DD5FA),
              Color(0xFF2980F2),
              Color(0xFF8F6ED5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red[300]), textAlign: TextAlign.center))
                    : _weatherData.isEmpty
                        ? Center(child: Text('No data available', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Latest Weather Data',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      shadows: [
                                        Shadow(color: Colors.black26, blurRadius: 8),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(Icons.cloud, color: Colors.white, size: 36),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildWeatherDataDisplay(_weatherData.last),
                              const SizedBox(height: 16),
                              _glassCard(
                                child: Text(
                                  "Good afternoon! It's a perfect time to be outside. Here is the latest sensor data.",
                                  style: TextStyle(color: Colors.white, fontSize: 17),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView(
                                  children: [
                                    // These will be built by _buildWeatherDataDisplay
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

  Widget _buildWeatherDataDisplay(Map<String, dynamic> data) {
    final temp = data['temp']?.toStringAsFixed(1) ?? 'N/A';
    final humid = data['humid']?.toStringAsFixed(1) ?? 'N/A';
    
    // Handle pressure value and unit scaling
    String pressureValue = 'N/A';
    final pressure = data['pressure']?.toDouble();
    if (pressure != null) {
      if (pressure >= 1000000) {
        pressureValue = '${(pressure / 1000000).toStringAsFixed(2)} MPa';
      } else if (pressure >= 1000) {
        pressureValue = '${(pressure / 1000).toStringAsFixed(1)} kPa';
      } else {
        pressureValue = '${pressure.toStringAsFixed(1)} hPa';
      }
    }

    final pred = data['pred'] ?? -1;

    String predStatus;
    Color predColor;
    switch (pred) {
      case 0:
        predStatus = 'Normal';
        predColor = Colors.greenAccent;
        break;
      case 1:
        predStatus = 'Warning';
        predColor = Colors.yellowAccent;
        break;
      case 2:
        predStatus = 'Danger';
        predColor = Colors.redAccent;
        break;
      default:
        predStatus = 'Unknown';
        predColor = Colors.white70;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Temperature',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
            Text(
              '$temp°C',
              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black26, blurRadius: 6)]),
            ),
            Icon(Icons.thermostat, color: Colors.white, size: 28),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: ${data['formatted_timestamp'] ?? 'N/A'}',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 16),
        _infoCard(Icons.water_drop, 'Humidity', '$humid%', 'Actual value: $humid%'),
        _infoCard(Icons.speed, 'Pressure', pressureValue, 'Actual value: ${data['pressure']?.toStringAsFixed(1) ?? 'N/A'} hPa'),
        _infoCard(Icons.warning_amber, 'Prediction Status', predStatus, 'Prediction value: $pred', valueColor: predColor),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value, String sub, {Color? valueColor}) {
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
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(icon, color: Colors.white, size: 28),
                radius: 26,
              ),
              title: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(sub, style: TextStyle(color: Colors.white70, fontSize: 14)),
              trailing: Text(
                value,
                style: TextStyle(color: valueColor ?? Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black26, blurRadius: 6)]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // InputDecoration _modernInputDecoration(String label) {
  //   // ... existing code ...
  // }
} 