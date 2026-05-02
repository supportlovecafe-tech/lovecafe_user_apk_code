class CinemaScreen {
  final String id;
  final String name;
  final String floor;
  final String tag;

  const CinemaScreen({
    required this.id,
    required this.name,
    required this.floor,
    required this.tag,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'tag': tag,
    };
  }

  factory CinemaScreen.fromMap(Map<String, dynamic> map) {
    return CinemaScreen(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      floor: map['floor']?.toString() ?? 'FLOOR 1',
      tag: map['tag']?.toString() ?? 'STANDARD',
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'name': name,
      'floor': floor,
      'tag': tag,
    };
  }
}

class CinemaHall {
  final String id;
  final String name;
  final String location;
  final String rating;
  final String feature;
  final String imageUrl;
  final List<CinemaScreen> screens;

  const CinemaHall({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.feature,
    required this.imageUrl,
    required this.screens,
  });

  int get screenCount => screens.length;

  CinemaHall copyWith({
    String? id,
    String? name,
    String? location,
    String? rating,
    String? feature,
    String? imageUrl,
    List<CinemaScreen>? screens,
  }) {
    return CinemaHall(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      feature: feature ?? this.feature,
      imageUrl: imageUrl ?? this.imageUrl,
      screens: screens ?? this.screens,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'rating': rating,
      'feature': feature,
      'imageUrl': imageUrl,
      'screens': screens.map((screen) => screen.toMap()).toList(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'name': name,
      'location': location,
      'rating': rating,
      'feature': feature,
      'image_url': imageUrl,
    };
  }

  factory CinemaHall.fromMap(Map<String, dynamic> map) {
    return CinemaHall(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      rating: map['rating']?.toString() ?? '4.5',
      feature: map['feature']?.toString() ?? 'Full Menu',
      imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? '',
      screens: (map['screens'] as List<dynamic>? ?? [])
          .map((entry) => CinemaScreen.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
    );
  }
}
