import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../models/reservation.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';
import '../services/reservation_service.dart';
import '../screens/reservation_edit_screen.dart';
import '../providers/theme_provider.dart';

class TaskManagementScreen extends ConsumerStatefulWidget {
  final int reservationId;

  const TaskManagementScreen({required this.reservationId, super.key});

  @override
  ConsumerState<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends ConsumerState<TaskManagementScreen> {
  final TaskService taskService = TaskService(ApiService());
  final ReservationService reservationService = ReservationService(ApiService());
  List<Task> tasks = [];
  Reservation? reservation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      reservation = (await reservationService.getReservations())
          .firstWhere((r) => r.id == widget.reservationId, orElse: () => throw Exception('Réservation non trouvée'));
      tasks = await taskService.getTasks();
      tasks = tasks.where((task) => task.reservationId == widget.reservationId).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelTask(int taskId) async {
    print('Attempting to cancel task ID: $taskId');
    try {
      await taskService.cancelTask(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tâche annulée avec succès')),
      );
      _loadData();
    } catch (e) {
      String errorMessage = 'Erreur lors de l\'annulation';
      if (e is DioError && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('etat')) {
          errorMessage = 'Erreur : ${responseData['etat'].join(', ')}';
        } else if (responseData is Map && responseData.containsKey('detail')) {
          errorMessage = responseData['detail'].toString();
        } else {
          errorMessage = 'Erreur : ${e.response!.data.toString()}';
        }
      } else {
        errorMessage = e.toString();
      }
      print('Raw exception for task cancellation: $e');
      print('Cancellation error: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    print('Attempting to cancel reservation ID: $reservationId');
    try {
      await reservationService.cancelReservation(reservationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation annulée avec succès')),
      );
      _loadData();
    } catch (e) {
      String errorMessage = 'Erreur lors de l\'annulation';
      if (e is DioError && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('detail')) {
          errorMessage = responseData['detail'].toString();
        } else {
          errorMessage = 'Erreur : ${e.response!.data.toString()}';
        }
      } else {
        errorMessage = e.toString();
      }
      print('Raw exception for reservation cancellation: $e');
      print('Cancellation error: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('manage_tasks')),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (reservation != null && reservation!.status != 'checked_in' && reservation!.status != 'checked_out')
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _cancelReservation(reservation!.id),
              tooltip: 'Annuler la réservation',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? Center(child: Text(l10n.translate('no_tasks')))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final canCancel = task.etat != 'terminee' &&
                        task.etat != 'annulee' &&
                        (reservation?.status ?? '') != 'checked_out';
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: theme.isDarkMode ? Colors.grey[800] : Colors.white,
                      child: ListTile(
                        title: Text(
                          'Tâche #${task.id} - ${task.serviceName}',
                          style: TextStyle(
                            color: theme.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.translate('status')}: ${task.etat}',
                              style: TextStyle(
                                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              'Date: ${task.dateService} ${task.heureService ?? ''}',
                              style: TextStyle(
                                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        trailing: canCancel
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _cancelTask(task.id),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (reservation != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationEditScreen(reservation: reservation!),
              ),
            ).then((_) => _loadData());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Réservation non chargée')),
            );
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}