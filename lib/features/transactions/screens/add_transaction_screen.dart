import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../data/models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType; // 'income' or 'expense'

  const AddTransactionScreen({
    super.key,
    required this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final TransactionRepository _transactionRepo = TransactionRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final WalletRepository _walletRepo = WalletRepository();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _wallets = [];
  
  int? _selectedCategoryId;
  int? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _categoryRepo.getByType(widget.initialType);
      final wallets = await _walletRepo.getAll();

      setState(() {
        _categories = categories;
        _wallets = wallets;
        _selectedCategoryId = categories.isNotEmpty ? categories.first['id'] : null;
        _selectedWalletId = wallets.isNotEmpty ? wallets.first['id'] : null;
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
      
      final transaction = TransactionModel(
        amount: amount,
        date: _selectedDate.toIso8601String(),
        categoryId: _selectedCategoryId,
        walletId: _selectedWalletId,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
      );

      await _transactionRepo.insert(transaction);

      // Update wallet balance
      final isIncome = widget.initialType == 'income';
      await _walletRepo.updateBalance(_selectedWalletId!, amount, isIncome);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.initialType == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${isIncome ? 'Income' : 'Expense'}'),
        backgroundColor: color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Input
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingL),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: color.withOpacity(0.3),
                              ),
                              prefixText: 'Rp ',
                              prefixStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                              border: InputBorder.none,
                              filled: false,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Category Selection
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategoryId == category['id'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category['icon'] ?? ''),
                              const SizedBox(width: 4),
                              Text(category['name'] ?? ''),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: color.withOpacity(0.2),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = category['id'];
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Wallet Selection
                    const Text(
                      'Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    DropdownButtonFormField<int>(
                      value: _selectedWalletId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _wallets.map((wallet) {
                        return DropdownMenuItem<int>(
                          value: wallet['id'],
                          child: Text(wallet['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedWalletId = value);
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Date Selection
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingL),

                    // Description
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add a note...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXL),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Transaction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
