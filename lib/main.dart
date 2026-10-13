import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Static offline variables
const String appTitle = 'Offline Clock App';
const String offlineStatus = 'Status: Offline Mode';
const String appVersion = 'v1.0.0';
const int offlineSun = 5;

void main() => runApp(const MaterialApp(
      home: OfflineWidget(),
    ));

/// Mathematical Object: SunDialRing inheriting/implementing Iterable<int>
/// modeling the finite cyclic group (Z/12Z) for sun dial numbers rotation.
class SunDialRing extends Iterable<int> {
  final int modulus;
  final int currentOffset;

  const SunDialRing({this.modulus = 12, this.currentOffset = 0});

  @override
  Iterator<int> get iterator => _SunDialIterator(modulus, currentOffset);

  SunDialRing rotate(int steps) {
    final newOffset = (currentOffset + steps) % modulus;
    return SunDialRing(
      modulus: modulus,
      currentOffset: newOffset < 0 ? newOffset + modulus : newOffset,
    );
  }
}

class _SunDialIterator implements Iterator<int> {
  final int modulus;
  final int offset;
  int _currentIndex = -1;

  _SunDialIterator(this.modulus, this.offset);

  @override
  int get current => ((_currentIndex + offset) % modulus) + 1; // 1 to 12

  @override
  bool moveNext() {
    _currentIndex++;
    return _currentIndex < modulus;
  }
}

enum ClockState { clockAndSun, sunInput, compassNorth, comparison }

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
  
  // Four states management
  ClockState _currentState = ClockState.clockAndSun;
  double _sunClockHours = 12.0; // State 2: Sun direction represented in clock units (0 - 24 hours)
  final TextEditingController _sunController = TextEditingController(text: '12.0');

  // Live physical sensor heading via sensors_plus
  double _sensorHeading = 0.0;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  DateTime get _now {
    final raw = widget.timeProvider?.call() ?? DateTime.now();
    return raw.toUtc().add(const Duration(hours: 8));
  }

  double get _physicalNorth => widget.compassProvider?.call() ?? _sensorHeading;

  @override
  void initState() {
    super.initState();
    _currentTime = _now;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _now;
      });
    });

    // Listen to physical magnetometer events with an input/output smoothing filter loop
    try {
      _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
        double rawHeading = (math.atan2(event.y, event.x) * (180.0 / math.pi) + 180.0) % 360.0;
        if (rawHeading < 0) {
          rawHeading += 360.0;
        }
        setState(() {
          _sensorHeading = (_sensorHeading * 0.8) + (rawHeading * 0.2);
        });
      });
    } catch (_) {
      // Fallback if sensors are not supported on current platform (e.g. desktop/tests)
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _sunController.dispose();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double physicalNorthHeading = _physicalNorth;

    // State 2 sun direction in clock units mapped to azimuth A_sun (1 hour = 15°)
    final double sunAzimuth = _sunClockHours * 15.0;
    // Clock face dial rotation angle corresponding to sun clock input (30° per clock hour on 12-hour dial)
    final double sunClockDialAngle = _sunClockHours * 30.0;
    final double sunElevation = 90.0 - (((_currentTime.hour - 12).abs()) * 7.5);

    // Hour hand angle H = 30 * (h + m/60)
    final double hValue = (_currentTime.hour % 12) + (_currentTime.minute / 60.0) + (_currentTime.second / 3600.0);
    final double H = 30.0 * hValue;

    // WATCH DIAL METHOD FORMULAS:
    // South is halfway between hour hand H and 12 o'clock (0°) -> Asouth = (Asun - H/2) mod 360
    final double southDirection = ((sunAzimuth - (H / 2.0)) % 360.0 + 360.0) % 360.0;
    // North is the opposite direction of South -> Anorth = (Asouth + 180) mod 360
    final double northDirection = ((southDirection + 180.0) % 360.0 + 360.0) % 360.0;

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
          // State Selector Bar (Four States)
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStateButton('1. Clock & Sun', ClockState.clockAndSun),
                  const SizedBox(width: 6),
                  _buildStateButton('2. Sun Input', ClockState.sunInput),
                  const SizedBox(width: 6),
                  _buildStateButton('3. Compass North', ClockState.compassNorth),
                  const SizedBox(width: 6),
                  _buildStateButton('4. North Compare', ClockState.comparison),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStateView(timeString, physicalNorthHeading, sunAzimuth, sunClockDialAngle, sunElevation, northDirection, southDirection, H),
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
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCurrentStateView(
    String timeString,
    double physicalNorthHeading,
    double sunAzimuth,
    double sunClockDialAngle,
    double sunElevation,
    double northDirection,
    double southDirection,
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
              'Enter sun direction in clock units (Solar Hours 0.0 - 24.0h):\n(1 hour = 30° Clock Dial / 15° Azimuth)',
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
              'Active Sun Clock Units: ${_sunClockHours.toStringAsFixed(1)}h (Dial Angle: ${sunClockDialAngle.toStringAsFixed(1)}°)',
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
                    'Live Physical Compass North: ${physicalNorthHeading.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Watch Dial Method (Cinematic sun alignment ${_sunClockHours.toStringAsFixed(1)}h):\nAsouth = Asun - H/2 = ${southDirection.toStringAsFixed(1)}°\nAnorth = Asouth + 180 = ${northDirection.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // State 3 clock with cinematic 3D tilt/pan, golden sunlight, and sun clock dial alignment
            LuxuryCircularClock(
              timeString: timeString,
              northAngle: northDirection,
              sunAzimuth: sunClockDialAngle,
            ),
          ],
        );

      case ClockState.comparison:
        final double deltaNorth = (physicalNorthHeading - northDirection).abs();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Watch Dial Method: North Compare',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Live Sensor Compass North (Blue P):', style: TextStyle(color: Colors.white70)),
                      Text('${physicalNorthHeading.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Watch Dial South (Asun - H/2):', style: TextStyle(color: Colors.white70)),
                      Text('${southDirection.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Watch Dial North (Red N):', style: TextStyle(color: Colors.white70)),
                      Text('${northDirection.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Variance / Delta:', style: TextStyle(color: Colors.white70)),
                      Text('${deltaNorth.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Error Warning Card based on watch dial accuracy limitations
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Accuracy Limitations & Error Warning',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Local Time vs. Zone Time discrepancy\n• Equation of Time (Solar time vs. Mean solar time)\n• Non-uniform change of Sun azimuth near tropics',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // State 4 clock with cinematic 3D tilt/pan, golden sunlight, dual vectors, and sun clock dial alignment
            LuxuryCircularClock(
              timeString: timeString,
              northAngle: northDirection,
              physicalNorthAngle: physicalNorthHeading,
              sunAzimuth: sunClockDialAngle,
            ),
          ],
        );
    }
  }
}

class LuxuryCircularClock extends StatefulWidget {
  final String timeString;
  final double northAngle;
  final double? physicalNorthAngle;
  final double? sunAzimuth;

  const LuxuryCircularClock({
    super.key,
    required this.timeString,
    required this.northAngle,
    this.physicalNorthAngle,
    this.sunAzimuth,
  });

  @override
  State<LuxuryCircularClock> createState() => _LuxuryCircularClockState();
}

class _LuxuryCircularClockState extends State<LuxuryCircularClock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds cinematic transition
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    if (widget.sunAzimuth != null) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LuxuryCircularClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sunAzimuth != oldWidget.sunAzimuth && widget.sunAzimuth != null) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double targetDialRotation = widget.sunAzimuth != null
        ? widget.sunAzimuth! * (math.pi / 180.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final double progress = _anim.value;
        // Cinematic 3D tilt & pan
        final double tilt = (1.0 - progress) * 0.35;
        final double pan = (1.0 - progress) * 0.2;
        final double currentDialRotation = progress * targetDialRotation;

        final double angleInRadians = widget.northAngle * (math.pi / 180.0);
        final double? physicalAngleInRadians = widget.physicalNorthAngle != null
            ? widget.physicalNorthAngle! * (math.pi / 180.0)
            : null;

        // Instantiate SunDialRing mathematical object (Iterable<int> Z/12Z)
        final SunDialRing dialRing = const SunDialRing(modulus: 12);
        final List<int> hours = dialRing.toList();

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(tilt)
            ..rotateY(pan),
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(const Color(0xFF3C3C3E), const Color(0xFF4C3C1E), progress)!,
                  Color.lerp(const Color(0xFF1C1C1E), const Color(0xFF2C1E0A), progress)!,
                  Color.lerp(const Color(0xFF000000), const Color(0xFF140C02), progress)!,
                ],
                stops: const [0.2, 0.7, 1.0],
              ),
              border: Border.all(
                color: Color.lerp(const Color(0xFFD4AF37), const Color(0xFFFFD700), progress)!,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3 * progress),
                  blurRadius: 25 * progress + 10,
                  spreadRadius: 8 * progress + 3,
                ),
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
                // Cinematic rotating clock dial using SunDialRing approaching sun direction
                Transform.rotate(
                  angle: currentDialRotation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...hours.map((hour) {
                        final index = hour == 12 ? 0 : hour;
                        final angle = index * (math.pi / 6);
                        return Transform.rotate(
                          angle: angle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: hour % 3 == 0 ? 3 : 1.5,
                              height: hour % 3 == 0 ? 12 : 8,
                              color: Color.lerp(const Color(0xFFD4AF37), const Color(0xFFFFE082), progress),
                            ),
                          ),
                        );
                      }),
                      ...hours.map((hour) {
                        final index = hour == 12 ? 0 : hour;
                        final angle = index * (math.pi / 6);
                        return Transform.rotate(
                          angle: angle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14.0),
                              child: Transform.rotate(
                                angle: -angle,
                                child: Text(
                                  '$hour',
                                  style: TextStyle(
                                    color: Color.lerp(const Color(0xFFD4AF37), const Color(0xFFFFE082), progress),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Red Calculated North Vector Transformed Indicator Needle
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
                // Blue Physical North Vector Transformed Indicator Needle (if provided in State 4)
                if (physicalAngleInRadians != null)
                  Transform.rotate(
                    angle: physicalAngleInRadians,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 20,
                          child: Container(
                            width: 3.5,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 4,
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
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
                        widget.timeString,
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
          ),
        );
      },
    );
  }
}
