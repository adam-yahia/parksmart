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

  // ── Mockup palette ──────────────────────────────────────────────
  static const _blue = Color(0xFF59BFFF);
  static const _blueDeep = Color(0xFF2B6FB0);
  static const _green = Color(0xFF5BCB6B);
  static const _greenDeep = Color(0xFF3F9E4D);
  static const _orange = Color(0xFFFF8A3D);
  static const _orangeDeep = Color(0xFFFF7D29);
  static const _ink = Color(0xFFF2F5FA);
  static const _card = Color(0xFF151B2B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.25),
            radius: 1.3,
            colors: [Color(0xFF15264A), Color(0xFF070A12), Color(0xFF04060C)],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildStatRow(),
                    const SizedBox(height: 20),
                    _buildSectionRow(),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Consumer<ParkingProvider>(
                        builder: (context, provider, _) {
                          if (provider.loading && provider.spots.isEmpty) {
                            return _buildLoadingState();
                          }
                          if (provider.error != null && provider.spots.isEmpty) {
                            return _buildErrorState(provider);
                          }
                          return _buildSpotGrid(provider);
                        },
                      ),
                    ),
                    // reserved clearance so Astro doesn't cover a spot card
                    const SizedBox(height: 96),
                  ],
                ),
              ),
              // Astro companion — overlaid bottom-left, mood = live sensor state
              Positioned(
                left: 6,
                bottom: 10,
                child: Consumer<ParkingProvider>(
                  builder: (context, provider, _) => _buildAstro(provider),
                ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER (blue gradient card) ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(22, 0, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_blue, _blueDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.30),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Adam',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ParkSmart',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _livePill(),
              ],
            ),
          ),
          _signOutButton(),
        ],
      ),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35 + 0.65 * _pulseAnim.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6 * _pulseAnim.value),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, size: 14, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Out',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION ROW ──────────────────────────────────────────────────
  Widget _buildSectionRow() {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final total = provider.spots.isEmpty ? 2 : provider.spots.length;
        return Row(
          children: [
            const Text(
              'Parking Spots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const Spacer(),
            Text(
              'Level 1 · $total sensors',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => provider.refresh(),
              child: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: _blue.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── SPOT GRID ────────────────────────────────────────────────────
  Widget _buildSpotGrid(ParkingProvider provider) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              childAspectRatio: 0.9,
            ),
            itemCount: provider.spots.length,
            itemBuilder: (context, i) => _spotCard(provider.spots[i]),
          ),
        ),
        if (provider.lastUpdated != null) ...[
          const SizedBox(height: 10),
          _buildTimestamp(provider.lastUpdated!, provider.error),
        ],
      ],
    );
  }

  Widget _spotCard(ParkingSpot spot) {
    final isFree = !spot.occupied;
    final color = isFree ? _green : _orange;
    final barColor = isFree ? _greenDeep : _orangeDeep;
    final label = isFree ? 'Available' : 'Occupied';
    final num = spot.id.toString().padLeft(2, '0');

    final icon = isFree
        ? Icons.check_circle_outline_rounded
        : Icons.directions_car_rounded;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        // free cards softly pulse a green glow; busy cards sit static
        final glow = isFree ? (0.12 + 0.30 * _pulseAnim.value) : 0.0;
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withOpacity(isFree ? 0.3 + 0.3 * _pulseAnim.value : 0.32),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(glow),
                blurRadius: 26,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      num,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: barColor,
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── STATS ────────────────────────────────────────────────────────
  Widget _buildStatRow() {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final total = provider.spots.isEmpty ? 2 : provider.spots.length;
        return Row(
          children: [
            _statCard('Free', provider.freeCount, _green),
            const SizedBox(width: 10),
            _statCard('Busy', provider.occupiedCount, _orange),
            const SizedBox(width: 10),
            _statCard('Total', total, _blue),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: _ink.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ASTRO COMPANION (mood bound to live state) ───────────────────
  Widget _buildAstro(ParkingProvider provider) {
    final mood = _moodFor(provider);
    return SizedBox(
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // speech bubble
          Container(
            margin: const EdgeInsets.only(left: 46, bottom: 8),
            constraints: const BoxConstraints(maxWidth: 196),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              mood.message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _ink,
                height: 1.35,
              ),
            ),
          ),
          // mascot
          Image.asset(
            mood.asset,
            height: 112,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  _AstroMood _moodFor(ParkingProvider provider) {
    if (provider.spots.isEmpty) {
      return const _AstroMood(
        asset: 'assets/mascot/AstroWave.png',
        message: 'Waking up the sensors…',
      );
    }
    final free = provider.freeCount;
    final total = provider.spots.length;
    if (free == 0) {
      return const _AstroMood(
        asset: 'assets/mascot/AstroEmpty.png',
        message: "Lot's full right now… I'll ping you 🤷",
      );
    }
    if (free == total) {
      return _AstroMood(
        asset: 'assets/mascot/AstroFound.png',
        message: total == 2
            ? 'Both spots open — take your pick! 🎉'
            : 'All $free spots open — nice! 🎉',
      );
    }
    return _AstroMood(
      asset: 'assets/mascot/AstroWave.png',
      message: '$free spot${free == 1 ? '' : 's'} open and live 👋',
    );
  }

  // ── STATES ───────────────────────────────────────────────────────
  Widget _buildTimestamp(DateTime dt, String? error) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    if (error != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 12, color: _orange.withOpacity(0.8)),
          const SizedBox(width: 5),
          Text(
            'Reconnecting…',
            style: TextStyle(color: _orange.withOpacity(0.8), fontSize: 11),
          ),
        ],
      );
    }
    return Text(
      'Last updated $h:$m:$s',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: _ink.withOpacity(0.22)),
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
              strokeWidth: 2.4,
              color: _blue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to Pi…',
            style: TextStyle(color: _ink.withOpacity(0.4), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '172.20.10.7:5000',
            style: TextStyle(color: _ink.withOpacity(0.2), fontSize: 12),
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
          Icon(Icons.wifi_off_rounded, color: _orange.withOpacity(0.7), size: 40),
          const SizedBox(height: 14),
          const Text(
            'Cannot reach the Pi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check the hotspot connection',
            style: TextStyle(color: _ink.withOpacity(0.35), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '172.20.10.7:5000',
            style: TextStyle(color: _ink.withOpacity(0.2), fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh_rounded, color: _blue),
            label: const Text(
              'Retry',
              style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AstroMood {
  final String asset;
  final String message;
  const _AstroMood({required this.asset, required this.message});
}
