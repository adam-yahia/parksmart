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
    return ParkingSpot(
      id: json['id'] as int,
      name: json['name'] as String,
      occupied: json['occupied'] as bool,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}
