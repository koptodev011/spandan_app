import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_drawer.dart';
import 'add_transaction_screen.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class TransactionsUpdatedScreen extends StatefulWidget {
  static const routeName = '/transactions-updated';

  const TransactionsUpdatedScreen({Key? key}) : super(key: key);

  @override
  _TransactionsUpdatedScreenState createState() => _TransactionsUpdatedScreenState();
}

class _TransactionsUpdatedScreenState extends State<TransactionsUpdatedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _transactions = [];
  Map<String, dynamic> _summaryData = {
    'income': 0.0,
    'expenses': 0.0,
    'net_income': 0.0,
  };
  bool _isLoading = true;
  String _errorMessage = '';

  // Removed categories filter as per requirement

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch transactions from API
      final response = await _paymentService.getPayments(
        type: _typeFilter == 'all' ? '' : _typeFilter,
        category: _categoryFilter == 'All' ? '' : _categoryFilter.toLowerCase(),
        search: _searchController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _transactions = response['data'] ?? [];
          
          // Calculate summary data
          double income = 0.0;
          double expenses = 0.0;
          
          for (var txn in _transactions) {
            final amount = double.tryParse(txn['amount']?.toString() ?? '0') ?? 0.0;
            if (txn['type'] == 'income') {
              income += amount;
            } else {
              expenses += amount;
            }
          }
          
          _summaryData = {
            'income': income,
            'expenses': expenses,
            'net_income': income - expenses,
          };
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load transactions';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading transactions: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get filtered transactions based on current filters and search
  List<dynamic> get _filteredTransactions {
    String searchTerm = _searchController.text.toLowerCase();
    
    return _transactions.where((txn) {
      // Filter by type
      if (_typeFilter != 'all' && txn['type'] != _typeFilter) {
        return false;
      }
      
      // Category filter removed as per requirement
      
      // Filter by search term (client-side as fallback)
      if (searchTerm.isNotEmpty) {
        final description = txn['description']?.toString().toLowerCase() ?? '';
        final amount = txn['amount']?.toString().toLowerCase() ?? '';
        final reference = txn['reference_number']?.toString().toLowerCase() ?? '';
        
        if (!description.contains(searchTerm) &&
            !amount.contains(searchTerm) &&
            !reference.contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _showFilterDialog() {
    // Use a StatefulBuilder to manage the dialog's state
    showDialog(
      context: context,
      builder: (context) {
        String selectedType = _typeFilter;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Transaction Type'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Type', 
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, 
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('All', selectedType == 'all', () {
                          setDialogState(() {
                            selectedType = 'all';
                          });
                        }),
                        _buildFilterChip('Income', selectedType == 'income', () {
                          setDialogState(() {
                            selectedType = 'income';
                          });
                        }),
                        _buildFilterChip('Expense', selectedType == 'expense', () {
                          setDialogState(() {
                            selectedType = 'expense';
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _typeFilter = selectedType;
                    });
                    Navigator.pop(context);
                    _loadTransactions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF3B82F6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF1E40AF)),
        onDeleted: onTap,
        backgroundColor: const Color(0xFFE0F2FE),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x803B82F6)),
        ),
        elevation: 0,
      ),
    );
  }
  
  // Removed duplicate _showFilterDialog and _buildFilterChip methods that were at the end of the file

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _refreshTransactions() {
    _loadTransactions();
  }

  // Format the filter label for display
  String get _typeFilterLabel {
    switch (_typeFilter) {
      case 'income':
        return 'Income';
      case 'expense':
        return 'Expense';
      default:
        return 'All Transactions';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
              onPressed: () async {
                final result = await Navigator.pushNamed(context, AddTransactionScreen.routeName);
                if (result == true) {
                  _refreshTransactions();
                }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading transactions',
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
            _buildSummaryCards(theme, isDarkMode),
            
            // Search and Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_alt_outlined),
                        onPressed: _showFilterDialog,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  // Active Filters
            if (_typeFilter != 'all')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActiveFilterChip(
                        _typeFilterLabel,
                        () {
                          setState(() {
                            _typeFilter = 'all';
                            _loadTransactions();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _typeFilter = 'all';
                            _loadTransactions();
                          });
                        },
                        child: const Text('Clear filter'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
            
            // Transaction List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_transactions.length} items',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions List
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _typeFilter != 'all' ||
                              _categoryFilter != 'All')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _typeFilter = 'all';
                                  _categoryFilter = 'All';
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final txn = _filteredTransactions[index];
                        return _buildTransactionCard(txn, theme, isDarkMode);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Income Card
          _buildSummaryCard(
            context,
            'Income',
            '₹${_summaryData['income']?.toStringAsFixed(2) ?? '0.00'}',
            Icons.arrow_upward,
            Colors.green,
            isDarkMode,
          ),
          const SizedBox(width: 12),
          
          // Expenses Card
          _buildSummaryCard(
            context,
            'Expenses',
            '₹${_summaryData['expenses']?.toStringAsFixed(2) ?? '0.00'}',
            Icons.arrow_downward,
            Colors.red,
            isDarkMode,
          ),
          const SizedBox(width: 12),
          
          // Net Income Card
          _buildSummaryCard(
            context,
            'Net',
            '₹${_summaryData['net_income']?.toStringAsFixed(2) ?? '0.00'}',
            _summaryData['net_income'] >= 0 ? Icons.trending_up : Icons.trending_down,
            _summaryData['net_income'] >= 0 ? Colors.green : Colors.red,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
      Map<String, dynamic> txn, ThemeData theme, bool isDarkMode) {
    final isIncome = txn['type'] == 'income';
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    final iconColor = isIncome ? Colors.green : Colors.red;
    final bgColor = isIncome
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);
        
    final date = txn['date'] != null 
        ? DateTime.tryParse(txn['date']) 
        : null;
    final patientName = txn['patient']?['full_name'] ?? 'N/A';
    final amount = '₹${double.tryParse(txn['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}';
    final reference = txn['reference_number']?.toString() ?? 'N/A';
    final description = txn['description']?.toString() ?? 'No description';
    final category = txn['category']?.toString() ?? 'Uncategorized';
    final dateStr = date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A';
    final patientInfo = 'Patient: $patientName';
    final categoryInfo = '$category • $dateStr';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryInfo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (patientName != 'N/A') ...[
                          const SizedBox(height: 2),
                          Text(
                            patientInfo,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Amount and Reference
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      if (reference != 'N/A') ...[
                        const SizedBox(height: 2),
                        Text(
                          reference,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        onTap: () {
          // Navigate to transaction details if needed
        },
      ),
    );
  }


}
