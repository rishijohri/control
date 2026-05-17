class FocusMode {
  const FocusMode({
    required this.name,
    required this.protectedCategories,
    this.active = false,
  });

  final String name;
  final List<String> protectedCategories;
  final bool active;

  FocusMode copyWith({bool? active}) {
    return FocusMode(
      name: name,
      protectedCategories: protectedCategories,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'protectedCategories': protectedCategories,
      'active': active,
    };
  }

  factory FocusMode.fromJson(Map<dynamic, dynamic> json) {
    return FocusMode(
      name: json['name'] as String,
      protectedCategories: (json['protectedCategories'] as List<dynamic>)
          .cast<String>(),
      active: (json['active'] as bool?) ?? false,
    );
  }
}
