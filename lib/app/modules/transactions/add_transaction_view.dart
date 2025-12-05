import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'add_transaction_controller.dart';

class AddTransactionView extends GetView<AddTransactionController> {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isIncome = controller.transactionType.value == 'income';
      final color = isIncome ? AppColors.income : AppColors.expense;

      return Scaffold(
        appBar: AppBar(
          title: Text('Add ${isIncome ? 'Income' : 'Expense'}'),
          backgroundColor: color,
        ),
        body: _buildBody(context, isIncome, color),
      );
    });
  }

  Widget _buildBody(BuildContext context, bool isIncome, Color color) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton('Income', 'income', AppColors.income),
                ),
                const SizedBox(width: AppSizes.paddingM),
                Expanded(
                  child: _buildTypeButton('Expense', 'expense', AppColors.expense),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Title Input
            TextField(
              controller: controller.titleController,
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
                  TextField(
                    controller: controller.amountController,
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
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.categories.map((category) {
                final isSelected =
                    controller.selectedCategoryId.value == category['id'];
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
                    controller.selectedCategoryId.value = category['id'];
                  },
                );
              }).toList(),
            )),
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
            Obx(() => DropdownButtonFormField<int>(
              value: controller.selectedWalletId.value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: controller.wallets.map((wallet) {
                return DropdownMenuItem<int>(
                  value: wallet['id'],
                  child: Text(wallet['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedWalletId.value = value;
              },
            )),
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
              onTap: () => controller.selectDate(context),
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
                    Obx(() => Text(
                      '${controller.selectedDate.value.day}/${controller.selectedDate.value.month}/${controller.selectedDate.value.year}',
                      style: const TextStyle(fontSize: 16),
                    )),
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
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),

            // Save Button
            Obx(() => ElevatedButton(
              onPressed: controller.isSaving.value ? null : controller.saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isSaving.value
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
            )),
          ],
        ),
      );
    });
  }

  Widget _buildTypeButton(String label, String type, Color color) {
    return Obx(() {
      final isSelected = controller.transactionType.value == type;
      return GestureDetector(
        onTap: () => controller.transactionType.value = type,
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
    });
  }
}
