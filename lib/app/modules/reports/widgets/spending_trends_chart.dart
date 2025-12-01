import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../reports_controller.dart';

class SpendingTrendsChart extends StatelessWidget {
  final List<DailySpending> dailySpending;

  const SpendingTrendsChart({
    super.key,
    required this.dailySpending,
  });

  @override
  Widget build(BuildContext context) {
    final maxSpending = dailySpending.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final avgSpending = dailySpending.map((d) => d.amount).reduce((a, b) => a + b) / dailySpending.length;
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg: ${CurrencyFormatter.formatCompact(avgSpending)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSpending > 0 ? maxSpending / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxSpending > 0 ? maxSpending / 4 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                minX: 1,
                maxX: dailySpending.length.toDouble(),
                minY: 0,
                maxY: maxSpending > 0 ? maxSpending * 1.2 : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: dailySpending
                        .map((d) => FlSpot(d.day.toDouble(), d.amount))
                        .toList(),
                    isCurved: true,
                    color: AppColors.expense,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Highlight peak spending
                        if (spot.y == maxSpending && maxSpending > 0) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: AppColors.expense,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.expense,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.expense.withOpacity(0.1),
                    ),
                  ),
                  // Average line
                  LineChartBarData(
                    spots: List.generate(
                      dailySpending.length,
                      (index) => FlSpot((index + 1).toDouble(), avgSpending),
                    ),
                    isCurved: false,
                    color: Colors.orange.withOpacity(0.5),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        if (spot.barIndex == 0) {
                          final date = dailySpending[spot.spotIndex].date;
                          return LineTooltipItem(
                            '${date.day}/${date.month}\n${CurrencyFormatter.formatCompact(spot.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Daily Spending', AppColors.expense),
              const SizedBox(width: 16),
              _buildLegend('Average', Colors.orange, isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
