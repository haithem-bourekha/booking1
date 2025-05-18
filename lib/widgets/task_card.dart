import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ajout pour formater la date
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Task ${task.id} - ${task.serviceName}'),
        subtitle: Text('Client ID: ${task.clientId}'),
        trailing: Text(DateFormat('dd/MM/yyyy').format(task.dateService)), // Formatage de DateTime en String
      ),
    );
  }
}