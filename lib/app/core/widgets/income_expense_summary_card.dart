import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';

class IncomeExpenseSummaryCard extends StatelessWidget {
  final double income;
  final double expense;

  const IncomeExpenseSummaryCard({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      transform: Matrix4.translationValues(0, -AppSizes.paddingXL, 0),
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Income Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.black,
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingS),
                    const Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${'+ '}${CurrencyFormatter.format(income)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 60,
            width: 1,
            color: AppColors.grey200,
          ),

          // Expense Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.black,
                            size: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${'- '}${CurrencyFormatter.format(expense)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
