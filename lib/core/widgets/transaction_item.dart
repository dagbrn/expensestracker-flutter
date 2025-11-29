import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class TransactionItem extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryType;
  final double amount;
  final String date;
  final String? description;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryType,
    required this.amount,
    required this.date,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = categoryType == 'income';
    final parsedDate = DateTime.tryParse(date) ?? DateTime.now();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isIncome 
                    ? AppColors.income.withOpacity(0.1) 
                    : AppColors.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Center(
                child: Text(
                  categoryIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description ?? DateFormatter.formatRelative(parsedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Amount
            Text(
              '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCompact(amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
