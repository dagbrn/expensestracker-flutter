# Code Examples & Integration Guide

## Complete Workflow Examples

### Example 1: Creating an Income Transaction

```dart
// In your controller or service
import 'package:expensetracker/app/data/models/transaction.dart';
import 'package:expensetracker/app/data/repositories/transaction_repository.dart';
import 'package:expensetracker/app/data/repositories/wallet_repository.dart';

Future<void> recordFreelanceIncome() async {
  final transactionRepo = TransactionRepository();
  final walletRepo = WalletRepository();

  try {
    // Create transaction
    final transaction = TransactionModel(
      amount: 500000, // Rp 500,000
      date: DateTime.now().toIso8601String(),
      categoryId: 4, // Freelance category
      walletId: 1, // Main wallet
      description: 'Freelance project payment',
      type: 'income', // Important: explicitly set type
    );

    // Save to database
    await transactionRepo.insert(transaction);

    // Update wallet balance
    await walletRepo.updateBalance(1, 500000, true); // true = income

    print('Income recorded successfully');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 2: Recording an Expense Transaction

```dart
Future<void> recordShoppingExpense() async {
  final transactionRepo = TransactionRepository();
  final walletRepo = WalletRepository();

  try {
    final transaction = TransactionModel(
      amount: 150000, // Rp 150,000
      date: DateTime.now().toIso8601String(),
      categoryId: 3, // Shopping category
      walletId: 1, // Main wallet
      description: 'Online shopping - clothes',
      type: 'expense', // Explicitly set type
    );

    await transactionRepo.insert(transaction);
    await walletRepo.updateBalance(1, 150000, false); // false = expense

    print('Expense recorded successfully');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 3: Updating a Transaction

```dart
Future<void> updateTransaction(int transactionId, double newAmount) async {
  final transactionRepo = TransactionRepository();

  try {
    // Fetch existing transaction
    final txData = await transactionRepo.getById(transactionId);
    
    if (txData == null) {
      print('Transaction not found');
      return;
    }

    // Create updated transaction
    final updatedTx = TransactionModel.fromMap(txData).copyWith(
      amount: newAmount,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Save updates
    await transactionRepo.update(updatedTx);

    print('Transaction updated successfully');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 4: Deleting a Transaction

```dart
Future<void> deleteTransaction(int transactionId) async {
  final transactionRepo = TransactionRepository();

  try {
    final result = await transactionRepo.delete(transactionId);
    
    if (result > 0) {
      print('Transaction deleted successfully');
    } else {
      print('Transaction not found');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 5: Querying Transactions

```dart
Future<void> queryTransactions() async {
  final transactionRepo = TransactionRepository();

  try {
    // Get all transactions
    final allTx = await transactionRepo.getAll();
    print('Total transactions: ${allTx.length}');

    // Get only income transactions
    final incomeTx = await transactionRepo.getByType('income');
    print('Income transactions: ${incomeTx.length}');

    // Get expenses from category
    final categoryExpenses = await transactionRepo.getByCategory(3);
    print('Category 3 transactions: ${categoryExpenses.length}');

    // Get transactions from date range
    final startDate = DateTime(2025, 1, 1);
    final endDate = DateTime(2025, 1, 31);
    final rangeTx = await transactionRepo.getByDateRange(startDate, endDate);
    print('January transactions: ${rangeTx.length}');

    // Get single transaction
    final singleTx = await transactionRepo.getById(1);
    if (singleTx != null) {
      print('Transaction 1: ${singleTx['description']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

## Widget Integration Examples

### Example 6: Using HomeHeaderSection Widget

```dart
import 'package:expensetracker/app/core/widgets/home_header_section.dart';

class MyCustomView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeHeaderSection(
          balance: 5000000.0, // Display balance
          greeting: 'Welcome back!', // Custom greeting
        ),
        // Rest of UI
      ],
    );
  }
}
```

### Example 7: Using IncomeExpenseSummaryCard

```dart
import 'package:expensetracker/app/core/widgets/income_expense_summary_card.dart';

class SummaryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IncomeExpenseSummaryCard(
        income: 2000000.0,
        expense: 500000.0,
      ),
    );
  }
}
```

### Example 8: Using CategoryFilterChip

```dart
import 'package:expensetracker/app/core/widgets/category_filter_chip.dart';

class CategoryFilterView extends StatefulWidget {
  @override
  State<CategoryFilterView> createState() => _CategoryFilterViewState();
}

class _CategoryFilterViewState extends State<CategoryFilterView> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryFilterChip(
            label: 'Food',
            icon: '🍔',
            isSelected: selectedCategory == 'Food',
            onTap: () => setState(() => selectedCategory = 'Food'),
          ),
          SizedBox(width: 8),
          CategoryFilterChip(
            label: 'Transport',
            icon: '🚗',
            isSelected: selectedCategory == 'Transport',
            onTap: () => setState(() => selectedCategory = 'Transport'),
          ),
          // More chips...
        ],
      ),
    );
  }
}
```

### Example 9: Using AddTransactionBottomSheet

```dart
import 'package:expensetracker/app/core/widgets/add_transaction_bottom_sheet.dart';

void openAddTransactionForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AddTransactionBottomSheet(
      initialType: 'expense',
      onTransactionAdded: () {
        // Refresh your data here
        print('Transaction added!');
      },
    ),
  );
}
```

## Validation Examples

### Example 10: Form Validation

```dart
import 'package:expensetracker/app/core/utils/transaction_validator.dart';

class FormValidator {
  bool validateForm(String title, String amount, int? category, String type) {
    // Validate each field
    final titleError = TransactionValidator.validateTitle(title);
    final amountError = TransactionValidator.validateAmount(amount);
    final categoryError = TransactionValidator.validateCategory(category);
    final typeError = TransactionValidator.validateType(type);

    // Collect errors
    final errors = <String>[];
    if (titleError != null) errors.add(titleError);
    if (amountError != null) errors.add(amountError);
    if (categoryError != null) errors.add(categoryError);
    if (typeError != null) errors.add(typeError);

    // Show errors
    if (errors.isNotEmpty) {
      print('Validation errors:');
      for (var error in errors) {
        print('  - $error');
      }
      return false;
    }

    return true;
  }
}
```

### Example 11: Individual Field Validation

```dart
class TransactionFormPage extends StatefulWidget {
  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  String? titleError;
  String? amountError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    amountController = TextEditingController();
  }

  void validateTitle(String value) {
    setState(() {
      titleError = TransactionValidator.validateTitle(value);
    });
  }

  void validateAmount(String value) {
    setState(() {
      amountError = TransactionValidator.validateAmount(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          onChanged: validateTitle,
          decoration: InputDecoration(
            errorText: titleError,
          ),
        ),
        TextField(
          controller: amountController,
          onChanged: validateAmount,
          decoration: InputDecoration(
            errorText: amountError,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
```

## Advanced Usage Examples

### Example 12: Monthly Summary Calculation

```dart
import 'package:expensetracker/app/data/repositories/transaction_repository.dart';

class MonthlySummary {
  final double income;
  final double expense;
  final double balance;

  MonthlySummary({
    required this.income,
    required this.expense,
    required this.balance,
  });
}

Future<MonthlySummary> getMonthlysSummary(int month, int year) async {
  final transactionRepo = TransactionRepository();

  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);

  final transactions = await transactionRepo.getByDateRange(startDate, endDate);

  double totalIncome = 0;
  double totalExpense = 0;

  for (var tx in transactions) {
    final amount = (tx['amount'] as num).toDouble();
    final type = tx['type'] as String;

    if (type == 'income') {
      totalIncome += amount;
    } else {
      totalExpense += amount;
    }
  }

  return MonthlySummary(
    income: totalIncome,
    expense: totalExpense,
    balance: totalIncome - totalExpense,
  );
}
```

### Example 13: Category-wise Analytics

```dart
class CategoryAnalytics {
  final String categoryName;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  CategoryAnalytics({
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });
}

Future<List<CategoryAnalytics>> getCategoryAnalytics(String type) async {
  final transactionRepo = TransactionRepository();
  final categoryRepo = CategoryRepository();

  final transactions = await transactionRepo.getByType(type);
  final categories = await categoryRepo.getByType(type);

  final categoryMap = <int, CategoryAnalytics>{};
  double totalAmount = 0;

  for (var tx in transactions) {
    final categoryId = tx['category_id'] as int?;
    final amount = (tx['amount'] as num).toDouble();

    if (categoryId != null) {
      totalAmount += amount;

      if (categoryMap.containsKey(categoryId)) {
        final existing = categoryMap[categoryId]!;
        categoryMap[categoryId] = CategoryAnalytics(
          categoryName: existing.categoryName,
          totalAmount: existing.totalAmount + amount,
          transactionCount: existing.transactionCount + 1,
          percentage: 0, // Will calculate below
        );
      } else {
        final category = categories.firstWhere(
          (c) => c['id'] == categoryId,
          orElse: () => {'name': 'Unknown'},
        );

        categoryMap[categoryId] = CategoryAnalytics(
          categoryName: category['name'],
          totalAmount: amount,
          transactionCount: 1,
          percentage: 0, // Will calculate below
        );
      }
    }
  }

  // Calculate percentages
  final analytics = categoryMap.values.map((cat) {
    return CategoryAnalytics(
      categoryName: cat.categoryName,
      totalAmount: cat.totalAmount,
      transactionCount: cat.transactionCount,
      percentage: (cat.totalAmount / totalAmount) * 100,
    );
  }).toList();

  // Sort by amount descending
  analytics.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

  return analytics;
}
```

### Example 14: Spending Trend Analysis

```dart
class SpendingTrend {
  final int month;
  final int year;
  final double amount;

  SpendingTrend({
    required this.month,
    required this.year,
    required this.amount,
  });
}

Future<List<SpendingTrend>> getSpendingTrends(int year) async {
  final transactionRepo = TransactionRepository();
  final trends = <SpendingTrend>[];

  for (int month = 1; month <= 12; month++) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final transactions = await transactionRepo.getByDateRange(startDate, endDate);

    double monthlyExpense = 0;
    for (var tx in transactions) {
      if (tx['type'] == 'expense') {
        monthlyExpense += (tx['amount'] as num).toDouble();
      }
    }

    trends.add(SpendingTrend(
      month: month,
      year: year,
      amount: monthlyExpense,
    ));
  }

  return trends;
}
```

## Integration with Services

### Example 15: Create a TransactionService

```dart
import 'package:expensetracker/app/data/repositories/transaction_repository.dart';
import 'package:expensetracker/app/data/repositories/wallet_repository.dart';
import 'package:expensetracker/app/data/models/transaction.dart';

class TransactionService {
  final _transactionRepo = TransactionRepository();
  final _walletRepo = WalletRepository();

  Future<void> addTransaction({
    required String title,
    required double amount,
    required int categoryId,
    required int walletId,
    required String type,
    String? description,
  }) async {
    try {
      final transaction = TransactionModel(
        amount: amount,
        date: DateTime.now().toIso8601String(),
        categoryId: categoryId,
        walletId: walletId,
        description: description,
        type: type,
      );

      await _transactionRepo.insert(transaction);
      await _walletRepo.updateBalance(walletId, amount, type == 'income');

      print('Transaction added successfully');
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByCategory(int categoryId) {
    return _transactionRepo.getByCategory(categoryId);
  }

  Future<List<Map<String, dynamic>>> getMonthlyTransactions(int month, int year) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _transactionRepo.getByDateRange(startDate, endDate);
  }
}

// Usage in controller
class MyController extends GetxController {
  final _transactionService = TransactionService();

  Future<void> recordTransaction() async {
    await _transactionService.addTransaction(
      title: 'Groceries',
      amount: 250000,
      categoryId: 1,
      walletId: 1,
      type: 'expense',
      description: 'Weekly shopping',
    );
  }
}
```

## Error Handling Patterns

### Example 16: Comprehensive Error Handling

```dart
class TransactionHandler {
  Future<bool> saveTransactionSafely(TransactionModel transaction) async {
    try {
      final transactionRepo = TransactionRepository();
      final walletRepo = WalletRepository();

      // Validate
      if (transaction.amount <= 0) {
        throw Exception('Invalid amount');
      }

      if (transaction.categoryId == null) {
        throw Exception('Category required');
      }

      // Save
      await transactionRepo.insert(transaction);

      // Update wallet
      await walletRepo.updateBalance(
        transaction.walletId ?? 1,
        transaction.amount,
        transaction.type == 'income',
      );

      return true;
    } on FormatException catch (e) {
      print('Format error: $e');
      return false;
    } on DatabaseException catch (e) {
      print('Database error: $e');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }
}
```

---

**These examples demonstrate:**
- ✅ Complete CRUD operations
- ✅ Widget integration
- ✅ Advanced queries
- ✅ Analytics calculations
- ✅ Service layer patterns
- ✅ Error handling
- ✅ Validation usage

Feel free to adapt these examples to your specific needs!
