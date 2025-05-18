import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';

class AssetDetailPage extends StatefulWidget {

  const AssetDetailPage({Key? key}) : super(key: key);

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  final ApiService _apiService = ApiService('http://3.107.212.93/api');

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
                        : SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height - 100, // Adjust based on padding/appbar height
                              ),
                              child: Column(
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
                                      _getWeatherStatus(_weatherData.last['pred']),
                                      style: TextStyle(color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
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
    
    // Map Zambretti numbers to status levels
    if ([1, 2, 10, 11, 20, 21, 22, 23, 24, 25, 26].contains(pred)) {
      predStatus = 'Normal';
      predColor = Colors.greenAccent;
    } else if ([3, 4, 12, 13, 14, 15, 16, 27, 28, 29].contains(pred)) {
      predStatus = 'Warning';
      predColor = Colors.yellowAccent;
    } else if ([5, 6, 7, 8, 9, 17, 18, 19, 30, 31, 32].contains(pred)) {
      predStatus = 'Danger';
      predColor = Colors.redAccent;
    } else {
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

  String _getWeatherStatus(int pred) {
    switch (pred) {
      case 1:
        return "Settled Fine: High pressure, clear skies, and calm conditions. Expect sunny weather with minimal cloud cover. Ideal for outdoor activities.";
      case 2:
        return "Fine Weather: Stable high pressure with mostly clear skies. Light winds and pleasant temperatures. Low chance of precipitation.";
      case 3:
        return "Fine, Becoming Less Settled: Initially clear but pressure starting to fall slightly. Clouds may increase later, with a small chance of light showers.";
      case 4:
        return "Mostly Fine, Showers Developing Later: Sunny intervals with increasing cloudiness. Scattered showers possible by evening, especially in hilly areas.";
      case 5:
        return "Showers, Becoming More Unsettled: Mixed weather with sunny spells and frequent showers. Pressure continues to drop, indicating worsening conditions.";
      case 6:
        return "Unsettled, Rain Later: Cloudy with occasional showers, becoming steadier rain by late day. Breezy conditions possible.";
      case 7:
        return "Rain at Times, Worse Later: Intermittent rain with short dry spells. Heavy rain likely by night as low pressure approaches.";
      case 8:
        return "Rain at Times, Becoming Very Unsettled: Persistent rain with brief pauses. Strong winds and cooler temperatures as a low pressure system deepens.";
      case 9:
        return "Very Unsettled, Rain: Continuous rain, possibly heavy, with gusty winds. Low pressure dominates, leading to poor visibility and wet conditions.";
      case 10:
        return "Settled Fine: Steady high pressure with clear or mostly clear skies. Warm and calm, with no significant precipitation expected.";
      case 11:
        return "Fine Weather: Stable weather with sunny periods. Light clouds may appear, but no major weather changes. Comfortable temperatures.";
      case 12:
        return "Fine, Possibly Showers: Mostly sunny but with a chance of isolated showers, especially in the afternoon. Light winds.";
      case 13:
        return "Fairly Fine, Showers Likely: Partly cloudy with frequent showers, some heavy. Bright intervals between showers. Moderate winds.";
      case 14:
        return "Showery, Bright Intervals: Frequent showers interspersed with sunny spells. Variable cloud cover and breezy conditions.";
      case 15:
        return "Changeable, Some Rain: Mixed weather with periods of rain and dry spells. Unpredictable conditions with moderate winds.";
      case 16:
        return "Unsettled, Rain at Times: Cloudy with occasional rain showers. Possible thunder in some areas. Windy at times.";
      case 17:
        return "Rain at Frequent Intervals: Persistent rain with short breaks. Cool and windy, with a risk of localized flooding.";
      case 18:
        return "Very Unsettled, Rain: Heavy, continuous rain with strong winds. Low pressure system brings prolonged wet and turbulent weather.";
      case 19:
        return "Stormy, Much Rain: Severe weather with heavy rain, strong gusts, and possible thunderstorms. Risk of flooding and disruptions.";
      case 20:
        return "Settled Fine: High pressure with clear skies, but early signs of change. Enjoy sunny weather while it lasts.";
      case 21:
        return "Fine Weather: Mostly sunny with stable conditions. Pressure starting to fall, hinting at changes within 24 hours.";
      case 22:
        return "Becoming Fine: Cloudy early but clearing to sunny spells as pressure stabilizes. Light winds and improving visibility.";
      case 23:
        return "Fairly Fine, Improving: Partly cloudy with occasional showers early, clearing later. Conditions gradually improving.";
      case 24:
        return "Fairly Fine, Possibly Showers Early: Mostly clear with a chance of morning showers. Brighter and drier by afternoon.";
      case 25:
        return "Showery Early, Improving: Morning showers giving way to sunny intervals. Pressure rising, signaling better weather.";
      case 26:
        return "Changeable, Mending: Mixed weather with showers and sunny spells. Conditions improving as pressure rises slightly.";
      case 27:
        return "Rather Unsettled, Clearing Later: Cloudy with rain early, but clearing to brighter skies by evening. Winds easing.";
      case 28:
        return "Unsettled, Probably Improving: Rain and clouds dominate early, with a trend toward clearer skies later. Variable winds.";
      case 29:
        return "Unsettled, Short Fine Intervals: Mostly rainy with brief sunny breaks. Pressure fluctuating, leading to changeable weather.";
      case 30:
        return "Very Unsettled, Finer at Times: Heavy rain with occasional dry spells. Strong winds and cooler temperatures.";
      case 31:
        return "Stormy, Possibly Improving: Severe weather with heavy rain and gusts, but signs of improvement as pressure begins to rise.";
      case 32:
        return "Stormy, Much Rain: Intense low pressure system with torrential rain and strong winds. Potential for flooding and storm damage.";
      default:
        return "Unknown: Invalid Zambretti number. Please provide a number between 1 and 32.";
    }
  }

  // InputDecoration _modernInputDecoration(String label) {
  //   // ... existing code ...
  // }
} 