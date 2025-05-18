import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Ajout pour formater la date
import '../l10n/app_localizations.dart';
import '../main.dart'; // Importer pour accéder à languageProvider
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'profile_update_screen.dart';
import 'hotel_info_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  late Future<List<Task>> _tasksFuture;
  final taskService = TaskService(ApiService());

  @override
  void initState() {
    super.initState();
    _tasksFuture = taskService.getTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = taskService.getTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final user = ref.watch(authProvider)!;
        final language = ref.watch(languageProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('employee_dashboard')),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  child: Text(
                    l10n.translate('welcome_user', params: {
                      'username': user.nom ?? user.username ?? 'Utilisateur',
                    }),
                  ),
                ),
                // Sélecteur de langue
                ListTile(
                  title: DropdownButton<Locale>(
                    value: language.locale,
                    isExpanded: true,
                    items: AppLocalizations.supportedLocales.map((locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(l10n.translate('language_${locale.languageCode}')),
                      );
                    }).toList(),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        ref.read(languageProvider.notifier).setLocale(newLocale);
                        Navigator.pop(context); // Ferme le Drawer après sélection
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text(l10n.translate('update_profile')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileUpdateScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(l10n.translate('hotel_info')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HotelInfoScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: FutureBuilder<List<Task>>(
            future: _tasksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    l10n.translate('error', params: {'error': snapshot.error.toString()}),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(l10n.translate('no_tasks_found')));
              }
              final tasks = snapshot.data!;
              // Filtrer les tâches pour aujourd'hui
              final today = DateTime.now().toLocal();
              final todaysTasks = tasks.where((task) {
                final taskDate = task.dateService.toLocal();
                return taskDate.year == today.year &&
                    taskDate.month == today.month &&
                    taskDate.day == today.day;
              }).toList();

              if (todaysTasks.isEmpty) {
                return Center(child: Text(l10n.translate('no_tasks_today')));
              }

              return ListView.builder(
                itemCount: todaysTasks.length,
                itemBuilder: (context, index) {
                  final task = todaysTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(
                        l10n.translate('task', params: {
                          'id': task.id.toString(),
                          'state': l10n.translate('state_${task.etat}'),
                        }),
                      ),
                      subtitle: Text(
                        l10n.translate('date', params: {
                          'date': DateFormat('dd/MM/yyyy').format(task.dateService), // Formatage de DateTime en String
                          'time': task.heureService ?? '',
                        }),
                      ),
                      trailing: DropdownButton<String>(
                        value: task.etat,
                        items: ['en_attente', 'en_cours', 'terminee', 'annulee']
                            .map((state) => DropdownMenuItem(
                                  value: state,
                                  child: Text(l10n.translate('state_$state')),
                                ))
                            .toList(),
                        onChanged: (newState) async {
                          if (newState != null && newState != task.etat) {
                            try {
                              await taskService.updateTask(task.id, newState);
                              _refreshTasks();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.translate('state_updated_to', params: {
                                      'state': l10n.translate('state_$newState'),
                                    }),
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.translate('error', params: {'error': e.toString()}),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}