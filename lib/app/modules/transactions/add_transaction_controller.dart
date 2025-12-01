import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/transaction.dart';

class AddTransactionController extends GetxController {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final WalletRepository _walletRepo = WalletRepository();

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  final categories = <Map<String, dynamic>>[].obs;
  final wallets = <Map<String, dynamic>>[].obs;

  final selectedCategoryId = Rxn<int>();
  final selectedWalletId = Rxn<int>();
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  late String transactionType;
  bool isEditMode = false;
  int? editTransactionId;
  double? oldAmount;
  int? oldWalletId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;

    if (args != null) {
      isEditMode = args['isEdit'] ?? false;

      if (isEditMode && args['transaction'] != null) {
        final transaction = args['transaction'] as Map<String, dynamic>;
        _loadEditData(transaction);
      } else {
        transactionType = args['type'] ?? 'expense';
      }
    } else {
      transactionType = 'expense';
    }

    loadData();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void _loadEditData(Map<String, dynamic> transaction) {
    editTransactionId = transaction['id'];
    transactionType = transaction['category_type'];

    // Set amount
    final amount = (transaction['amount'] as num).toDouble();
    amountController.text = amount.toStringAsFixed(0);
    oldAmount = amount;

    // Set description
    if (transaction['description'] != null) {
      descriptionController.text = transaction['description'];
    }

    // Set date
    selectedDate.value = DateTime.parse(transaction['date']);

    // Set category and wallet (will be set after loadData)
    selectedCategoryId.value = transaction['category_id'];
    selectedWalletId.value = transaction['wallet_id'];
    oldWalletId = transaction['wallet_id'];
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      final categoriesData = await _categoryRepo.getByType(transactionType);
      final walletsData = await _walletRepo.getAll();

      categories.value = categoriesData;
      wallets.value = walletsData;

      // Only set default values if not in edit mode
      if (!isEditMode) {
        if (categoriesData.isNotEmpty) {
          selectedCategoryId.value = categoriesData.first['id'];
        }
        if (walletsData.isNotEmpty) {
          selectedWalletId.value = walletsData.first['id'];
        }
      }
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

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter amount',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedCategoryId.value == null) {
      Get.snackbar(
        'Error',
        'Please select a category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedWalletId.value == null) {
      Get.snackbar(
        'Error',
        'Please select a wallet',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;

      final amount = double.parse(
        amountController.text.replaceAll('.', '').replaceAll(',', ''),
      );

      if (isEditMode) {
        await _updateTransaction(amount);
      } else {
        await _createTransaction(amount);
      }

      Get.back(result: true);
      Get.snackbar(
        'Success',
        isEditMode
            ? 'Transaction updated successfully'
            : 'Transaction added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save transaction: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _createTransaction(double amount) async {
    final transaction = TransactionModel(
      amount: amount,
      date: selectedDate.value.toIso8601String(),
      categoryId: selectedCategoryId.value,
      walletId: selectedWalletId.value,
      description: descriptionController.text.isEmpty
          ? null
          : descriptionController.text,
    );

    await _transactionRepo.insert(transaction);

    // Update wallet balance
    final isIncome = transactionType == 'income';
    await _walletRepo.updateBalance(selectedWalletId.value!, amount, isIncome);
  }

  Future<void> _updateTransaction(double amount) async {
    final transaction = TransactionModel(
      id: editTransactionId,
      amount: amount,
      date: selectedDate.value.toIso8601String(),
      categoryId: selectedCategoryId.value,
      walletId: selectedWalletId.value,
      description: descriptionController.text.isEmpty
          ? null
          : descriptionController.text,
    );

    await _transactionRepo.update(transaction);

    // Update wallet balance
    final isIncome = transactionType == 'income';

    // If wallet changed, revert old wallet and update new wallet
    if (oldWalletId != selectedWalletId.value) {
      // Revert old wallet balance
      await _walletRepo.updateBalance(
        oldWalletId!,
        oldAmount!,
        !isIncome, // Opposite operation to revert
      );
      // Add to new wallet
      await _walletRepo.updateBalance(
        selectedWalletId.value!,
        amount,
        isIncome,
      );
    } else {
      // Same wallet, calculate the difference
      final difference = amount - oldAmount!;
      if (difference != 0) {
        await _walletRepo.updateBalance(
          selectedWalletId.value!,
          difference.abs(),
          difference > 0 ? isIncome : !isIncome,
        );
      }
    }
  }
}
