class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _authToken;
  String? _userEmail;
  String? _username;
  
  // Warning threshold values
  double _temperatureThreshold = 25.0;
  double _humidityThreshold = 50.0;
  double _pressureThreshold = 100000.0;

  String? get authToken => _authToken;
  String? get userEmail => _userEmail;
  String? get username => _username;
  
  // Getters for warning thresholds
  double get temperatureThreshold => _temperatureThreshold;
  double get humidityThreshold => _humidityThreshold;
  double get pressureThreshold => _pressureThreshold;

  void setSessionData({
    required String token,
    required String email,
    required String username,
  }) {
    _authToken = token;
    _userEmail = email;
    _username = username;
  }

  void setWarningThresholds({
    required double temperature,
    required double humidity,
    required double pressure,
  }) {
    _temperatureThreshold = temperature;
    _humidityThreshold = humidity;
    _pressureThreshold = pressure;
  }

  void clearSession() {
    _authToken = null;
    _userEmail = null;
    _username = null;
    // Reset warning thresholds to default values
    _temperatureThreshold = 25.0;
    _humidityThreshold = 50.0;
    _pressureThreshold = 101325.0;
  }

  bool get isLoggedIn => _authToken != null;
} 