import 'dart:async';
import 'package:flutter/material.dart';

// Static offline variables
const String appTitle = 'Offline Clock App';
const String offlineStatus = 'Status: Offline Mode';
const String appVersion = 'v1.0.0';
const int offlineSun = 5;

void main() => runApp(const MaterialApp(
      home: OfflineWidget(),
    ));

enum ClockState { clockAndSun, sunInput, compassNorth }

class OfflineWidget extends StatefulWidget {
  final DateTime Function()? timeProvider;
  final double Function()? compassProvider;

  const OfflineWidget({
    super.key,
    this.timeProvider,
    this.compassProvider,
  });

  @override
  State<OfflineWidget> createState() => _OfflineWidgetState();
}

class _OfflineWidgetState extends State<OfflineWidget> {
  late Timer _timer;
  late DateTime _currentTime;
  
  // Three states management
  ClockState _currentState = ClockState.clockAndSun;
  double _sunClockHours = 12.0; // State 2: Sun direction represented in clock units (0 - 24 hours)
  final TextEditingController _sunController = TextEditingController(text: '12.0');

  DateTime get _now {
    final raw = widget.timeProvider != null ? widget.timeProvider!() : DateTime.now();
    return raw.toUtc().add(const Duration(hours: 8));
  }

  double get _physicalNorth {
    return widget.compassProvider != null ? widget.compassProvider!() : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _currentTime = _now;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _now;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double physicalNorthHeading = _physicalNorth;

    // State 2 sun direction in clock units mapped to azimuth A_sun (1 hour = 15°)
    final double sunAzimuth = _sunClockHours * 15.0;
    final double sunElevation = 90.0 - (((_currentTime.hour - 12).abs()) * 7.5);

    // Hour hand angle H = 30 * (h + m/60)
    final double hValue = (_currentTime.hour % 12) + (_currentTime.minute / 60.0) + (_currentTime.second / 3600.0);
    final double H = 30.0 * hValue;

    // CORRECTED SOLAR NAVIGATION FORMULA FOR NORTH: Anorth = (Asun - H/2) mod 360
    final double northDirection = ((sunAzimuth - (H / 2.0)) % 360.0 + 360.0) % 360.0;

    // Format clock representation (HH:MM:SS)
    final String timeString =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // State Selector Bar (Three States)
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStateButton('1. Clock & Sun', ClockState.clockAndSun),
                _buildStateButton('2. Sun Input', ClockState.sunInput),
                _buildStateButton('3. Compass North', ClockState.compassNorth),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStateView(timeString, physicalNorthHeading, sunAzimuth, sunElevation, northDirection, H),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateButton(String label, ClockState state) {
    final bool isSelected = _currentState == state;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFD4AF37) : Colors.grey[800],
        foregroundColor: isSelected ? Colors.black : Colors.white,
      ),
      onPressed: () {
        setState(() {
          _currentState = state;
        });
      },
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCurrentStateView(
    String timeString,
    double physicalNorthHeading,
    double sunAzimuth,
    double sunElevation,
    double northDirection,
    double H,
  ) {
    switch (_currentState) {
      case ClockState.clockAndSun:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny, size: 64, color: Colors.amber),
            const SizedBox(height: 10),
            Text('Sun Intensity: $offlineSun', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              'Sun Vector (Asun: ${sunAzimuth.toStringAsFixed(1)}°, H: ${H.toStringAsFixed(1)}°): Elev ${sunElevation.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 14, color: Colors.amber, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LuxuryCircularClock(
              timeString: timeString,
              northAngle: northDirection,
            ),
            const SizedBox(height: 20),
            Text(offlineStatus, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            const Text('App Version: $appVersion', style: TextStyle(color: Colors.grey)),
          ],
        );

      case ClockState.sunInput:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sun Direction Input Mode',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter sun direction in clock units (Solar Hours 0.0 - 24.0h):\n(1 hour = 15° Azimuth)',
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // Light container background for black text in State 2
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 250,
                child: TextField(
                  controller: _sunController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18), // Input text color as black
                  decoration: InputDecoration(
                    labelText: 'Sun Clock Units (Hours)',
                    labelStyle: const TextStyle(color: Colors.black87),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _sunClockHours = double.tryParse(value) ?? _sunClockHours;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: () {
                setState(() {
                  _sunClockHours = double.tryParse(_sunController.text) ?? _sunClockHours;
                });
              },
              child: const Text('Apply Sun Clock Units', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            Text(
              'Active Sun Clock Units: ${_sunClockHours.toStringAsFixed(1)}h (Asun: ${sunAzimuth.toStringAsFixed(1)}°)',
              style: const TextStyle(fontSize: 18, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case ClockState.compassNorth:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Compass North Calibration Mode',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.explore, size: 48, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  Text(
                    'Calculated Corrected Anorth: ${northDirection.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Corrected Solar Navigation Formula:\nAnorth = (Asun - H/2) mod 360\n= (${sunAzimuth.toStringAsFixed(1)}° - ${(H / 2.0).toStringAsFixed(1)}°) mod 360\n= ${northDirection.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // State 3 clock utilizing the corrected solar navigation formula
            LuxuryCircularClock(
              timeString: timeString,
              northAngle: northDirection,
            ),
          ],
        );
    }
  }
}

class LuxuryCircularClock extends StatelessWidget {
  final String timeString;
  final double northAngle;

  const LuxuryCircularClock({
    super.key,
    required this.timeString,
    required this.northAngle,
  });

  @override
  Widget build(BuildContext context) {
    final double angleInRadians = northAngle * (3.141592653589793 / 180.0);

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E), Color(0xFF000000)],
          stops: [0.2, 0.7, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(12, (index) {
            final angle = index * (3.141592653589793 / 6);
            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: index % 3 == 0 ? 3 : 1.5,
                  height: index % 3 == 0 ? 12 : 8,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            );
          }),
          // North Vector Transformed Indicator Needle
          Transform.rotate(
            angle: angleInRadians,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 15,
                  child: Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // North 'N' marker
                const Positioned(
                  top: 2,
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Center Core & Luxury Digital Time Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LUXURY',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFFD4AF37),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
