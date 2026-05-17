class DistractingApp {
  const DistractingApp({
    required this.packageName,
    required this.label,
    this.iconBase64,
    this.isProtected = false,
    this.category = 'General',
    this.delaySeconds = 8,
    this.randomizedDelay = false,
    this.estimatedUsageMinutes = 0,
  });

  final String packageName;
  final String label;
  final String? iconBase64;
  final bool isProtected;
  final String category;
  final int delaySeconds;
  final bool randomizedDelay;
  final int estimatedUsageMinutes;

  DistractingApp copyWith({
    String? packageName,
    String? label,
    String? iconBase64,
    bool? isProtected,
    String? category,
    int? delaySeconds,
    bool? randomizedDelay,
    int? estimatedUsageMinutes,
  }) {
    return DistractingApp(
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      iconBase64: iconBase64 ?? this.iconBase64,
      isProtected: isProtected ?? this.isProtected,
      category: category ?? this.category,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      randomizedDelay: randomizedDelay ?? this.randomizedDelay,
      estimatedUsageMinutes: estimatedUsageMinutes ?? this.estimatedUsageMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'label': label,
      'iconBase64': iconBase64,
      'isProtected': isProtected,
      'category': category,
      'delaySeconds': delaySeconds,
      'randomizedDelay': randomizedDelay,
      'estimatedUsageMinutes': estimatedUsageMinutes,
    };
  }

  static DistractingApp fromMap(Map<dynamic, dynamic> map) {
    return DistractingApp(
      packageName: map['packageName']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      iconBase64: map['iconBase64']?.toString(),
      isProtected: map['isProtected'] == true,
      category: map['category']?.toString() ?? 'General',
      delaySeconds: (map['delaySeconds'] as num?)?.toInt() ?? 8,
      randomizedDelay: map['randomizedDelay'] == true,
      estimatedUsageMinutes: (map['estimatedUsageMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
