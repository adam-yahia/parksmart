class ParkingSpot {
  final int id;
  final String name;
  final bool occupied;
  final String updatedAt;

  const ParkingSpot({
    required this.id,
    required this.name,
    required this.occupied,
    required this.updatedAt,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    final id = json['spot_id'] as int;
    return ParkingSpot(
      id: id,
      name: 'Spot $id',
      occupied: json['status'] == 'occupied',
      updatedAt: json['last_updated'] as String? ?? '',
    );
  }
}
