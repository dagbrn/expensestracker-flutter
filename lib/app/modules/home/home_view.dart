import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/balance_card.dart';
import '../../core/widgets/transaction_item.dart';
import '../../core/widgets/empty_state.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                BalanceCard(
                  totalBalance: controller.totalBalance.value,
                  income: controller.totalIncome.value,
                  expense: controller.totalExpense.value,
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.navigateToAddTransaction('income'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Income'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.navigateToAddTransaction('expense'),
                        icon: const Icon(Icons.remove),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingL),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to transactions tab
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingM),

                if (controller.recentTransactions.isEmpty)
                  const EmptyState(
                    title: 'No Transactions',
                    message: 'No transactions yet',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.recentTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = controller.recentTransactions[index];
                      return TransactionItem(
                        categoryIcon: transaction['category_icon'] ?? '❓',
                        categoryName: transaction['category_name'] ?? 'Unknown',
                        date: transaction['date'] ?? '',
                        amount: (transaction['amount'] as num).toDouble(),
                        categoryType: transaction['category_type'] ?? 'expense',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
