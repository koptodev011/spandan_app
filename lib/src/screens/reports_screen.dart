import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  static const routeName = '/reports';

  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // State variables
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedReport = 'general';
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _reportData = {};
  final _apiBaseUrl = 'https://spandan.koptotech.solutions/api';

  // Report types
  final List<String> _reportTypes = [
    'appointments',
    'payments',
    'sessions',
    'patients',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReport = 'appointments';
    _loadReportData();
  }

  // Get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    } catch (e) {
      throw Exception('Failed to get authentication token');
    }
  }

  // Load report data from API
  Future<void> _loadReportData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final startDate = _startDate.toIso8601String().split('T')[0];
      final endDate = _endDate.toIso8601String().split('T')[0];

      String endpoint;
      final queryParams = <String, String>{
        'start_date': startDate,
        'end_date': endDate,
      };

      // Set endpoint and query parameters based on report type
      switch (_selectedReport) {
        case 'general':
          endpoint = '/reports/statistics';
          break;
        case 'payments':
          endpoint = '/reports/payments/summary';
          break;
        case 'appointments':
          endpoint = '/reports/appointments';
          queryParams['per_page'] = '20';
          break;
        case 'sessions':
          endpoint = '/reports/sessions/completed';
          queryParams['per_page'] = '20';
          break;
        case 'patients':
          endpoint = '/reports/patients';
          queryParams['per_page'] = '20';
          break;
        default:
          endpoint = '/reports/statistics';
      }

      final uri = Uri.parse('$_apiBaseUrl$endpoint').replace(
        queryParameters: queryParams..removeWhere((_, value) => value.isEmpty),
      );

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection.');
        },
      );

      if (!mounted) return;

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        setState(() {
          _reportData = responseData['data'] ?? {};
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load report data');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Date range selector
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  // Show date range picker dialog
  Future<void> _showDateRangePickerDialog() async {
    DateTime tempStartDate = _startDate;
    DateTime tempEndDate = _endDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Range'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tempStartDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() => tempStartDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM d, yyyy').format(tempStartDate),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tempEndDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() => tempEndDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM d, yyyy').format(tempEndDate),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                    });
                    Navigator.pop(context);
                    _loadReportData();
                  },
                  child: const Text('APPLY'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  // Build date range selector
  Widget _buildDateRangeSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.date_range, color: Colors.blue),
        title: const Text('Date Range'),
        subtitle: Text(
          '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _showDateRangePickerDialog,
      ),
    );
  }

  // Build report type selector
  Widget _buildReportTypeSelector() {
    final reportTypeIcons = {
      'appointments': Icons.calendar_today,
      'payments': Icons.payments,
      'sessions': Icons.medical_services,
      'patients': Icons.people,
    };

    final reportTypeTitles = {
      'appointments': 'Appointments',
      'payments': 'Payments',
      'sessions': 'Sessions',
      'patients': 'Patients',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _reportTypes.map((type) {
          final isSelected = _selectedReport == type;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Row(
                children: [
                  Icon(reportTypeIcons[type], size: 16),
                  const SizedBox(width: 4),
                  Text(reportTypeTitles[type] ?? type),
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedReport = type);
                _loadReportData();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Build error message
  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReportData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build no data message
  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your date range',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Build stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build general dashboard
  Widget _buildGeneralDashboard() {
    if (_reportData.isEmpty) return _buildNoData();

    // Log the full response for debugging
    print('Report Data: $_reportData');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Details Card
          if (_reportData['id'] != null) ...[
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Name', _reportData['full_name'] ?? 'N/A'),
                    _buildDetailRow('Age', '${_reportData['age'] ?? 'N/A'}'),
                    _buildDetailRow('Gender', _reportData['gender']?.toString().capitalize() ?? 'N/A'),
                    _buildDetailRow('Phone', _reportData['phone'] ?? 'N/A'),
                    _buildDetailRow('Email', _reportData['email'] ?? 'N/A'),
                    _buildDetailRow('Address', _reportData['address'] ?? 'N/A'),
                    _buildDetailRow('Emergency Contact', _reportData['emergency_contact'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Medical Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Medical History', _reportData['medical_history'] ?? 'None provided'),
                    _buildDetailRow('Current Medication', _reportData['current_medication'] ?? 'None'),
                    _buildDetailRow('Allergies', _reportData['allergies'] ?? 'None'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ]
          else ...[
            // Fallback to original stats view if no patient data
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildStatCard(
                  'Total Patients',
                  '${_reportData['patients']?['total'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'New Patients',
                  '${_reportData['patients']?['new_this_period'] ?? 0}',
                  Icons.person_add,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Sessions',
                  '${_reportData['sessions']?['total'] ?? 0}',
                  Icons.medical_services,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed',
                  '${_reportData['sessions']?['completed'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build appointments report
  Widget _buildAppointmentsReport() {
    final appointments = List<Map<String, dynamic>>.from(_reportData['appointments'] ?? []);
    final summary = _reportData['summary'] ?? {};
    final pagination = _reportData['pagination'] ?? {};

    if (appointments.isEmpty) return _buildNoData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Appointments',
                '${summary['total_appointments'] ?? 0}',
                Icons.calendar_today,
                Colors.blue,
              ),
              if (summary['type_distribution'] != null) ...[
                for (final entry in (summary['type_distribution'] as Map<String, dynamic>).entries)
                  _buildStatCard(
                    '${entry.key.replaceAll('_', ' ').capitalize()}',
                    '${entry.value}',
                    Icons.event_available,
                    Colors.green,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          // Appointments List
          const Text(
            'Upcoming Appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...appointments.map((appointment) => _buildAppointmentCard(appointment)).toList(),
          
          // Pagination Info
          if (pagination.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Showing ${pagination['from']}-${pagination['to']} of ${pagination['total']} appointments',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Build appointment card
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final date = DateTime.parse(appointment['appointment_date']);
    final time = DateTime.parse(appointment['start_time']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment['patient_name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (appointment['type'] ?? '').toString().replaceAll('_', ' ').capitalize(),
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(time),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${appointment['duration_minutes']} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (appointment['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${appointment['notes']}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build payments report
  Widget _buildPaymentsReport() {
    if (_reportData.isEmpty) return _buildNoData();

    final totalIncome = _reportData['total_income'] ?? 0;
    final totalExpenses = _reportData['total_expenses'] ?? 0;
    final netIncome = _reportData['net_income'] ?? 0;
    final incomeByCategory = List<Map<String, dynamic>>.from(_reportData['income_by_category'] ?? []);
    final expensesByCategory = List<Map<String, dynamic>>.from(_reportData['expenses_by_category'] ?? []);
    final dateRange = _reportData['date_range'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Income',
                '₹${double.parse(totalIncome.toString()).toStringAsFixed(2)}',
                Icons.arrow_upward,
                Colors.green,
              ),
              _buildStatCard(
                'Total Expenses',
                '₹${double.parse(totalExpenses.toString()).toStringAsFixed(2)}',
                Icons.arrow_downward,
                Colors.red,
              ),
              _buildStatCard(
                'Net Income',
                '₹${double.parse(netIncome.toString()).toStringAsFixed(2)}',
                netIncome >= 0 ? Icons.trending_up : Icons.trending_down,
                netIncome >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Income by Category
          if (incomeByCategory.isNotEmpty) ...[
            const Text(
              'Income by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildCategoryList(incomeByCategory, Colors.green),
            const SizedBox(height: 24),
          ],

          // Expenses by Category
          if (expensesByCategory.isNotEmpty) ...[
            const Text(
              'Expenses by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildCategoryList(expensesByCategory, Colors.red),
            const SizedBox(height: 24),
          ],

          // Date Range
          if (dateRange.isNotEmpty)
            Text(
              'Date Range: ${dateRange['start_date']} to ${dateRange['end_date']}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // Build category list items
  List<Widget> _buildCategoryList(List<Map<String, dynamic>> categories, Color color) {
    return categories.map((category) {
      final amount = double.parse(category['total']?.toString() ?? '0');
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              color == Colors.green ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            (category['category'] ?? 'Uncategorized').toString().capitalize(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  // Build sessions report
  Widget _buildSessionsReport() {
    final sessions = List<Map<String, dynamic>>.from(_reportData['sessions'] ?? []);
    final summary = _reportData['summary'] ?? {};
    final pagination = _reportData['pagination'] ?? {};

    if (sessions.isEmpty) return _buildNoData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Sessions',
                '${summary['total_sessions'] ?? sessions.length}',
                Icons.medical_services,
                Colors.blue,
              ),
              if (summary['average_duration'] != null)
                _buildStatCard(
                  'Avg. Duration',
                  '${summary['average_duration']} min',
                  Icons.timer,
                  Colors.orange,
                ),
              if (summary['unique_patients'] != null)
                _buildStatCard(
                  'Unique Patients',
                  '${summary['unique_patients']}',
                  Icons.people,
                  Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sessions List
          const Text(
            'Completed Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sessions.map((session) => _buildSessionCard(session)).toList(),
          
          // Pagination Info
          if (pagination.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Showing ${pagination['from']}-${pagination['to']} of ${pagination['total']} sessions',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Build session card
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final date = DateTime.parse(session['session_date'] ?? DateTime.now().toString());
    final startTime = DateTime.parse(session['start_time'] ?? DateTime.now().toString());
    final endTime = DateTime.parse(session['end_time'] ?? DateTime.now().toString());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session['patient_name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${session['time'] ?? 'N/A'} minutes',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  session['type']?.toString().replaceAll('_', ' ').capitalize() ?? 'N/A',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (session['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session['notes'],
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build patients report
  Widget _buildPatientsReport() {
    final patients = List<Map<String, dynamic>>.from(_reportData['patients'] ?? []);
    final summary = _reportData['summary'] ?? {};
    final pagination = _reportData['pagination'] ?? {};
    final genderDistribution = Map<String, dynamic>.from(summary['gender_distribution'] ?? {});
    final ageDistribution = Map<String, dynamic>.from(summary['age_distribution'] ?? {});
    final newPatientsLast6Months = Map<String, dynamic>.from(summary['new_patients_last_6_months'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Patients',
                '${summary['total_patients'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              ...genderDistribution.entries.map((entry) => _buildStatCard(
                entry.key.capitalize(),
                '${entry.value}',
                entry.key.toLowerCase() == 'male' ? Icons.male : Icons.female,
                entry.key.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
              )).toList(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Patients List
          if (patients.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Patient List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...patients.map((patient) => _buildPatientCard(patient)).toList(),
          ],
          
          // No Patients Message
          if (patients.isEmpty) ...[
            const SizedBox(height: 24),
            _buildNoData(),
          ],
          
          // Pagination Info
          if (pagination.isNotEmpty && pagination['total'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Showing ${pagination['from'] ?? 0}-${pagination['to'] ?? 0} of ${pagination['total']} patients',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  // Build age distribution item
  Widget _buildAgeDistributionItem(String range, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              range,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: count / (_reportData['summary']?['total_patients'] ?? 1),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor.withOpacity(0.7),
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Build patient card
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final joinDate = DateTime.tryParse(patient['created_at'] ?? '');
    final age = patient['age'] != null ? '${patient['age']} years' : 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patient['email'] ?? 'No email',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.phone, patient['phone'] ?? 'No phone'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.cake, age),
                if (patient['gender'] != null) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    patient['gender']?.toLowerCase() == 'male' 
                        ? Icons.male 
                        : Icons.female,
                    patient['gender'] ?? '',
                  ),
                ],
              ],
            ),
            if (patient['address']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patient['address'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (joinDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Member since ${DateFormat('MMM d, yyyy').format(joinDate)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build info chip
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Add this key at the top of the _ReportsScreenState class
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3; // Reports is at index 3 in the sidebar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadReportData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          _buildReportTypeSelector(),
          if (_errorMessage != null) _buildErrorMessage(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _selectedReport == 'general'
                    ? _buildGeneralDashboard()
                    : _selectedReport == 'appointments'
                        ? _buildAppointmentsReport()
                        : _selectedReport == 'payments'
                            ? _buildPaymentsReport()
                            : _selectedReport == 'sessions'
                                ? _buildSessionsReport()
                                : _selectedReport == 'patients'
                                    ? _buildPatientsReport()
                                    : _buildNoData(),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
