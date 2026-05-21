import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/parking_spot.dart';
import '../services/api_service.dart';

class ParkingProvider extends ChangeNotifier {
  List<ParkingSpot> _spots = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _timer;
  bool _polling = false;

  List<ParkingSpot> get spots => _spots;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  int get occupiedCount => _spots.where((s) => s.occupied).length;
  int get freeCount => _spots.where((s) => !s.occupied).length;

  void startPolling() {
    if (_polling) return;
    _polling = true;
    _loading = true;
    _fetchSpots();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchSpots());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _polling = false;
  }

  Future<void> refresh() => _fetchSpots();

  Future<void> _fetchSpots() async {
    try {
      final spots = await ApiService.getSpots();
      _spots = spots;
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (_) {
      _error = 'Cannot reach Pi — check hotspot';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
