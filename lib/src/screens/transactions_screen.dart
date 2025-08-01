import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../widgets/app_drawer.dart';

class TransactionsScreen extends StatefulWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  
  // Mock data - replace with actual data from your backend
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Session with Sarah Johnson',
      amount: 150.0,
      type: TransactionType.income,
      category: 'Therapy Sessions',
      patientName: 'Sarah Johnson',
    ),
    // Add more mock transactions as needed
  ];

  List<Transaction> get _filteredTransactions {
    return _transactions.where((txn) {
      final matchesSearch = txn.description.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          (txn.patientName?.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ??
              false);

      final matchesType = _typeFilter == 'all' ||
          (_typeFilter == 'income' && txn.type == TransactionType.income) ||
          (_typeFilter == 'expense' && txn.type == TransactionType.expense);

      final matchesCategory = _categoryFilter == 'all' ||
          txn.category.toLowerCase() == _categoryFilter.toLowerCase();

      return matchesSearch && matchesType && matchesCategory;
    }).toList();
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get _netIncome => _totalIncome - _totalExpenses;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(theme),
            const SizedBox(height: 24),
            
            // Filters
            _buildFilters(theme),
            const SizedBox(height: 16),
            
            // Transactions List
            _buildTransactionsList(theme, textTheme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    // Use LayoutBuilder to make the layout responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        // For small screens, show cards in a column
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSummaryCard(
                theme,
                title: 'Total Income',
                amount: _totalIncome,
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                theme,
                title: 'Total Expenses',
                amount: _totalExpenses,
                icon: Icons.trending_down,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                theme,
                title: 'Net Income',
                amount: _netIncome,
                icon: Icons.account_balance_wallet,
                color: _netIncome >= 0 ? Colors.green : Colors.red,
              ),
            ],
          );
        } 
        // For larger screens, show cards in a row
        else {
          return Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  title: 'Total Income',
                  amount: _totalIncome,
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  title: 'Total Expenses',
                  amount: _totalExpenses,
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  title: 'Net Income',
                  amount: _netIncome,
                  icon: Icons.account_balance_wallet,
                  color: _netIncome >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            // Use LayoutBuilder to adjust layout based on screen width
            LayoutBuilder(
              builder: (context, constraints) {
                // For small screens, stack the filters vertically
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      // Search Field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      // Type Filter
                      DropdownButtonFormField<String>(
                        value: _typeFilter,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        isExpanded: true,
                        items: [
                          'all',
                          'income',
                          'expense',
                        ].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == 'all' 
                                ? 'All Types' 
                                : '${type[0].toUpperCase()}${type.substring(1)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _typeFilter = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Category Filter
                      DropdownButtonFormField<String>(
                        value: _categoryFilter,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        isExpanded: true,
                        items: [
                          'all',
                          ...TransactionCategories.income,
                          ...TransactionCategories.expense,
                        ].toSet().toList().map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category.toLowerCase(),
                            child: Text(
                              category == 'all' ? 'All Categories' : category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _categoryFilter = value;
                            });
                          }
                        },
                      ),
                    ],
                  );
                } 
                // For larger screens, show filters in a single row
                else {
                  return Row(
                    children: [
                      // Search Field
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Type Filter
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _typeFilter,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          isExpanded: true,
                          items: [
                            'all',
                            'income',
                            'expense',
                          ].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type == 'all' 
                                  ? 'All Types' 
                                  : '${type[0].toUpperCase()}${type.substring(1)}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _typeFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category Filter
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _categoryFilter,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          isExpanded: true,
                          items: [
                            'all',
                            ...TransactionCategories.income,
                            ...TransactionCategories.expense,
                          ].toSet().toList().map<DropdownMenuItem<String>>((category) {
                            return DropdownMenuItem<String>(
                              value: category.toLowerCase(),
                              child: Text(
                                category == 'all' ? 'All Categories' : category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _categoryFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: textTheme.titleMedium?.copyWith(
                  color: theme.disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isNotEmpty ||
                  _typeFilter != 'all' ||
                  _categoryFilter != 'all') ...[
                const SizedBox(height: 12),
                Text(
                  'Try adjusting your filters',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _typeFilter = 'all';
                      _categoryFilter = 'all';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Filters'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Add a new transaction to get started',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddTransactionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final txn = _filteredTransactions[index];
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _showTransactionDetails(context, txn),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: isSmallScreen
                  ? _buildMobileTransactionItem(txn, Theme.of(context), Theme.of(context).textTheme)
                  : _buildDesktopTransactionItem(txn, Theme.of(context), Theme.of(context).textTheme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTransactionItem(
    Transaction txn,
    ThemeData theme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Icon and amount section
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: txn.type == TransactionType.income
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                txn.type == TransactionType.income
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: txn.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${txn.amount.toStringAsFixed(0)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: txn.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Details section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row - Description and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      txn.description,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd').format(txn.date),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Second row - Category and patient name if available
              Text(
                txn.category,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (txn.patientName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Patient: ${txn.patientName!}',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTransactionItem(
    Transaction txn,
    ThemeData theme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: txn.type == TransactionType.income
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            txn.type == TransactionType.income
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: txn.type == TransactionType.income
                ? Colors.green
                : Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        // Description
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                txn.description,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (txn.patientName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Patient: ${txn.patientName!}',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // Category
        Expanded(
          flex: 2,
          child: Text(
            txn.category,
            style: textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Date
        Expanded(
          flex: 2,
          child: Text(
            DateFormat('MMM d, y hh:mm a').format(txn.date),
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ),
        // Amount
        Expanded(
          flex: 1,
          child: Text(
            '\$${txn.amount.toStringAsFixed(2)}',
            style: textTheme.titleMedium?.copyWith(
              color: txn.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        // Type
        Expanded(
          flex: 1,
          child: Text(
            txn.type == TransactionType.income ? 'Income' : 'Expense',
            style: textTheme.bodyMedium?.copyWith(
              color: txn.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    // TODO: Implement add transaction dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Transaction'),
        content: const Text('Add transaction form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle save transaction
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow('Amount',
                '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Type', transaction.type == TransactionType.income ? 'Income' : 'Expense'),
            _buildDetailRow('Category', transaction.category),
            if (transaction.patientName != null)
              _buildDetailRow('Patient', transaction.patientName!),
            _buildDetailRow('Date',
                DateFormat('MMM d, y hh:mm a').format(transaction.date)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransactionDialog(context, transaction);
                    },
                    child: const Text('EDIT'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Handle delete
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction deleted'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: const Text('DELETE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(
      BuildContext context, Transaction transaction) {
    // TODO: Implement edit transaction dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: const Text('Edit transaction form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle update transaction
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction updated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
