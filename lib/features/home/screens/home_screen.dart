import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/transaction_item.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../transactions/screens/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  bool _isLoading = true;
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current month date range
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      // Calculate balance for current month
      final incomeCategories = await _categoryRepo.getByType('income');
      final expenseCategories = await _categoryRepo.getByType('expense');

      final allTransactions = await _transactionRepo.getAll();

      double income = 0;
      double expense = 0;

      for (var tx in allTransactions) {
        final txDate = DateTime.parse(tx['date']);
        if (txDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
            txDate.isBefore(lastDay.add(const Duration(days: 1)))) {
          final categoryId = tx['category_id'];
          final amount = (tx['amount'] as num).toDouble();

          final isIncome = incomeCategories.any((c) => c['id'] == categoryId);
          if (isIncome) {
            income += amount;
          } else {
            expense += amount;
          }
        }
      }

      // Get recent transactions with details
      final recentTx = await _transactionRepo.getAll();
      final recentWithDetails = <Map<String, dynamic>>[];

      for (var tx in recentTx.take(5)) {
        final categoryId = tx['category_id'];
        if (categoryId != null) {
          final categories = await _categoryRepo.getAll();
          final category = categories.firstWhere(
            (c) => c['id'] == categoryId,
            orElse: () => {
              'name': 'Unknown',
              'icon': '❓',
              'type': 'expense',
            },
          );

          recentWithDetails.add({
            ...tx,
            'category_name': category['name'],
            'category_icon': category['icon'],
            'category_type': category['type'],
          });
        }
      }

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _totalBalance = income - expense;
        _recentTransactions = recentWithDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _navigateToAddTransaction(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: type),
      ),
    );

    if (result == true) {
      _loadData(); // Refresh data after adding transaction
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    BalanceCard(
                      totalBalance: _totalBalance,
                      income: _totalIncome,
                      expense: _totalExpense,
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToAddTransaction('income'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Income'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.income,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingM),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToAddTransaction('expense'),
                            icon: const Icon(Icons.remove),
                            label: const Text('Add Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.expense,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all transactions
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Recent Transactions List
                    if (_recentTransactions.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Transactions Yet',
                        message: 'Start tracking your finances by adding your first transaction',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentTransactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSizes.paddingM),
                        itemBuilder: (context, index) {
                          final tx = _recentTransactions[index];
                          return TransactionItem(
                            categoryName: tx['category_name'] ?? 'Unknown',
                            categoryIcon: tx['category_icon'] ?? '❓',
                            categoryType: tx['category_type'] ?? 'expense',
                            amount: (tx['amount'] as num).toDouble(),
                            date: tx['date'] ?? DateTime.now().toIso8601String(),
                            description: tx['description'],
                            onTap: () {
                              // TODO: Navigate to transaction detail
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
