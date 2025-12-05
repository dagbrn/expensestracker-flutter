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
  final titleController = TextEditingController();

  final categories = <Map<String, dynamic>>[].obs;
  final wallets = <Map<String, dynamic>>[].obs;

  final selectedCategoryId = Rxn<int>();
  final selectedWalletId = Rxn<int>();
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final transactionType = 'expense'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      transactionType.value = args['type'] ?? 'expense';
    }
    loadData();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    titleController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      final categoriesData =
          await _categoryRepo.getByType(transactionType.value);
      final walletsData = await _walletRepo.getAll();

      categories.value = categoriesData;
      wallets.value = walletsData;

      if (categoriesData.isNotEmpty) {
        selectedCategoryId.value = categoriesData.first['id'];
      }
      if (walletsData.isNotEmpty) {
        selectedWalletId.value = walletsData.first['id'];
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
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter transaction title',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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

      final transaction = TransactionModel(
        amount: amount,
        date: selectedDate.value.toIso8601String(),
        categoryId: selectedCategoryId.value,
        walletId: selectedWalletId.value,
        description:
            descriptionController.text.isEmpty ? null : descriptionController.text,
        type: transactionType.value,
      );

      await _transactionRepo.insert(transaction);

      // Update wallet balance
      final isIncome = transactionType.value == 'income';
      await _walletRepo.updateBalance(selectedWalletId.value!, amount, isIncome);

      Get.back(result: true);
      Get.snackbar(
        'Success',
        'Transaction added successfully',
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
}
