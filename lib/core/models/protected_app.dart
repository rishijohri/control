class ProtectedApp {
  const ProtectedApp({
    required this.packageName,
    required this.appName,
    required this.iconHint,
    this.isProtected = false,
    this.category = 'General',
    this.delaySeconds = 8,
    this.dailyUsageMinutes,
  });

  final String packageName;
  final String appName;
  final String iconHint;
  final bool isProtected;
  final String category;
  final int delaySeconds;
  final int? dailyUsageMinutes;

  ProtectedApp copyWith({
    bool? isProtected,
    String? category,
    int? delaySeconds,
  }) {
    return ProtectedApp(
      packageName: packageName,
      appName: appName,
      iconHint: iconHint,
      isProtected: isProtected ?? this.isProtected,
      category: category ?? this.category,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      dailyUsageMinutes: dailyUsageMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconHint': iconHint,
      'isProtected': isProtected,
      'category': category,
      'delaySeconds': delaySeconds,
      'dailyUsageMinutes': dailyUsageMinutes,
    };
  }

  factory ProtectedApp.fromJson(Map<dynamic, dynamic> json) {
    return ProtectedApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      iconHint: json['iconHint'] as String,
      isProtected: (json['isProtected'] as bool?) ?? false,
      category: (json['category'] as String?) ?? 'General',
      delaySeconds: (json['delaySeconds'] as int?) ?? 8,
      dailyUsageMinutes: json['dailyUsageMinutes'] as int?,
    );
  }
}
