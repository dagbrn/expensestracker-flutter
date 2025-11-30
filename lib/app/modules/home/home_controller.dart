import 'package:get/get.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';

class HomeController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final isLoading = true.obs;
  final totalBalance = 0.0.obs;
  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;
  final recentTransactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
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

  void navigateToAddTransaction(String type) async {
    final result = await Get.toNamed(
      '/add-transaction',
      arguments: {'type': type},
    );

    if (result == true) {
      loadData();
    }
  }
}
