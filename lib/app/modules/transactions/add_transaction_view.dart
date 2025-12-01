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
    final isIncome = controller.transactionType == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final isEdit = controller.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isEdit ? 'Edit' : 'Add'} ${isIncome ? 'Income' : 'Expense'}',
        ),
        backgroundColor: color,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
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
                    TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: color.withOpacity(0.3)),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Obx(
                () => Wrap(
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
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Wallet Selection
              const Text(
                'Wallet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Obx(
                () => DropdownButtonFormField<int>(
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
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Date Selection
              const Text(
                'Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                      Obx(
                        () => Text(
                          '${controller.selectedDate.value.day}/${controller.selectedDate.value.month}/${controller.selectedDate.value.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Description
              const Text(
                'Description (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.saveTransaction,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Transaction' : 'Save Transaction',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
