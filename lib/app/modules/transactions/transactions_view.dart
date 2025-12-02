import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/transaction_item.dart';
import '../../core/utils/currency_formatter.dart';
import 'transactions_controller.dart';

class TransactionsView extends GetView<TransactionsController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTransactions,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Month Selector
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: controller.previousMonth,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: controller.showMonthSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingM,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Obx(
                              () => Text(
                                controller.selectedPeriod.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: controller.nextMonth,
                  ),
                ],
              ),
            ),

            // Filter Chips
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                0,
                AppSizes.paddingM,
                AppSizes.paddingM,
              ),
              child: Column(
                children: [
                  // Top row with filter icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Type filter button (left)
                      IconButton(
                        icon: Obx(
                          () => Icon(
                            Icons.filter_list,
                            color: controller.showTypeFilter.value
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        onPressed: controller.toggleTypeFilter,
                        tooltip: 'Type Filter',
                      ),
                      // Order button (right)
                      IconButton(
                        icon: Obx(
                          () => Icon(
                            controller.sortOrder.value == 'newest'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: controller.showSortOrder.value
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        onPressed: controller.toggleSortOrder,
                        tooltip: 'Sort Order',
                      ),
                    ],
                  ),
                  // Type filter row (conditional)
                  Obx(
                    () => controller.showTypeFilter.value
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Type:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('All'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Income'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Expense'),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Sort order options (conditional)
                  Obx(
                    () => controller.showSortOrder.value
                        ? Column(
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Order:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOrderChip('Newest', 'newest'),
                                  const SizedBox(width: 8),
                                  _buildOrderChip('Oldest', 'oldest'),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ), // Transactions List
            Expanded(
              child: controller.filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: AppColors.grey400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No transactions found',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSizes.paddingM,
                        right: AppSizes.paddingM,
                        bottom: 80, // Extra padding for FAB
                      ),
                      itemCount: controller.groupedTransactions.length,
                      itemBuilder: (context, index) {
                        final groupKey = controller.groupedTransactions.keys
                            .elementAt(index);
                        final transactions =
                            controller.groupedTransactions[groupKey]!;
                        final dayTotal = controller.getDayTotal(transactions);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingM,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    groupKey,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(dayTotal.abs()),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: dayTotal >= 0
                                          ? AppColors.income
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Transactions for this date
                            ...transactions.map((transaction) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8, // Reduced spacing
                                ),
                                child: TransactionItem(
                                  categoryIcon: transaction['category_icon'],
                                  categoryName: transaction['category_name'],
                                  date: transaction['date'],
                                  amount: (transaction['amount'] as num)
                                      .toDouble(),
                                  categoryType: transaction['category_type'],
                                  description: transaction['description'],
                                  onTap: () => controller.showTransactionDetail(
                                    transaction,
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showAddTransactionOptions,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Obx(() {
      final isSelected = controller.selectedType.value == label;
      return InkWell(
        onTap: () => controller.setFilterType(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOrderChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.sortOrder.value == value;
      return InkWell(
        onTap: () => controller.setSortOrder(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
