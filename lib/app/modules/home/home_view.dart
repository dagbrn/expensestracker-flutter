import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/balance_card.dart';
import '../../core/widgets/income_expense_summary_card.dart';
import '../../core/widgets/transaction_item.dart';
import '../../core/widgets/empty_state.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              BalanceCard(
                  balance: controller.totalBalance.value,
                  expense:  controller.totalExpense.value,
                ),

              // Income/Expense Summary Card
              IncomeExpenseSummaryCard(
                income: controller.totalIncome.value,
                expense: controller.totalExpense.value,
              ),

              // Latest Transactions Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Latest Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to transactions tab
                            // This would be handled by MainController
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingS),
                    if (controller.recentTransactions().isEmpty)
                      const EmptyState(
                        title: 'No Transactions',
                        message:
                            'No transactions found for this category',
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller
                            .recentTransactions()
                            .length,
                        itemBuilder: (context, index) {
                          final transaction = controller
                              .recentTransactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingM,
                            ),
                            child: TransactionItem(
                              categoryIcon:
                                  transaction['category_icon'] ?? '❓',
                              categoryName:
                                  transaction['category_name'] ??
                                      'Unknown',
                              date: transaction['date'] ?? '',
                              amount:
                                  (transaction['amount'] as num)
                                      .toDouble(),
                              categoryType:
                                  transaction['category_type'] ??
                                      'expense',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

            ],
          ),
        );
      }),
    );
  }
}
