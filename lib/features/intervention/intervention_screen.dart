import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({
    super.key,
    required this.targetApp,
    required this.delaySeconds,
    required this.onContinue,
  });

  final String targetApp;
  final int delaySeconds;
  final VoidCallback onContinue;

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.delaySeconds;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = math.max(0, _remaining - 1);
      });
      if (_remaining == 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _remaining == 0;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2135), Color(0xFF111421)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pause before opening ${widget.targetApp}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final scale = 0.7 + (_controller.value * 0.3);
                      return Transform.scale(
                        scale: scale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.lightBlueAccent.withValues(alpha: 0.28),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 40,
                                spreadRadius: 10,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _remaining > 0
                                  ? 'Breathe\n$_remaining'
                                  : 'Choose intent',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 8,
                  children: const [
                    _IntentChip(label: 'I have a purpose'),
                    _IntentChip(label: 'I am bored'),
                    _IntentChip(label: 'Quick check'),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: canContinue ? widget.onContinue : null,
                  child: Text(canContinue
                      ? 'Continue to app'
                      : 'Continue in $_remaining s'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  const _IntentChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
