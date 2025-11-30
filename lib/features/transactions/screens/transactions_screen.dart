import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/transaction_item.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final WalletRepository _walletRepo = WalletRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String _selectedFilter = 'all'; // all, income, expense
  String _selectedPeriod = 'all'; // all, today, week, month
  DateTime? _selectedMonth; // null means 'all months'
  List<DateTime> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionRepo.getAll();
      final categories = await _categoryRepo.getAll();

      final transactionsWithDetails = <Map<String, dynamic>>[];

      for (var tx in transactions) {
        final categoryId = tx['category_id'];
        if (categoryId != null) {
          final category = categories.firstWhere(
            (c) => c['id'] == categoryId,
            orElse: () => {'name': 'Unknown', 'icon': '❓', 'type': 'expense'},
          );

          transactionsWithDetails.add({
            ...tx,
            'category_name': category['name'],
            'category_icon': category['icon'],
            'category_type': category['type'],
          });
        }
      }

      // Sort by date (newest first)
      transactionsWithDetails.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });

      // Extract unique months from transactions
      final monthsSet = <String>{};
      for (var tx in transactionsWithDetails) {
        final date = DateTime.parse(tx['date']);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthsSet.add(monthKey);
      }

      final months = monthsSet.map((monthKey) {
        final parts = monthKey.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }).toList();

      months.sort((a, b) => b.compareTo(a)); // Newest first

      setState(() {
        _allTransactions = transactionsWithDetails;
        _filteredTransactions = transactionsWithDetails;
        _availableMonths = months;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allTransactions);

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((tx) => tx['category_type'] == _selectedFilter)
          .toList();
    }

    // Filter by period
    final now = DateTime.now();
    if (_selectedPeriod == 'today') {
      filtered = filtered.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.year == now.year &&
            txDate.month == now.month &&
            txDate.day == now.day;
      }).toList();
    } else if (_selectedPeriod == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.isAfter(weekAgo);
      }).toList();
    } else if (_selectedPeriod == 'month') {
      filtered = filtered.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.year == now.year && txDate.month == now.month;
      }).toList();
    }

    // Filter by selected month (if month filter is active)
    if (_selectedMonth != null) {
      filtered = filtered.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.year == _selectedMonth!.year &&
            txDate.month == _selectedMonth!.month;
      }).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _navigateToAddTransaction(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: type),
      ),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  void _navigateToEditTransaction(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Update wallet balance (reverse the transaction)
        final amount = (transaction['amount'] as num).toDouble();
        final isIncome = transaction['category_type'] == 'income';
        await _walletRepo.updateBalance(
          transaction['wallet_id'],
          amount,
          !isIncome, // Reverse: if it was income, subtract; if expense, add
        );

        // Delete transaction
        await _transactionRepo.delete(transaction['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e')),
          );
        }
      }
    }
  }

  Widget _buildMonthSelector() {
    if (_availableMonths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Row(
        children: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _selectedMonth == null
                ? null
                : () {
                    final currentIndex = _availableMonths.indexOf(
                      _selectedMonth!,
                    );
                    if (currentIndex < _availableMonths.length - 1) {
                      setState(() {
                        _selectedMonth = _availableMonths[currentIndex + 1];
                        _selectedPeriod = 'all'; // Reset period filter
                      });
                      _applyFilters();
                    }
                  },
          ),
          // Month selector
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: () => _showMonthPicker(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedMonth == null
                          ? 'All Months'
                          : DateFormat('MMMM yyyy').format(_selectedMonth!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
          // Next month button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth == null
                ? null
                : () {
                    final currentIndex = _availableMonths.indexOf(
                      _selectedMonth!,
                    );
                    if (currentIndex > 0) {
                      setState(() {
                        _selectedMonth = _availableMonths[currentIndex - 1];
                        _selectedPeriod = 'all'; // Reset period filter
                      });
                      _applyFilters();
                    }
                  },
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // All months option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedMonth == null
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.all_inclusive,
                  color: _selectedMonth == null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              title: const Text('All Months'),
              selected: _selectedMonth == null,
              selectedTileColor: AppColors.primary.withOpacity(0.05),
              onTap: () {
                setState(() {
                  _selectedMonth = null;
                  _selectedPeriod = 'all';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            // List of available months
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableMonths.length,
                itemBuilder: (context, index) {
                  final month = _availableMonths[index];
                  final isSelected =
                      _selectedMonth != null &&
                      _selectedMonth!.year == month.year &&
                      _selectedMonth!.month == month.month;

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(DateFormat('MMMM yyyy').format(month)),
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withOpacity(0.05),
                    onTap: () {
                      setState(() {
                        _selectedMonth = month;
                        _selectedPeriod =
                            'all'; // Reset period filter when selecting month
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Row(
        children: [
          // Type Filter
          const Text('Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              setState(() => _selectedFilter = 'all');
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Income'),
            selected: _selectedFilter == 'income',
            selectedColor: AppColors.income.withOpacity(0.3),
            onSelected: (selected) {
              setState(() => _selectedFilter = 'income');
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Expense'),
            selected: _selectedFilter == 'expense',
            selectedColor: AppColors.expense.withOpacity(0.3),
            onSelected: (selected) {
              setState(() => _selectedFilter = 'expense');
              _applyFilters();
            },
          ),
          const SizedBox(width: 16),
          // Period Filter
          const Text('Period: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (_selectedMonth == null) ...[
            ChoiceChip(
              label: const Text('All'),
              selected: _selectedPeriod == 'all',
              onSelected: (selected) {
                setState(() => _selectedPeriod = 'all');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Today'),
              selected: _selectedPeriod == 'today',
              onSelected: (selected) {
                setState(() => _selectedPeriod = 'today');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Week'),
              selected: _selectedPeriod == 'week',
              onSelected: (selected) {
                setState(() => _selectedPeriod = 'week');
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Month'),
              selected: _selectedPeriod == 'month',
              onSelected: (selected) {
                setState(() => _selectedPeriod = 'month');
                _applyFilters();
              },
            ),
          ] else ...[
            Text(
              'Showing: ${DateFormat('MMMM yyyy').format(_selectedMonth!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.paddingL),
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Transactions Found',
          message: 'Try adjusting your filters or add a new transaction',
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (var tx in _filteredTransactions) {
      final date = DateTime.parse(tx['date']);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        // Calculate total for this day
        double dayTotal = 0;
        for (var tx in transactions) {
          final amount = (tx['amount'] as num).toDouble();
          if (tx['category_type'] == 'income') {
            dayTotal += amount;
          } else {
            dayTotal -= amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateHeader(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(dayTotal),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dayTotal >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            // Transactions for this day
            ...transactions.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                child: TransactionItem(
                  categoryName: tx['category_name'] ?? 'Unknown',
                  categoryIcon: tx['category_icon'] ?? '❓',
                  categoryType: tx['category_type'] ?? 'expense',
                  amount: (tx['amount'] as num).toDouble(),
                  date: tx['date'] ?? DateTime.now().toIso8601String(),
                  description: tx['description'],
                  onTap: () => _showTransactionDetails(tx),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today';
    } else if (txDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isIncome = transaction['category_type'] == 'income';
        final amount = (transaction['amount'] as num).toDouble();
        final date = DateTime.parse(transaction['date']);

        return Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isIncome ? AppColors.income : AppColors.expense)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction['category_icon'] ?? '❓',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['category_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(amount),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
              if (transaction['description'] != null &&
                  transaction['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction['description'],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEditTransaction(transaction);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTransaction(transaction);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: AppSizes.paddingM),
                _buildMonthSelector(),
                const SizedBox(height: AppSizes.paddingM),
                _buildFilterChips(),
                const SizedBox(height: AppSizes.paddingM),
                Expanded(child: _buildTransactionsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionOptions(),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddTransactionOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: AppColors.income),
              ),
              title: const Text('Add Income'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction('income');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove, color: AppColors.expense),
              ),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction('expense');
              },
            ),
          ],
        ),
      ),
    );
  }
}
