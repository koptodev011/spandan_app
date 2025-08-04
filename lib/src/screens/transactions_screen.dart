import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../models/transaction_model.dart';
import '../services/payment_service.dart';
import '../widgets/app_drawer.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  
  // State variables
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 10;
  Timer? _debounceTimer;
  
  // Data
  List<Transaction> _transactions = [];
  Map<String, dynamic> _summaryData = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    // Use a microtask to ensure this runs after the current build phase
    Future.microtask(() async {
      if (!mounted) return;
      
      try {
        // Load data in parallel but don't wait for completion
        unawaited(Future.wait([
          _fetchTransactions(),
          _fetchSummary(),
          _fetchCategories(),
        ]));
      } catch (e) {
        if (!mounted) return;
        
        // Schedule error handling for after the current build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load data: $e')),
          );
        });
      }
    });
  }

  double get _totalIncome {
    final value = _summaryData['income'];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  double get _totalExpenses {
    final value = _summaryData['expenses'];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  double get _netIncome {
    final value = _summaryData['net_income'];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Handle search input with debounce
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        // Just update the UI, filtering is done in the getter
      });
    });
  }
  
  // Fetch all transactions from API
  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First fetch the first page to get total count
      final firstPage = await _paymentService.getPayments(
        type: 'all',
        category: 'all',
        search: '',
        page: 1,
        perPage: _perPage,
      );
      
      final totalPages = firstPage['meta']['last_page'] as int;
      List<dynamic> allTransactions = List.from(firstPage['data']);
      
      // If there are more pages, fetch them in parallel
      if (totalPages > 1) {
        final futures = <Future>[];
        
        for (int page = 2; page <= totalPages; page++) {
          futures.add(
            _paymentService.getPayments(
              type: 'all',
              category: 'all',
              search: '',
              page: page,
              perPage: _perPage,
            ).then((response) {
              allTransactions.addAll(response['data']);
            })
          );
        }
        
        await Future.wait(futures);
      }
      
      if (!mounted) return;
      
      setState(() {
        _transactions = allTransactions
            .map((json) => Transaction.fromJson(json))
            .toList();
        _isLoading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transactions: $e')),
        );
      }
    }
  }
  
  // Get filtered transactions based on current filters and search
  List<Transaction> get _filteredTransactions {
    String searchTerm = _searchController.text.toLowerCase();
    
    return _transactions.where((txn) {
      // Filter by type
      if (_typeFilter != 'all' && txn.type?.name != _typeFilter) {
        return false;
      }
      
      // Filter by category
      if (_categoryFilter != 'all' && txn.category != _categoryFilter) {
        return false;
      }
      
      // Filter by search term
      if (searchTerm.isNotEmpty) {
        final description = txn.description?.toLowerCase() ?? '';
        final amount = txn.amount.toString();
        final category = txn.category?.toLowerCase() ?? '';
        final type = txn.type?.name ?? '';
        
        if (!description.contains(searchTerm) &&
            !amount.contains(searchTerm) &&
            !category.contains(searchTerm) &&
            !type.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  // Fetch summary data
  Future<void> _fetchSummary() async {
    try {
      final response = await _paymentService.getPaymentSummary();
      if (!mounted) return;
      
      // Schedule state update for after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _summaryData = response['data'] ?? {};
        });
      });
    } catch (e) {
      if (!mounted) return;
      
      // Schedule error handling for after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e')),
        );
      });
    }
  }
  
  // Fetch categories
  Future<void> _fetchCategories() async {
    try {
      final response = await _paymentService.getPaymentCategories();
      if (!mounted) return;
      
      // Schedule state update for after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categories = [
            'all',
            ...(response['data']['income_categories'] as List<dynamic>).cast<String>(),
            ...(response['data']['expense_categories'] as List<dynamic>).cast<String>(),
          ];
        });
      });
    } catch (e) {
      if (!mounted) return;
      
      // Schedule error handling for after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      });
    }
  }

  // Handle type filter change
  void _handleTypeFilterChanged(String? value) {
    if (value != null && value != _typeFilter) {
      setState(() {
        _typeFilter = value;
      });
    }
  }
  
  // Handle category filter change
  void _handleCategoryChanged(String? value) {
    if (value != null && value != _categoryFilter) {
      setState(() {
        _categoryFilter = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Financial Transactions',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E40AF)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: Text(isSmallScreen ? 'Add' : 'Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58C0F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Title and Description
            Text(
              'Financial Overview',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your income and expenses',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    title: 'Total Income',
                    amount: _totalIncome,
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF10B981),
                    textColor: const Color(0xFF065F46),
                    bgColor: const Color(0xFFD1FAE5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    title: 'Total Expenses',
                    amount: _totalExpenses,
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFEF4444),
                    textColor: const Color(0xFF991B1B),
                    bgColor: const Color(0xFFFEE2E2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    theme,
                    title: 'Net Income',
                    amount: _netIncome,
                    icon: Icons.account_balance_wallet_rounded,
                    color: _netIncome >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    textColor: _netIncome >= 0 ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                    bgColor: _netIncome >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filters
            _buildFilters(theme),
            const SizedBox(height: 24),

            // Transactions List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (!isSmallScreen) Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_outlined, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Transactions List
            _buildTransactionsList(theme, textTheme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color bgColor,
  }) {
    // Safely format the amount
    final formattedAmount = amount.isFinite 
        ? '\$${amount.toStringAsFixed(2)}' 
        : '\$0.00';
        
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedAmount,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isSmallScreen
              ? _buildMobileFilters()
              : _buildDesktopFilters(),
        ),
      ),
    );
  }

  Widget _buildMobileFilters() {
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
          onChanged: (_) {},
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
          ].map<DropdownMenuItem<String>>((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type == 'all' ? 'All Types' : '${type[0].toUpperCase()}${type.substring(1)}',
              ),
            );
          }).toList(),
          onChanged: _handleTypeFilterChanged,
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
          items: _categories.map<DropdownMenuItem<String>>((category) {
            return DropdownMenuItem<String>(
              value: category.toLowerCase(),
              child: Text(
                category == 'all' ? 'All Categories' : category,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _handleCategoryChanged,
        ),
      ],
    );
  }

  Widget _buildDesktopFilters() {
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
            onChanged: (_) {},
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
            ].map<DropdownMenuItem<String>>((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type == 'all' ? 'All Types' : '${type[0].toUpperCase()}${type.substring(1)}',
                ),
              );
            }).toList(),
            onChanged: _handleTypeFilterChanged,
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
            items: _categories.map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category.toLowerCase(),
                child: Text(
                  category == 'all' ? 'All Categories' : category,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _handleCategoryChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(
    ThemeData theme,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTransactions = _filteredTransactions;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _typeFilter != 'all' || _categoryFilter != 'all'
                  ? 'No matching transactions found'
                  : 'No transactions found',
              style: textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isNotEmpty || _typeFilter != 'all' || _categoryFilter != 'all')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _typeFilter = 'all';
                    _categoryFilter = 'all';
                  });
                },
                child: const Text('Clear filters'),
              )
            else
              Text(
                'Add a new transaction to get started',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _showTransactionDetails(context, transaction),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: isSmallScreen
                  ? _buildMobileTransactionItem(transaction, theme, textTheme)
                  : _buildDesktopTransactionItem(transaction, theme, textTheme),
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
