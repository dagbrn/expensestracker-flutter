import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'reports_controller.dart';
import 'widgets/summary_card.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/spending_trends_chart.dart';
import 'widgets/category_breakdown_list.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadReportData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Navigator
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Month Button
                      IconButton(
                        onPressed: controller.previousMonth,
                        icon: const Icon(Icons.chevron_left),
                        color: AppColors.primary,
                      ),
                      // Month & Year
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              controller.monthYearText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.periodText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Next Month Button
                      Obx(() => IconButton(
                        onPressed: controller.canGoNext 
                            ? controller.nextMonth 
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        color: controller.canGoNext 
                            ? AppColors.primary 
                            : AppColors.grey400,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      title: 'Total Income',
                      amount: controller.totalIncome.value,
                      icon: Icons.arrow_downward,
                      color: AppColors.income,
                    ),
                    SummaryCard(
                      title: 'Total Expense',
                      amount: controller.totalExpense.value,
                      icon: Icons.arrow_upward,
                      color: AppColors.expense,
                    ),
                    SummaryCard(
                      title: 'Net Balance',
                      amount: controller.netBalance.value,
                      icon: Icons.account_balance_wallet,
                      color: controller.netBalance.value >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                    SummaryCard(
                      title: 'Transactions',
                      amount: controller.transactionCount.value.toDouble(),
                      icon: Icons.receipt_long,
                      color: AppColors.primary,
                      isCount: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart Tab Selector
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.grey200.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        'Income vs Expense',
                        0,
                        controller,
                      ),
                      _buildTabButton(
                        'Spending Trends',
                        1,
                        controller,
                      ),
                      _buildTabButton(
                        'By Category',
                        2,
                        controller,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Chart Content based on selected tab
                Obx(() {
                  switch (controller.selectedChartTab.value) {
                    case 0:
                      return IncomeExpenseChart(
                        weeklyData: controller.weeklyData,
                      );
                    case 1:
                      return SpendingTrendsChart(
                        dailySpending: controller.dailySpending,
                      );
                    case 2:
                      return CategoryBreakdownList(
                        breakdowns: controller.categoryBreakdowns,
                      );
                    default:
                      return const SizedBox();
                  }
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    ReportsController controller,
  ) {
    return Expanded(
      child: Obx(() {
        final isSelected = controller.selectedChartTab.value == index;
        return GestureDetector(
          onTap: () => controller.changeChartTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusM - 2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }
}
