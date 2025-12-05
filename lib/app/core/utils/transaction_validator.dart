class TransactionValidator {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }

    if (value.length < 2) {
      return 'Title must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Title must not exceed 100 characters';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'Description must not exceed 500 characters';
    }

    return null;
  }

  static String? validateCategory(int? categoryId) {
    if (categoryId == null) {
      return 'Category is required';
    }

    return null;
  }

  static String? validateWallet(int? walletId) {
    if (walletId == null) {
      return 'Wallet is required';
    }

    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }

    if (date.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  static String? validateType(String? type) {
    if (type == null || (type != 'income' && type != 'expense')) {
      return 'Invalid transaction type';
    }

    return null;
  }
}
