import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/transaction.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String initialType; // 'income' or 'expense'
  final VoidCallback? onTransactionAdded;

  const AddTransactionBottomSheet({
    super.key,
    required this.initialType,
    this.onTransactionAdded,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;

  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final WalletRepository _walletRepo = WalletRepository();

  late String _transactionType;
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedWalletId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _titleController = TextEditingController();
    _transactionType = widget.initialType;
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categoriesData = await _categoryRepo.getByType(_transactionType);
      final walletsData = await _walletRepo.getAll();

      setState(() {
        _categories = categoriesData;
        _wallets = walletsData;

        if (categoriesData.isNotEmpty) {
          _selectedCategoryId = categoriesData.first['id'];
        }
        if (walletsData.isNotEmpty) {
          _selectedWalletId = walletsData.first['id'];
        }
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter transaction title',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter amount',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedCategoryId == null) {
      Get.snackbar(
        'Error',
        'Please select a category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedWalletId == null) {
      Get.snackbar(
        'Error',
        'Please select a wallet',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', ''),
      );

      final transaction = TransactionModel(
        amount: amount,
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        type: _transactionType,
      );

      await _transactionRepo.insert(transaction);

      // Update wallet balance
      final isIncome = _transactionType == 'income';
      await _walletRepo.updateBalance(_selectedWalletId!, amount, isIncome);

      if (mounted) {
        setState(() => _isSaving = false);
      }

      widget.onTransactionAdded?.call();

      Get.back(result: true);
      Get.snackbar(
        'Success',
        'Transaction added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }

      Get.snackbar(
        'Error',
        'Failed to save transaction: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _transactionType == 'income'
        ? AppColors.income
        : AppColors.expense;

    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXL),
            topRight: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXL),
            topRight: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSizes.paddingM,
            right: AppSizes.paddingM,
            top: AppSizes.paddingL,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with type toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add ${_transactionType == 'income' ? 'Income' : 'Expense'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record your transaction',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Type Selector
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Income',
                      'income',
                      AppColors.income,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: _buildTypeButton(
                      'Expense',
                      'expense',
                      AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Transaction Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Freelance Work, Shopping',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Date Picker
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Category Selection
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedCategoryId,
                  underline: const SizedBox(),
                  items: _categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'],
                      child: Row(
                        children: [
                          Text(category['icon'] ?? '📁', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(category['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Wallet Selection
              const Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedWalletId,
                  underline: const SizedBox(),
                  items: _wallets.map((wallet) {
                    return DropdownMenuItem<int>(
                      value: wallet['id'],
                      child: Text(wallet['name'] ?? 'Wallet'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedWalletId = value);
                  },
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Transaction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String type, Color color) {
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () => setState(() => _transactionType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppColors.grey300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
