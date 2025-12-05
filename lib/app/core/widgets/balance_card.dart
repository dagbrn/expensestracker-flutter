import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double expense;
  final String? greeting;

  const BalanceCard({
    super.key, 
    required this.balance, 
    required this.expense, 
    this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingL,
        AppSizes.paddingXL,
        AppSizes.paddingL,
        AppSizes.paddingXL + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row - Greeting and Bell Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting ?? 'Hi, Welcome Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Good Morning',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),

              // Notification Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Balance
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          /// Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: LinearProgressIndicator(
                      value:
                          expense/200000, //diisi dengan value berdasarkan presentase pengeluaran / target
                      // backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        // Colors.white,
                        Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      minHeight: 25,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsGeometry.symmetric(
                      horizontal: AppSizes.paddingM,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${expense/200000*100}%',
                          style: TextStyle(
                            // color: AppColors.primary,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rp200.000',
                          style: TextStyle(
                            // color: Colors.white,
                            // color: Colors.black,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  if(expense/200000 <= 0.3)
                    Icon(
                      Icons.done_outline, 
                      color: Colors.black,
                      size: 15,
                    )
                  else if (expense/200000 <= 0.6)
                    Icon(
                      Icons.error_outline, 
                      color: Colors.black,
                      size: 15,
                    )
                  else 
                    Icon(
                      Icons.gpp_maybe_outlined, 
                      color: Colors.black,
                      size: 15,
                    ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    '${expense/200000*100}% Of Your Expenses, '
                    '${expense/200000 <= 0.3 
                      ? 'Looks Good'
                      : (expense/200000 <= 0.6
                        ? 'Watch Out!'
                        : 'Don\'t push your limit')}',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
