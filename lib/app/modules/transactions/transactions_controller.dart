import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../main/main_controller.dart';

class TransactionsController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final isLoading = true.obs;
  final allTransactions = <Map<String, dynamic>>[].obs;
  final selectedType = 'All'.obs;
  final selectedPeriod = ''.obs; // Will be set to current month
  final selectedMonth = DateTime.now().obs;
  final availableMonths = <DateTime>[].obs;
  final showTypeFilter = false.obs; // Default off
  final showSortOrder = false.obs; // Default off
  final sortOrder = 'newest'.obs; // 'newest' or 'oldest'

  void toggleTypeFilter() {
    showTypeFilter.value = !showTypeFilter.value;
    // Turn off sort order when type filter is turned on
    if (showTypeFilter.value) {
      showSortOrder.value = false;
    }
  }

  void toggleSortOrder() {
    showSortOrder.value = !showSortOrder.value;
    // Turn off type filter when sort order is turned on
    if (showSortOrder.value) {
      showTypeFilter.value = false;
    }
  }

  void setSortOrder(String order) {
    sortOrder.value = order;
  }

  @override
  void onInit() {
    super.onInit();
    // Set default period to current month
    final now = DateTime.now();
    selectedMonth.value = DateTime(now.year, now.month);
    _updatePeriodLabel();
    loadTransactions();
    
    // Listen to tab changes from MainController
      ever(Get.find<MainController>().currentIndex, (index) {
        if (index == 1) { // Transactions tab index
          loadTransactions();
        }
      });
  }

  List<Map<String, dynamic>> get filteredTransactions {
    return allTransactions.value.where((transaction) {
      final txDate = DateTime.parse(transaction['date']);

      // Filter by type
      if (selectedType.value == 'Income') {
        if (transaction['category_type'] != 'income') return false;
      } else if (selectedType.value == 'Expense') {
        if (transaction['category_type'] != 'expense') return false;
      }

      // Always filter by selected month from month selector
      if (txDate.year != selectedMonth.value.year ||
          txDate.month != selectedMonth.value.month) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var transaction in filteredTransactions) {
      final date = DateTime.parse(transaction['date']);
      final String groupKey = _getGroupKey(date);

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(transaction);
    }

    // Sort each group's transactions by date based on sortOrder
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return sortOrder.value == 'newest'
            ? dateB.compareTo(dateA) // Newest first
            : dateA.compareTo(dateB); // Oldest first
      });
    }

    // Sort groups by date based on sortOrder
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        // Parse dates from group keys for proper sorting
        DateTime getDateFromKey(String key) {
          if (key == 'Today') return DateTime.now();
          if (key == 'Yesterday') {
            return DateTime.now().subtract(const Duration(days: 1));
          }
          // Parse "Saturday, 29 November 2025" format
          final parts = key.split(', ');
          if (parts.length == 2) {
            final dateParts = parts[1].split(' ');
            if (dateParts.length == 3) {
              final day = int.parse(dateParts[0]);
              final monthNames = [
                '',
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December',
              ];
              final month = monthNames.indexOf(dateParts[1]);
              final year = int.parse(dateParts[2]);
              return DateTime(year, month, day);
            }
          }
          return DateTime.now();
        }

        final dateA = getDateFromKey(a);
        final dateB = getDateFromKey(b);
        return sortOrder.value == 'newest'
            ? dateB.compareTo(dateA) // Newest first
            : dateA.compareTo(dateB); // Oldest first
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      // Format: "Saturday, 29 November 2025"
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = days[date.weekday - 1];
      final monthName = months[date.month];
      return '$dayName, ${date.day} $monthName ${date.year}';
    }
  }

  double getDayTotal(List<Map<String, dynamic>> transactions) {
    return transactions.fold(0.0, (sum, transaction) {
      final amount = (transaction['amount'] as num).toDouble();
      return sum +
          (transaction['category_type'] == 'income' ? amount : -amount);
    });
  }

  Future<void> loadTransactions() async {
    try {
      isLoading.value = true;

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

      allTransactions.value = transactionsWithDetails;
      _extractAvailableMonths();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load transactions: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _extractAvailableMonths() {
    final Set<String> monthKeys = {};
    final List<DateTime> months = [];

    for (var transaction in allTransactions.value) {
      final date = DateTime.parse(transaction['date']);
      final monthKey = '${date.year}-${date.month}';

      if (!monthKeys.contains(monthKey)) {
        monthKeys.add(monthKey);
        months.add(DateTime(date.year, date.month));
      }
    }

    // Sort months in descending order (newest first)
    months.sort((a, b) => b.compareTo(a));
    availableMonths.value = months;
  }

  void showMonthSelector() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Available months (removed "All Months" option)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableMonths.length,
                itemBuilder: (context, index) {
                  final month = availableMonths[index];
                  final monthLabel = _getMonthLabel(month);
                  final isSelected = selectedPeriod.value == monthLabel;

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
                    title: Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withOpacity(0.05)
                        : null,
                    onTap: () {
                      selectedMonth.value = month;
                      selectedPeriod.value = monthLabel;
                      Get.back();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _getMonthLabel(DateTime date) {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month]} ${date.year}';
  }

  void setFilterType(String type) {
    selectedType.value = type;
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
  }

  void navigateToAddTransaction() async {
    final result = await Get.toNamed('/add-transaction');
    if (result == true) {
      loadTransactions();
    }
  }

  void showAddTransactionOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
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
              title: const Text(
                'Add Income',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                Get.toNamed(
                  '/add-transaction',
                  arguments: {'type': 'income'},
                )?.then((result) {
                  if (result == true) loadTransactions();
                });
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
              title: const Text(
                'Add Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                Get.toNamed(
                  '/add-transaction',
                  arguments: {'type': 'expense'},
                )?.then((result) {
                  if (result == true) loadTransactions();
                });
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showTransactionDetail(Map<String, dynamic> transaction) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        (transaction['category_type'] == 'income'
                                ? AppColors.income
                                : AppColors.expense)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      transaction['category_icon'] ?? '❓',
                      style: const TextStyle(fontSize: 28),
                    ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(transaction['date']),
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

            // Amount
            const Text(
              'Amount',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(
                (transaction['amount'] as num).toDouble(),
              ),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: transaction['category_type'] == 'income'
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              transaction['description'] ?? '-',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(
                        '/add-transaction',
                        arguments: {'transaction': transaction, 'isEdit': true},
                      )?.then((result) {
                        if (result == true) loadTransactions();
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(transaction),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  void _confirmDelete(Map<String, dynamic> transaction) {
    Get.back(); // Close detail bottom sheet
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _deleteTransaction(transaction['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      Get.back(); // Close dialog
      await _transactionRepo.delete(id);
      await loadTransactions();
      Get.snackbar(
        'Success',
        'Transaction deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete transaction: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void nextMonth() {
    final currentIndex = availableMonths.indexWhere(
      (m) =>
          m.year == selectedMonth.value.year &&
          m.month == selectedMonth.value.month,
    );

    if (currentIndex > 0) {
      selectedMonth.value = availableMonths[currentIndex - 1];
      _updatePeriodLabel();
    }
  }

  void previousMonth() {
    final currentIndex = availableMonths.indexWhere(
      (m) =>
          m.year == selectedMonth.value.year &&
          m.month == selectedMonth.value.month,
    );

    if (currentIndex < availableMonths.length - 1) {
      selectedMonth.value = availableMonths[currentIndex + 1];
      _updatePeriodLabel();
    }
  }

  void _updatePeriodLabel() {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    selectedPeriod.value =
        '${months[selectedMonth.value.month]} ${selectedMonth.value.year}';
  }
}
