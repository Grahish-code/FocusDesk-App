import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveBatteryWidget extends StatefulWidget {
  const LiveBatteryWidget({super.key});

  @override
  State<LiveBatteryWidget> createState() => _LiveBatteryWidgetState();
}

class _LiveBatteryWidgetState extends State<LiveBatteryWidget> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _levelTimer;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  void _initBattery() {
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() => _batteryState = state);
        _getBatteryLevel();
      }
    });

    _getBatteryLevel();

    _levelTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => _getBatteryLevel(),
    );
  }

  Future<void> _getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (e) {
      debugPrint("Battery Error: $e");
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$_batteryLevel%",
          style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18),
        ),
        const SizedBox(width: 5),
        Icon(
          _batteryState == BatteryState.charging
              ? Icons.battery_charging_full
              : _batteryLevel > 80
              ? Icons.battery_full
              : _batteryLevel > 50
              ? Icons.battery_5_bar
              : _batteryLevel > 20
              ? Icons.battery_3_bar
              : Icons.battery_alert,
          color: (_batteryLevel < 20 &&
              _batteryState != BatteryState.charging)
              ? Colors.redAccent
              : Colors.cyanAccent,
        ),
      ],
    );
  }
}