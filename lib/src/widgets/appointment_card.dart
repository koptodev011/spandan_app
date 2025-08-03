import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.onTap,
    this.onCancel,
    this.onComplete,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appointment.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: _getStatusColor(appointment.status).withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16.0,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(appointment.dateTime),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (appointment.purpose.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16.0,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        appointment.purpose,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (onCancel != null || onComplete != null) ...[
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('CANCEL'),
                      ),
                    if (onComplete != null) ...[
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: onComplete,
                        child: const Text('COMPLETE'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
