import 'package:control/core/providers.dart';
import 'package:control/features/analytics/analytics_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

    final source = analytics.granularity == AnalyticsGranularity.hourly
        ? analytics.hourlyCounts
        : analytics.dailyCounts;

    final sortedBuckets = source.keys.toList()..sort();
    final trimmedBuckets = analytics.granularity == AnalyticsGranularity.hourly
        ? (sortedBuckets.length > 24
              ? sortedBuckets.sublist(sortedBuckets.length - 24)
              : sortedBuckets)
        : (sortedBuckets.length > 14
              ? sortedBuckets.sublist(sortedBuckets.length - 14)
              : sortedBuckets);

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < trimmedBuckets.length; i++) {
      final bucket = trimmedBuckets[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: source[bucket]!.toDouble(),
              width: 14,
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF7ED9B4), Color(0xFF6AA8FF)],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: 'Interventions', value: '${analytics.totalInterventions}'),
              _MetricCard(label: 'Mindful opens', value: '${analytics.mindfulOpens}'),
              _MetricCard(label: 'Bypasses', value: '${analytics.bypasses}'),
              _MetricCard(
                label: 'Est. minutes saved',
                value: '${analytics.estimatedMinutesSaved}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intervention timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AnalyticsGranularity>(
                    segments: const [
                      ButtonSegment<AnalyticsGranularity>(
                        value: AnalyticsGranularity.hourly,
                        label: Text('Hourly'),
                      ),
                      ButtonSegment<AnalyticsGranularity>(
                        value: AnalyticsGranularity.daily,
                        label: Text('Daily'),
                      ),
                    ],
                    selected: {analytics.granularity},
                    onSelectionChanged: (selection) {
                      controller.setGranularity(selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: analytics.selectedApp.isEmpty ? '__all__' : analytics.selectedApp,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '__all__',
                        child: Text('All apps'),
                      ),
                      ...analytics.availableApps.map(
                        (app) => DropdownMenuItem<String>(
                          value: app,
                          child: Text(app),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null || value == '__all__') {
                        controller.setSelectedApp('');
                        return;
                      }
                      controller.setSelectedApp(value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Filter by app',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: bars.isEmpty
                    ? const Center(child: Text('No data for this filter yet.'))
                    : BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: bars,
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= trimmedBuckets.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final bucket = trimmedBuckets[index];
                                  final text = analytics.granularity == AnalyticsGranularity.hourly
                                      ? DateFormat.Hm().format(bucket)
                                      : DateFormat.Md().format(bucket);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(text, style: const TextStyle(fontSize: 11)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason distribution',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (analytics.reasonCounts.isEmpty)
                    const Text('No reason data yet for this filter.')
                  else
                    ...(() {
                      final entries = analytics.reasonCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key),
                          trailing: Text('${entry.value}'),
                        ),
                      );
                    })(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most distracting apps',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (analytics.topApps.isEmpty)
                    const Text('No intervention data yet.')
                  else
                    ...(() {
                      final entries = analytics.topApps.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return entries.take(5).map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key),
                          trailing: Text('${entry.value}'),
                        ),
                      );
                    })(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
