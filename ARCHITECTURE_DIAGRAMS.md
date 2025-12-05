# Architecture & Flow Diagrams

## Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App Layer                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Presentation Layer (UI)                 │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  HomeView          TransactionsView                  │   │
│  │  ├─ Header          ├─ List                          │   │
│  │  ├─ Summary Card    └─ Details                       │   │
│  │  ├─ Filter Chips                                     │   │
│  │  ├─ Transaction List    AddTransactionBottomSheet   │   │
│  │  └─ FAB               ├─ Type Toggle                 │   │
│  │                       ├─ Form Fields                 │   │
│  │  Reusable Widgets     └─ Validation                  │   │
│  │  ├─ HomeHeaderSection                               │   │
│  │  ├─ IncomeExpenseSummaryCard                         │   │
│  │  ├─ CategoryFilterChip                               │   │
│  │  └─ TransactionItem                                  │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Business Logic Layer (Controllers)         │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  HomeController                                      │   │
│  │  ├─ loadData()                                       │   │
│  │  ├─ openAddTransactionBottomSheet()                  │   │
│  │  ├─ setSelectedCategory()                            │   │
│  │  └─ getFilteredTransactions()                        │   │
│  │                                                       │   │
│  │  AddTransactionController                            │   │
│  │  ├─ loadData()                                       │   │
│  │  ├─ selectDate()                                     │   │
│  │  └─ saveTransaction()                                │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │             Data Layer (Repositories)                │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  TransactionRepository       CategoryRepository      │   │
│  │  ├─ insert()                 ├─ getAll()             │   │
│  │  ├─ update()                 ├─ getByType()          │   │
│  │  ├─ delete()                 └─ ...                  │   │
│  │  ├─ getAll()                                         │   │
│  │  ├─ getByType()              WalletRepository        │   │
│  │  ├─ getByCategory()          ├─ getAll()             │   │
│  │  ├─ getByDateRange()         ├─ updateBalance()      │   │
│  │  ├─ getById()                └─ ...                  │   │
│  │  └─ ...                                              │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Database Layer (SQLite)                 │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  Transactions      Categories      Wallets          │   │
│  │  ├─ id             ├─ id          ├─ id             │   │
│  │  ├─ amount         ├─ name        ├─ name           │   │
│  │  ├─ date           ├─ type        ├─ balance        │   │
│  │  ├─ type           ├─ icon        └─ ...            │   │
│  │  ├─ category_id    └─ ...                           │   │
│  │  ├─ wallet_id                                       │   │
│  │  └─ ...                                              │   │
│  │                                                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## User Flow - Add Transaction

```
Home Screen
    ↓
[FAB Button Pressed]
    ↓
┌─────────────────────────┐
│ Type Selector Dialog    │
│ [Income] [Expense]      │
└─────────────────────────┘
    ↓
[User Selects Type]
    ↓
┌──────────────────────────────┐
│ AddTransactionBottomSheet    │
│ ├─ Type Toggle               │
│ ├─ Title Input               │
│ ├─ Amount Input              │
│ ├─ Date Picker               │
│ ├─ Category Dropdown         │
│ ├─ Wallet Dropdown           │
│ ├─ Description Field         │
│ └─ [Save Transaction]        │
└──────────────────────────────┘
    ↓
[Form Validation]
    ├─ Title valid?
    ├─ Amount valid?
    ├─ Category selected?
    ├─ Wallet selected?
    ├─ Date valid?
    └─ Type valid?
    ↓
[If Valid] → TransactionRepository.insert()
    ↓
[Update Wallet Balance]
    ↓
[Close Bottom Sheet]
    ↓
[Refresh Home Screen]
    ↓
[Show Success Message]
    ↓
Home Screen (Updated)
```

## Category Filtering Flow

```
Home Screen Loads
    ↓
[Display All Transactions]
    ↓
[User Taps Category Chip]
    ├─ All
    ├─ Electricity
    ├─ Internet
    ├─ Shopping
    ├─ Insurance
    └─ Others
    ↓
HomeController.setSelectedCategory(category)
    ↓
[Update selectedCategoryFilter observable]
    ↓
HomeView.Obx() detects change
    ↓
getFilteredTransactions()
    ├─ If category is null → return all
    └─ If category selected → filter by name
    ↓
[Update Transaction List]
    ↓
[Display Filtered Results or Empty State]
```

## Data Flow - Transaction Creation

```
User Input (Bottom Sheet)
    ↓
    ├─ title: "Shopping"
    ├─ amount: 150000
    ├─ categoryId: 3
    ├─ walletId: 1
    ├─ date: 2025-01-01
    ├─ type: "expense"
    └─ description: "Online shopping"
    ↓
[Validation Layer]
    ↓
    ├─ TransactionValidator.validateTitle()
    ├─ TransactionValidator.validateAmount()
    ├─ TransactionValidator.validateCategory()
    ├─ TransactionValidator.validateWallet()
    ├─ TransactionValidator.validateDate()
    └─ TransactionValidator.validateType()
    ↓
[Create TransactionModel]
    ↓
    TransactionModel(
      amount: 150000,
      date: '2025-01-01T...',
      categoryId: 3,
      walletId: 1,
      type: 'expense',
      description: 'Online shopping'
    )
    ↓
[Convert to Map]
    ↓
    {
      amount: 150000,
      date: '2025-01-01T...',
      category_id: 3,
      wallet_id: 1,
      type: 'expense',
      description: 'Online shopping',
      created_at: '...',
      updated_at: null
    }
    ↓
[Insert to Database]
    ↓
    INSERT INTO transactions (
      amount, date, category_id, wallet_id,
      type, description, created_at
    ) VALUES (...)
    ↓
[Transaction Saved]
    ↓
[Update Wallet Balance]
    ↓
    wallet.balance = wallet.balance - 150000
    ↓
[Balance Updated]
    ↓
[Return to Home Screen]
    ↓
[Refresh Data]
    ↓
[Display Updated Balance & Transactions]
```

## State Management - GetX Observables

```
HomeController
│
├─ isLoading: RxBool
│  ├─ true when loading data
│  └─ false when done
│
├─ totalBalance: RxDouble
│  └─ Sum of income - expense
│
├─ totalIncome: RxDouble
│  └─ Sum of all income
│
├─ totalExpense: RxDouble
│  └─ Sum of all expenses
│
├─ recentTransactions: RxList
│  └─ List of transactions with details
│
├─ selectedCategoryFilter: RxnString
│  ├─ null when "All" selected
│  └─ category name when filtered
│
└─ greetingText: RxString
   └─ Changes based on time of day
```

## Database Schema Evolution

```
Version 1 (Original)
┌─────────────────────┐
│ transactions        │
├─────────────────────┤
│ id                  │
│ amount              │
│ date                │
│ category_id         │
│ wallet_id           │
│ description         │
│ created_at          │
│ updated_at          │
└─────────────────────┘

                 ↓ (Automatic Migration)

Version 2 (Current)
┌─────────────────────┐
│ transactions        │
├─────────────────────┤
│ id                  │
│ amount              │
│ date                │
│ category_id         │
│ wallet_id           │
│ description         │
│ type ← NEW          │
│ created_at          │
│ updated_at          │
└─────────────────────┘
```

## Component Hierarchy

```
Scaffold
├─ body
│  └─ Stack
│     ├─ SingleChildScrollView (Main Content)
│     │  └─ Column
│     │     ├─ HomeHeaderSection
│     │     │  ├─ Gradient Background
│     │     │  ├─ Greeting Text
│     │     │  ├─ Balance Label
│     │     │  └─ Large Balance Amount
│     │     │
│     │     ├─ IncomeExpenseSummaryCard
│     │     │  ├─ Income Section
│     │     │  │  ├─ Icon
│     │     │  │  └─ Amount
│     │     │  ├─ Divider
│     │     │  └─ Expense Section
│     │     │     ├─ Icon
│     │     │     └─ Amount
│     │     │
│     │     ├─ Categories Label
│     │     │
│     │     ├─ SingleChildScrollView (Horizontal)
│     │     │  └─ Row
│     │     │     ├─ CategoryFilterChip (All)
│     │     │     ├─ CategoryFilterChip (Electricity)
│     │     │     ├─ CategoryFilterChip (Internet)
│     │     │     └─ ... more chips
│     │     │
│     │     ├─ "Latest Transactions" Row
│     │     │
│     │     └─ ListView
│     │        └─ TransactionItem (multiple)
│     │
│     └─ Positioned (FAB)
│        └─ FloatingActionButton
│           └─ Icon.add
```

## Request/Response Pattern

### Get All Transactions
```
HomeController.loadData()
    ↓
TransactionRepository.getAll()
    ↓
DatabaseInstance.instance.database
    ↓
db.query('transactions', orderBy: 'date DESC')
    ↓
[Returns: List<Map<String, dynamic>>]
    ↓
[For each transaction]
    ├─ Fetch category details
    ├─ Get category name & icon
    ├─ Get category type
    └─ Merge into transaction map
    ↓
[Update recentTransactions observable]
    ↓
[UI rebuilds via Obx()]
    ↓
[Display transactions]
```

### Save Transaction
```
AddTransactionBottomSheet
    ↓
[User fills form & taps Save]
    ↓
[Validate all fields]
    ↓
TransactionRepository.insert(transaction)
    ↓
DatabaseInstance.instance.database
    ↓
db.insert('transactions', tx.toMap())
    ↓
[Returns: int (transaction ID)]
    ↓
WalletRepository.updateBalance()
    ↓
[Update wallet balance in database]
    ↓
[Close bottom sheet]
    ↓
HomeController.loadData()
    ↓
[Fetch updated data]
    ↓
[Update observables]
    ↓
[UI rebuilds]
    ↓
[Home screen shows updated data]
```

## Error Handling Flow

```
User Action
    ↓
[Try Operation]
    ↓
    ├─ FormatException
    │  └─ Show: "Invalid format"
    │
    ├─ DatabaseException
    │  └─ Show: "Database error"
    │
    ├─ ValidationException
    │  └─ Show: Specific validation message
    │
    └─ Generic Exception
       └─ Show: "Unexpected error"
    ↓
Get.snackbar()
    ↓
[Display error to user]
```

## Folder Structure Visualization

```
lib/
└─ app/
   ├─ core/
   │  ├─ constants/
   │  │  ├─ app_colors.dart
   │  │  └─ app_sizes.dart
   │  ├─ themes/
   │  │  └─ app_theme.dart
   │  ├─ utils/
   │  │  ├─ currency_formatter.dart
   │  │  ├─ date_formatter.dart
   │  │  └─ transaction_validator.dart ✨
   │  └─ widgets/
   │     ├─ balance_card.dart
   │     ├─ transaction_item.dart
   │     ├─ empty_state.dart
   │     ├─ home_header_section.dart ✨
   │     ├─ income_expense_summary_card.dart ✨
   │     ├─ category_filter_chip.dart ✨
   │     └─ add_transaction_bottom_sheet.dart ✨
   │
   ├─ data/
   │  ├─ db/
   │  │  └─ db_instance.dart 🔄
   │  ├─ models/
   │  │  ├─ transaction.dart 🔄
   │  │  ├─ category.dart
   │  │  └─ wallet.dart
   │  └─ repositories/
   │     ├─ transaction_repository.dart 🔄
   │     ├─ category_repository.dart
   │     └─ wallet_repository.dart
   │
   ├─ modules/
   │  ├─ home/
   │  │  ├─ home_view.dart 🔄
   │  │  ├─ home_controller.dart 🔄
   │  │  └─ home_binding.dart
   │  ├─ transactions/
   │  │  ├─ transactions_view.dart
   │  │  ├─ add_transaction_view.dart 🔄
   │  │  ├─ add_transaction_controller.dart 🔄
   │  │  └─ add_transaction_binding.dart
   │  ├─ main/
   │  ├─ reports/
   │  └─ settings/
   │
   └─ routes/
      ├─ app_pages.dart
      └─ app_routes.dart
```

---

**Legend:**
- ✨ New files
- 🔄 Modified files
- No marker = Unchanged

**Diagrams show:**
- Architecture layers
- User workflows
- Data flows
- Component hierarchy
- Database changes
- Error handling
- State management
