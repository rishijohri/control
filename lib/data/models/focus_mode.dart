class FocusMode {
  const FocusMode({
    required this.id,
    required this.name,
    required this.protectedPackages,
    required this.active,
    this.startHour = 9,
    this.endHour = 17,
  });

  final String id;
  final String name;
  final List<String> protectedPackages;
  final bool active;
  final int startHour;
  final int endHour;

  FocusMode copyWith({
    String? id,
    String? name,
    List<String>? protectedPackages,
    bool? active,
    int? startHour,
    int? endHour,
  }) {
    return FocusMode(
      id: id ?? this.id,
      name: name ?? this.name,
      protectedPackages: protectedPackages ?? this.protectedPackages,
      active: active ?? this.active,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'protectedPackages': protectedPackages,
      'active': active,
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  static FocusMode fromMap(Map<dynamic, dynamic> map) {
    return FocusMode(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      protectedPackages: List<String>.from(
        (map['protectedPackages'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      active: map['active'] == true,
      startHour: (map['startHour'] as num?)?.toInt() ?? 9,
      endHour: (map['endHour'] as num?)?.toInt() ?? 17,
    );
  }
}
