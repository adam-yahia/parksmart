import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parking_provider.dart';
import '../models/parking_spot.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _teal = Color(0xFF64FFDA);
  static const _bg = Color(0xFF060B14);
  static const _green = Color(0xFF00E676);
  static const _red = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _signOut() {
    context.read<ParkingProvider>().stopPolling();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatRow(),
              const SizedBox(height: 24),
              Expanded(
                child: Consumer<ParkingProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) return _buildLoadingState();
                    if (provider.error != null && provider.spots.isEmpty) {
                      return _buildErrorState(provider);
                    }
                    return _buildSpotSection(provider);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            color: _teal,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ParkSmart',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                'Live overview',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(_pulseAnim.value),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _teal.withOpacity(_pulseAnim.value),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _signOut,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, size: 14, color: Colors.white54),
                SizedBox(width: 5),
                Text(
                  'Out',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow() {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) => Row(
        children: [
          _statCard('Occupied', provider.occupiedCount, _red),
          const SizedBox(width: 10),
          _statCard('Free', provider.freeCount, _green),
          const SizedBox(width: 10),
          _statCard('Total', provider.spots.isEmpty ? 2 : provider.spots.length, Colors.white60),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotSection(ParkingProvider provider) {
    return Column(
      children: [
        _buildLotHeader(provider),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: provider.spots.length,
            itemBuilder: (context, i) => _spotTile(provider.spots[i]),
          ),
        ),
        if (provider.lastUpdated != null) ...[
          const SizedBox(height: 10),
          _buildTimestamp(provider.lastUpdated!),
        ],
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 12,
                  color: Colors.orange.withOpacity(0.7),
                ),
                const SizedBox(width: 5),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLotHeader(ParkingProvider provider) {
    return Row(
      children: [
        Icon(
          Icons.grid_view_rounded,
          size: 14,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(width: 8),
        Text(
          'Lot A — Ground Floor',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => provider.refresh(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 14,
                color: _teal.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Refresh',
                style: TextStyle(
                  color: _teal.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spotTile(ParkingSpot spot) {
    final isFree = !spot.occupied;
    final color = isFree ? _green : _red;
    final label = isFree ? 'Free' : 'Occupied';
    final icon = isFree
        ? Icons.check_circle_outline_rounded
        : Icons.directions_car_rounded;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            spot.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return Text(
      'Last updated $h:$m:$s',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withOpacity(0.22),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _teal.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to Pi...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '172.20.10.7:5000',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ParkingProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.redAccent.withOpacity(0.6),
            size: 40,
          ),
          const SizedBox(height: 14),
          const Text(
            'Cannot reach the Pi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check the hotspot connection',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '172.20.10.7:5000',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh_rounded, color: _teal),
            label: const Text(
              'Retry',
              style: TextStyle(color: _teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Free', _green),
          const SizedBox(width: 28),
          _legendItem('Occupied', _red),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
