import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// 최근 7일의 운동 볼륨을 막대 차트로 보여준다.
class WeeklyVolumeChart extends StatelessWidget {
  const WeeklyVolumeChart({required this.volumes, super.key});

  final Map<DateTime, double> volumes;

  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    final dates = List<DateTime>.generate(
      7,
      (int index) => now.subtract(Duration(days: 6 - index)),
    );
    final values = dates
        .map((DateTime date) => volumes[date] ?? 0)
        .toList(growable: false);
    final maxVolume = values.reduce(
      (double left, double right) => left > right ? left : right,
    );
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVolume == 0 ? 1 : maxVolume * 1.2,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) {
                    return const SizedBox(width: 0, height: 0);
                  }
                  final date = dates[index];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.month}/${date.day}',
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(
            values.length,
            (int index) => BarChartGroupData(
              x: index,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: values[index],
                  color: context.tokens.brand,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ),
        ),
        duration: Duration.zero,
      ),
    );
  }
}
