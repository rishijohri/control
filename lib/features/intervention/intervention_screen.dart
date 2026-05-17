import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InterventionResult {
  const InterventionResult({
    required this.continueToTarget,
    required this.intent,
    required this.usedBypass,
  });

  final bool continueToTarget;
  final String intent;
  final bool usedBypass;
}

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({
    super.key,
    required this.appLabel,
    required this.delaySeconds,
    required this.breathTarget,
    required this.opensToday,
    required this.minutesToday,
  });

  final String appLabel;
  final int delaySeconds;
  final int breathTarget;
  final int opensToday;
  final int minutesToday;

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _holdController;
  late int _remaining;
  late final int _breathTarget;
  Timer? _timer;
  int _completedBreaths = 0;
  double _lastAnimationValue = 0;
  String _selectedIntent = 'I have a purpose';
  bool _holdCompleting = false;

  bool get _isPauseComplete =>
      _remaining <= 0 && _completedBreaths >= _breathTarget;

  @override
  void initState() {
    super.initState();
    _remaining = widget.delaySeconds;
    _breathTarget = widget.breathTarget.clamp(1, 12);
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..addListener(() {
        if (!mounted) {
          return;
        }
        final currentValue = _controller.value;
        // With repeat(), detect a completed breath cycle when animation wraps.
        if (currentValue + 0.5 < _lastAnimationValue) {
          setState(() {
            _completedBreaths = (_completedBreaths + 1).clamp(0, 999);
          });
        }
        _lastAnimationValue = currentValue;
      })
      ..repeat();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
      }
      setState(() {
        _remaining = (_remaining - 1).clamp(0, 999);
      });
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _holdToContinue() async {
    if (_holdCompleting || !_isPauseComplete) {
      return;
    }
    setState(() => _holdCompleting = true);
    HapticFeedback.mediumImpact();
    await _holdController.forward(from: 0);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      InterventionResult(
        continueToTarget: true,
        intent: _selectedIntent,
        usedBypass: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intents = const [
      'I have a purpose',
      'Quick check',
      'I am bored',
      'I need a break',
    ];
    final isBreathingStage = !_isPauseComplete;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061D2E), Color(0xFF0E2F42), Color(0xFF143954)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isBreathingStage
                  ? _BreathingStage(
                      key: const ValueKey<String>('breathing-stage'),
                      appLabel: widget.appLabel,
                      remaining: _remaining,
                      completedBreaths: _completedBreaths,
                      breathTarget: _breathTarget,
                      controller: _controller,
                    )
                  : _IntentStage(
                      key: const ValueKey<String>('intent-stage'),
                      intents: intents,
                      selectedIntent: _selectedIntent,
                      opensToday: widget.opensToday,
                      minutesToday: widget.minutesToday,
                      onIntentChanged: (intent) => setState(() => _selectedIntent = intent),
                      onHoldToContinue: _holdToContinue,
                      holdProgress: _holdController,
                      holdCompleting: _holdCompleting,
                      onNotNow: () {
                        Navigator.of(context).pop(
                          InterventionResult(
                            continueToTarget: false,
                            intent: _selectedIntent,
                            usedBypass: false,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingStage extends StatelessWidget {
  const _BreathingStage({
    super.key,
    required this.appLabel,
    required this.remaining,
    required this.completedBreaths,
    required this.breathTarget,
    required this.controller,
  });

  final String appLabel;
  final int remaining;
  final int completedBreaths;
  final int breathTarget;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final normalized = controller.value;
          final elapsedWaveSeconds =
              (controller.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
            const inhaleFraction = 1 / 3;
            const holdFraction = 1 / 6;
            const exhaleFraction = 1 / 3;
            const finalHoldFraction = 1 / 6;
          const inhaleSeconds = 4;
          const holdSeconds = 2;
          const exhaleSeconds = 4;
            const finalHoldSeconds = 2;
          final holdPeakBoundary = inhaleFraction + holdFraction;
            final exhaleEndBoundary = holdPeakBoundary + exhaleFraction;

          String phaseLabel;
          double fillLevel;
          int phaseSecondsRemaining;

          if (normalized < inhaleFraction) {
            final phaseProgress = normalized / inhaleFraction;
            phaseLabel = 'Inhale';
            fillLevel = 0.18 + (phaseProgress * 0.72);
            phaseSecondsRemaining =
                (inhaleSeconds - (phaseProgress * inhaleSeconds)).ceil().clamp(1, inhaleSeconds);
          } else if (normalized < holdPeakBoundary) {
            final phaseProgress = (normalized - inhaleFraction) / holdFraction;
            phaseLabel = 'Hold';
            // Hold starts exactly when the container reaches full level.
            fillLevel = 0.90;
            phaseSecondsRemaining =
                (holdSeconds - (phaseProgress * holdSeconds)).ceil().clamp(1, holdSeconds);
            } else if (normalized < exhaleEndBoundary) {
            final phaseProgress = ((normalized - holdPeakBoundary) / exhaleFraction)
                .clamp(0.0, 1.0);
            phaseLabel = 'Exhale';
            fillLevel = 0.18 + ((1 - phaseProgress) * 0.72);
            phaseSecondsRemaining =
                (exhaleSeconds - (phaseProgress * exhaleSeconds)).ceil().clamp(1, exhaleSeconds);
            } else {
            final phaseProgress = ((normalized - exhaleEndBoundary) / finalHoldFraction)
              .clamp(0.0, 1.0);
            phaseLabel = 'Hold';
            fillLevel = 0.18;
            phaseSecondsRemaining =
              (finalHoldSeconds - (phaseProgress * finalHoldSeconds))
                .ceil()
                .clamp(1, finalHoldSeconds);
          }

          final shownBreaths = completedBreaths.clamp(0, breathTarget);
          final textOnLiquid = fillLevel > 0.50;
          final primaryText = textOnLiquid ? Colors.black87 : Colors.white;
          final secondaryText = textOnLiquid ? Colors.black54 : Colors.white70;
          const orbSize = 280.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pause Before $appLabel',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Breathe with the flow ($shownBreaths/$breathTarget)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: orbSize,
                    height: orbSize,
                    child: CustomPaint(
                      painter: _LiquidFillPainter(
                        fillLevel: fillLevel,
                        phase: elapsedWaveSeconds,
                        liquidColor: const Color(0xFF7ED9B4),
                        liquidAccent: const Color(0xFF50A9D8),
                      ),
                    ),
                  ),
                  Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 1.2,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$phaseSecondsRemaining',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        phaseLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Intent selection unlocks when this pause and breath target complete.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiquidFillPainter extends CustomPainter {
  _LiquidFillPainter({
    required this.fillLevel,
    required this.phase,
    required this.liquidColor,
    required this.liquidAccent,
  });

  final double fillLevel;
  final double phase;
  final Color liquidColor;
  final Color liquidAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    final shellPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.22),
          const Color(0xFF8FC9E6).withValues(alpha: 0.12),
          const Color(0xFF1D4C69).withValues(alpha: 0.30),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, shellPaint);

    final clipPath = Path()..addOval(rect.deflate(1));
    canvas.save();
    canvas.clipPath(clipPath);

    final waterTop = size.height * (1 - fillLevel.clamp(0.0, 1.0));
    final amplitude = 6.0 + (1 - fillLevel) * 6.0;
    final waveLength = size.width;
    final wavePhase = phase * math.pi * 2.2;

    final liquidPath = Path()..moveTo(0, size.height);
    liquidPath.lineTo(0, waterTop);

    for (double x = 0; x <= size.width; x += 1) {
      final sine = math.sin(((x / waveLength) * 2 * math.pi) + wavePhase) * amplitude;
      final secondary =
          math.cos(((x / waveLength) * 4 * math.pi) + wavePhase * 0.7) * (amplitude * 0.35);
      liquidPath.lineTo(x, waterTop + sine + secondary);
    }

    liquidPath.lineTo(size.width, size.height);
    liquidPath.close();

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquidAccent.withValues(alpha: 0.86),
          liquidColor.withValues(alpha: 0.92),
        ],
      ).createShader(rect);

    canvas.drawPath(liquidPath, liquidPaint);

    final sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final sheenPath = Path()..moveTo(0, waterTop);
    for (double x = 0; x <= size.width; x += 1) {
      final y = waterTop + math.sin(((x / waveLength) * 2 * math.pi) + wavePhase) * (amplitude * 0.52);
      sheenPath.lineTo(x, y);
    }
    canvas.drawPath(sheenPath, sheen);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || oldDelegate.phase != phase;
  }
}

class _IntentStage extends StatelessWidget {
  const _IntentStage({
    super.key,
    required this.intents,
    required this.selectedIntent,
    required this.opensToday,
    required this.minutesToday,
    required this.onIntentChanged,
    required this.onHoldToContinue,
    required this.holdProgress,
    required this.holdCompleting,
    required this.onNotNow,
  });

  final List<String> intents;
  final String selectedIntent;
  final int opensToday;
  final int minutesToday;
  final ValueChanged<String> onIntentChanged;
  final Future<void> Function() onHoldToContinue;
  final Animation<double> holdProgress;
  final bool holdCompleting;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey<String>('intent-controls'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Choose your intent',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a reason before continuing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AwarenessMetric(
                          title: 'Opens today',
                          value: '$opensToday',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AwarenessMetric(
                          title: 'Minutes today',
                          value: '$minutesToday',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final intent in intents)
                        ChoiceChip(
                          label: Text(intent),
                          selected: selectedIntent == intent,
                          onSelected: (_) => onIntentChanged(intent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onNotNow,
                      icon: const Icon(Icons.celebration_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Close app and keep your focus'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA6F0CF),
                        foregroundColor: const Color(0xFF123829),
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reward yourself by ending the urge loop right here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onLongPress: onHoldToContinue,
                    child: SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 58,
                              color: const Color(0xFF7ED9B4),
                            ),
                            AnimatedBuilder(
                              animation: holdProgress,
                              builder: (context, _) {
                                return FractionallySizedBox(
                                  widthFactor: holdProgress.value,
                                  child: Container(
                                    height: 58,
                                    color: const Color(0xFF4FB886),
                                  ),
                                );
                              },
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  holdCompleting
                                      ? 'Continuing...'
                                      : 'Press and hold to continue',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Entering the app requires a deliberate long press.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AwarenessMetric extends StatelessWidget {
  const _AwarenessMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
