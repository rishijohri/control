enum InterventionOutcome {
  mindfulOpen,
  bypass,
  dropped,
}

class InterventionEvent {
  const InterventionEvent({
    required this.packageName,
    required this.appLabel,
    required this.intent,
    required this.outcome,
    required this.timestamp,
    required this.delaySeconds,
  });

  final String packageName;
  final String appLabel;
  final String intent;
  final InterventionOutcome outcome;
  final DateTime timestamp;
  final int delaySeconds;

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appLabel': appLabel,
      'intent': intent,
      'outcome': outcome.name,
      'timestamp': timestamp.toIso8601String(),
      'delaySeconds': delaySeconds,
    };
  }

  static InterventionEvent fromMap(Map<dynamic, dynamic> map) {
    return InterventionEvent(
      packageName: map['packageName']?.toString() ?? '',
      appLabel: map['appLabel']?.toString() ?? '',
      intent: map['intent']?.toString() ?? 'Unspecified',
      outcome: InterventionOutcome.values.firstWhere(
        (value) => value.name == map['outcome'],
        orElse: () => InterventionOutcome.mindfulOpen,
      ),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      delaySeconds: (map['delaySeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
