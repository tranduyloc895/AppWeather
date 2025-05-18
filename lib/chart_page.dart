import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';

class ChartPage extends StatefulWidget {

  const ChartPage({Key? key}) : super(key: key);

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final ApiService _apiService = ApiService('http://3.107.212.93/api');

  DateTime? _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime? _endDate = DateTime.now();
  String _selectedSensor = 'temperature';
  bool _isLoading = false;
  List<Map<String, dynamic>> _weatherData = [];
  String _errorMessage = '';
  String _pressureUnit = 'hPa'; // Default pressure unit
  double _pressureScale = 1.0; // Default pressure scale

  // Date formatters
  final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2980F2),
              onPrimary: Colors.white,
              onSurface: Colors.blue[900]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF2980F2)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
        _fetchWeatherData(); // Fetch data when dates are picked
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return _displayFormat.format(date);
  }

  Future<void> _fetchWeatherData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Format dates for API request
      final startDateStr = _apiFormat.format(_startDate!);
      final endDateStr = _apiFormat.format(_endDate!);

      final data = await _apiService.getWeatherDataByDateRange(
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      // Sort the data by timestamp in ascending order
      final sortedData = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) {
          final timestampA = a['timestamp'] is int 
              ? a['timestamp'] 
              : DateTime.parse(a['timestamp'].toString()).millisecondsSinceEpoch ~/ 1000;
          final timestampB = b['timestamp'] is int 
              ? b['timestamp'] 
              : DateTime.parse(b['timestamp'].toString()).millisecondsSinceEpoch ~/ 1000;
          return timestampA.compareTo(timestampB);
        });
      
      setState(() {
        _weatherData = sortedData;
        _updatePressureUnit(); // Update pressure unit after fetching data
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Determine the pressure unit and scale based on data
  void _updatePressureUnit() {
    if (_selectedSensor == 'pressure' && _weatherData.isNotEmpty) {
      final maxPressure = _weatherData
          .map((data) => data['pressure']?.toDouble() ?? 0)
          .reduce((a, b) => a > b ? a : b);

      if (maxPressure >= 1000000) {
        _pressureUnit = 'MPa';
        _pressureScale = 1000000.0;
      } else if (maxPressure >= 1000) {
        _pressureUnit = 'kPa';
        _pressureScale = 1000.0;
      } else {
        _pressureUnit = 'hPa';
        _pressureScale = 1.0;
      }
    } else {
      _pressureUnit = 'hPa';
      _pressureScale = 1.0;
    }
  }

  List<FlSpot> _getChartData() {
    if (_weatherData.isEmpty) return [];

    return List.generate(_weatherData.length, (index) {
      final data = _weatherData[index];
      double value = 0;
      
      switch (_selectedSensor) {
        case 'temperature':
          value = data['temp']?.toDouble() ?? 0;
          break;
        case 'humidity':
          value = data['humid']?.toDouble() ?? 0;
          break;
        case 'pressure':
          // Scale pressure value and subtract offset
          value = ((data['pressure']?.toDouble() ?? 100000) - 100000) / _pressureScale;
          break;
        default:
          value = 0; // Should not happen with current sensors
      }

      return FlSpot(index.toDouble(), value);
    });
  }

  String _getYAxisTitle() {
    switch (_selectedSensor) {
      case 'temperature':
        return 'Temperature (°C)';
      case 'humidity':
        return 'Humidity (%)';
      case 'pressure':
        // Indicate offset and dynamic unit
        final offsetValue = (100000 / _pressureScale).toStringAsFixed(0);
        return 'Pressure ($_pressureUnit - ${offsetValue} $_pressureUnit)';
      default:
        return '';
    }
  }

  Widget _buildChart() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: TextStyle(color: Colors.red[300]),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_weatherData.isEmpty) {
      return Center(
        child: Text(
          'No data available for the selected date range',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Calculate min and max values for Y-axis
    final values = _weatherData.map((data) {
      switch (_selectedSensor) {
        case 'temperature':
          return data['temp']?.toDouble() ?? 0;
        case 'humidity':
          return data['humid']?.toDouble() ?? 0;
        case 'pressure':
          // Scale pressure value and subtract offset for calculation
          return ((data['pressure']?.toDouble() ?? 100000) - 100000) / _pressureScale;
        default:
          return 0;
      }
    }).toList();

    // Handle case with single or zero data points
    double minValue;
    double maxValue;
    if (values.isEmpty) {
      minValue = 0;
      maxValue = 10; // Default range
    } else if (values.length == 1) {
      // Provide a small range around the single value, ensuring it's not zero range
      minValue = values[0] - (values[0] * 0.1).abs() - 1; // 10% of value plus 1
      maxValue = values[0] + (values[0] * 0.1).abs() + 1; // 10% of value plus 1
       if (minValue == maxValue) {
        minValue -= 5;
        maxValue += 5;
      }
    } else {
      minValue = values.reduce((a, b) => a < b ? a : b);
      maxValue = values.reduce((a, b) => a > b ? a : b);
    }
    
    // Calculate padding and intervals
    final range = maxValue - minValue;
    final padding = range * 0.1; // 10% padding
    final minY = (minValue - padding).floorToDouble();
    final maxY = (maxValue + padding).ceilToDouble();
    
    // Calculate appropriate interval based on range
    double interval;
    if (range <= 0.5) {
      interval = 0.05; // Smaller intervals for very small ranges
    } else if (range <= 1) {
      interval = 0.1;
    } else if (range <= 5) {
      interval = 0.5;
    } else if (range <= 10) {
      interval = 1;
    } else if (range <= 50) {
      interval = 5;
    } else if (range <= 100) {
      interval = 10;
    } else if (range <= 500) {
       interval = 50;
    } else if (range <= 1000) {
       interval = 100;
    }else {
      interval = (range / 10).ceilToDouble();
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: interval,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (_weatherData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _weatherData.length) return Text('');
                final timestamp = _weatherData[value.toInt()]['timestamp'];
                final date = timestamp is int 
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
                    : DateTime.parse(timestamp.toString());
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Display offset and scaled value with appropriate precision
                String displayValue;
                 if (_selectedSensor == 'pressure') {
                  final actualValue = value * _pressureScale + 100000;
                  displayValue = actualValue.toStringAsFixed(0); // Always show integer for pressure
                } else { // Temperature or Humidity
                  displayValue = value.toStringAsFixed(1); // Keep one decimal for temp/humidity
                }

                return SizedBox(
                  width: 60, // Tăng width để đủ chỗ cho 6 số
                  child: Text(
                    displayValue,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.visible, // Đảm bảo không bị cắt
                    softWrap: false, // Không tự động xuống dòng
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: (_weatherData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _getChartData(),
            isCurved: true,
            color: Colors.white,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade700,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String valueStr;
                if (_selectedSensor == 'pressure') {
                  final actualValue = spot.y * _pressureScale + 100000;
                  valueStr = actualValue.toStringAsFixed(0); // Áp suất luôn dương
                } else {
                  valueStr = spot.y.toStringAsFixed(1);
                }
                return LineTooltipItem(
                  valueStr,
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure background is transparent
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
            padding: const EdgeInsets.all(16.0),
            child: ListView( // Wrap the Column with ListView for scrollability
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.show_chart, color: Colors.white, size: 32),
                        SizedBox(width: 10),
                        Text(
                          'Statistics',
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSensor,
                            decoration: _modernInputDecoration('Sensor Type'),
                            items: [
                              DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
                              DropdownMenuItem(value: 'humidity', child: Text('Humidity')),
                              DropdownMenuItem(value: 'pressure', child: Text('Pressure')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSensor = value;
                                });
                              }
                            },
                            dropdownColor: Colors.blue[400],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row for date pickers - Replaced with _buildDatePickerRow()
                    _buildDatePickerRow(), // Using the dedicated row builder
                    const SizedBox(height: 20),
                    // Wrap the chart card with a SizedBox to give it a fixed height
                    SizedBox(
                      height: 360, // Tăng chiều cao
                      width: double.infinity, // Tăng chiều rộng tối đa theo parent
                      child: _glassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0), // Tăng padding cho đẹp
                          child: _buildChart(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchWeatherData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
                                      ),
                                    )
                                  : Text(
                                      'SHOW CHART',
                                      style: TextStyle(
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.redAccent, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(isStart: true),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: _modernInputDecoration('Start Date'),
                style: TextStyle(color: Colors.white),
                readOnly: true,
                controller: TextEditingController(text: _formatDate(_startDate)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(isStart: false),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: _modernInputDecoration('End Date'),
                style: TextStyle(color: Colors.white),
                readOnly: true,
                controller: TextEditingController(text: _formatDate(_endDate)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
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
          child: child,
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.18),
      labelStyle: TextStyle(color: Colors.white),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }
}