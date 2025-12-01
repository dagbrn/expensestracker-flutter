import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../main/main_controller.dart';

class ReportsController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final isLoading = true.obs;
  final totalIncome = 0.0.obs;
  final totalExpense = 0.0.obs;
  final netBalance = 0.0.obs;
  final transactionCount = 0.obs;
  
  final categoryBreakdowns = <CategoryBreakdown>[].obs;
  final weeklyData = <WeeklyData>[].obs;
  final dailySpending = <DailySpending>[].obs;
  
  final selectedMonth = DateTime.now().obs;
  final periodStart = DateTime.now().obs;
  final periodEnd = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _setMonth(DateTime.now());
    loadReportData();
    
    // Listen to tab changes from MainController
    ever(Get.find<MainController>().currentIndex, (index) {
      if (index == 2) { // Reports tab index
        loadReportData();
      }
    });
  }

  void _setMonth(DateTime date) {
    selectedMonth.value = date;
    periodStart.value = DateTime(date.year, date.month, 1);
    periodEnd.value = DateTime(date.year, date.month + 1, 0);
  }

  void previousMonth() {
    final newDate = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    _setMonth(newDate);
    loadReportData();
  }

  void nextMonth() {
    final now = DateTime.now();
    final newDate = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    
    // Don't allow future months
    if (newDate.isBefore(DateTime(now.year, now.month + 1))) {
      _setMonth(newDate);
      loadReportData();
    }
  }

  bool get canGoNext {
    final now = DateTime.now();
    final nextMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    return nextMonth.isBefore(DateTime(now.year, now.month + 1));
  }

  Future<void> loadReportData() async {
    try {
      isLoading.value = true;

      // Get all transactions in period
      final allTransactions = await _transactionRepo.getAll();
      final categories = await _categoryRepo.getAll();

      // Filter transactions by date range
      final filteredTransactions = allTransactions.where((tx) {
        final txDate = DateTime.parse(tx['date']);
        return txDate.isAfter(periodStart.value.subtract(const Duration(days: 1))) &&
               txDate.isBefore(periodEnd.value.add(const Duration(days: 1)));
      }).toList();

      // Calculate summary
      double income = 0;
      double expense = 0;
      Map<int, double> categoryTotals = {};

      for (var tx in filteredTransactions) {
        final categoryId = tx['category_id'];
        final amount = (tx['amount'] as num).toDouble();

        final category = categories.firstWhere(
          (c) => c['id'] == categoryId,
          orElse: () => {'type': 'expense'},
        );

        if (category['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
          // Track expense by category
          categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
        }
      }

      // Create category breakdowns
      List<CategoryBreakdown> breakdowns = [];
      categoryTotals.forEach((categoryId, total) {
        final category = categories.firstWhere(
          (c) => c['id'] == categoryId,
          orElse: () => {'name': 'Unknown', 'icon': '❓'},
        );

        breakdowns.add(CategoryBreakdown(
          categoryName: category['name'] ?? 'Unknown',
          categoryIcon: category['icon'] ?? '❓',
          amount: total,
          percentage: expense > 0 ? (total / expense * 100) : 0,
          transactionCount: filteredTransactions
              .where((tx) => tx['category_id'] == categoryId)
              .length,
        ));
      });

      // Sort by amount
      breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

      // Calculate weekly data
      List<WeeklyData> weekly = _calculateWeeklyData(filteredTransactions, categories);
      
      // Calculate daily spending
      List<DailySpending> daily = _calculateDailySpending(filteredTransactions, categories);

      // Update observables
      totalIncome.value = income;
      totalExpense.value = expense;
      netBalance.value = income - expense;
      transactionCount.value = filteredTransactions.length;
      categoryBreakdowns.value = breakdowns;
      weeklyData.value = weekly;
      dailySpending.value = daily;

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load report data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<WeeklyData> _calculateWeeklyData(
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> categories,
  ) {
    // Group transactions by week
    Map<int, Map<String, double>> weeklyTotals = {};

    for (var tx in transactions) {
      final txDate = DateTime.parse(tx['date']);
      final weekNumber = ((txDate.day - 1) / 7).floor();
      
      final categoryId = tx['category_id'];
      final amount = (tx['amount'] as num).toDouble();
      
      final category = categories.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => {'type': 'expense'},
      );

      if (!weeklyTotals.containsKey(weekNumber)) {
        weeklyTotals[weekNumber] = {'income': 0, 'expense': 0};
      }

      if (category['type'] == 'income') {
        weeklyTotals[weekNumber]!['income'] = 
            (weeklyTotals[weekNumber]!['income'] ?? 0) + amount;
      } else {
        weeklyTotals[weekNumber]!['expense'] = 
            (weeklyTotals[weekNumber]!['expense'] ?? 0) + amount;
      }
    }

    // Convert to list
    List<WeeklyData> result = [];
    for (int i = 0; i < 5; i++) {
      result.add(WeeklyData(
        week: i + 1,
        income: weeklyTotals[i]?['income'] ?? 0,
        expense: weeklyTotals[i]?['expense'] ?? 0,
      ));
    }

    return result;
  }

  List<DailySpending> _calculateDailySpending(
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> categories,
  ) {
    // Group transactions by day
    Map<int, double> dailyTotals = {};

    for (var tx in transactions) {
      final txDate = DateTime.parse(tx['date']);
      final day = txDate.day;
      
      final categoryId = tx['category_id'];
      final amount = (tx['amount'] as num).toDouble();
      
      final category = categories.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => {'type': 'expense'},
      );

      // Only count expenses for spending trends
      if (category['type'] == 'expense') {
        dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;
      }
    }

    // Convert to list with all days of the month
    List<DailySpending> result = [];
    final daysInMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
      0,
    ).day;

    for (int i = 1; i <= daysInMonth; i++) {
      result.add(DailySpending(
        day: i,
        amount: dailyTotals[i] ?? 0,
        date: DateTime(
          selectedMonth.value.year,
          selectedMonth.value.month,
          i,
        ),
      ));
    }

    return result;
  }

  String get monthYearText {
    final formatter = DateFormat('MMMM yyyy');
    return formatter.format(selectedMonth.value);
  }

  String get periodText {
    final formatter = DateFormat('d MMM yyyy');
    return '${formatter.format(periodStart.value)} - ${formatter.format(periodEnd.value)}';
  }
}

class CategoryBreakdown {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final int transactionCount;

  CategoryBreakdown({
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });
}

class WeeklyData {
  final int week;
  final double income;
  final double expense;

  WeeklyData({
    required this.week,
    required this.income,
    required this.expense,
  });
}

class DailySpending {
  final int day;
  final double amount;
  final DateTime date;

  DailySpending({
    required this.day,
    required this.amount,
    required this.date,
  });
}
