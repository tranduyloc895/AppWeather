import 'api_service.dart';
import 'session_manager.dart';

class WarningService {
  final ApiService _apiService;
  final SessionManager _sessionManager;
  bool _isChecking = false;

  WarningService(this._apiService, this._sessionManager);

  Future<void> checkWeatherWarnings(List<dynamic> weatherData) async {
    if (_isChecking || weatherData.isEmpty) return;
    _isChecking = true;

    try {
      final latestData = weatherData[0]; // Get the most recent weather data
      bool shouldSendAlert = false;
      String alertMessage = '';

      // Check temperature (using 'temp' field)
      final temperature = latestData['temp']?.toDouble();
      if (temperature != null && temperature > _sessionManager.temperatureThreshold) {
        shouldSendAlert = true;
        alertMessage += 'Temperature (${temperature.toStringAsFixed(1)}°C) exceeds threshold (${_sessionManager.temperatureThreshold}°C). ';
      }

      // Check humidity (using 'humid' field)
      final humidity = latestData['humid']?.toDouble();
      if (humidity != null && humidity > _sessionManager.humidityThreshold) {
        shouldSendAlert = true;
        alertMessage += 'Humidity (${humidity.toStringAsFixed(1)}%) exceeds threshold (${_sessionManager.humidityThreshold}%). ';
      }

      // Check pressure
      final pressure = latestData['pressure']?.toDouble();
      if (pressure != null && pressure > _sessionManager.pressureThreshold) {
        shouldSendAlert = true;
        alertMessage += 'Pressure (${pressure.toStringAsFixed(1)}Pa) exceeds threshold (${_sessionManager.pressureThreshold}Pa). ';
      }

      // Send alert if any threshold is exceeded
      if (shouldSendAlert && _sessionManager.userEmail != null) {
        print('Sending alert email for: $alertMessage');
        await _apiService.sendAlertEmail(
          tempThreshold: _sessionManager.temperatureThreshold,
          humidThreshold: _sessionManager.humidityThreshold,
          pressureThreshold: _sessionManager.pressureThreshold,
          emailTo: _sessionManager.userEmail!,
        );
      }
    } catch (e) {
      print('Error checking weather warnings: $e');
    } finally {
      _isChecking = false;
    }
  }
} 