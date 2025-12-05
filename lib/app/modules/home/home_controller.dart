import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../core/widgets/add_transaction_bottom_sheet.dart';

class HomeController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final isLoading = true.obs;
  final totalBalance = 0.0.obs;
  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;
  final recentTransactions = <Map<String, dynamic>>[].obs;

  final greetingText = 'Hey there!'.obs;

  @override
  void onInit() {
    super.onInit();
    _setGreeting();
    loadData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greetingText.value = 'Good morning!';
    } else if (hour < 17) {
      greetingText.value = 'Good afternoon!';
    } else {
      greetingText.value = 'Good evening!';
    }
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      // Get current month date range
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      // Calculate balance for current month
      final incomeCategories = await _categoryRepo.getByType('income');

      final allTransactions = await _transactionRepo.getAll();

      double income = 0;
      double expense = 0;

      for (var tx in allTransactions) {
        final txDate = DateTime.tryParse(tx['date']) ?? DateTime.now();
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

      totalIncome.value = income;
      totalExpense.value = expense;
      totalBalance.value = income - expense;
      recentTransactions.value = recentWithDetails;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void openAddTransactionBottomSheet(String type) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => AddTransactionBottomSheet(
        initialType: type,
        onTransactionAdded: () {
          loadData();
        },
      ),
    );
  }

}

