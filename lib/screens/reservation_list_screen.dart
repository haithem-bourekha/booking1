import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import './task_management_screen.dart';
import './reservation_edit_screen.dart';

class ReservationListScreen extends ConsumerWidget {
  const ReservationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationService = ReservationService(ApiService()); // Utilisation du singleton
    final taskService = TaskService(ApiService()); // Utilisation du singleton
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('reservations_list')),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<Locale>(
            value: language.locale,
            isExpanded: false,
            items: AppLocalizations.supportedLocales.map((locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(l10n.translate('language_${locale.languageCode}')),
              );
            }).toList(),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                ref.read(languageProvider.notifier).setLocale(newLocale);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Reservation>>(
        future: reservationService.getReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.translate('error', params: {'error': snapshot.error.toString()}),
                style: TextStyle(
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                l10n.translate('no_reservations_found'),
                style: TextStyle(
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final reservation = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                color: theme.isDarkMode ? Colors.grey[800] : Colors.white,
                child: ListTile(
                  leading: Icon(
                    Icons.book,
                    color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  title: Text(
                    l10n.translate('reservation') +
                        ' #${reservation.id} - ' +
                        l10n.translate('room', params: {'number': reservation.room.number.toString()}),
                    style: TextStyle(
                      color: theme.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('from_to', params: {
                          'from': reservation.checkInDate.toString().split(' ')[0],
                          'to': reservation.checkOutDate.toString().split(' ')[0]
                        }),
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        l10n.translate('adults_children', params: {
                          'adults': reservation.nombreAdultes.toString(),
                          'children': reservation.nombreEnfants.toString()
                        }),
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        l10n.translate('status') + ': ${reservation.status ?? l10n.translate('unknown')}',
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        l10n.translate('total_price') + ': ${reservation.totalPrice} DZD',
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        l10n.translate('created_on') + ': ${reservation.createdAt.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reservation.status != 'checked_out')
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationEditScreen(reservation: reservation),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await reservationService.cancelReservation(reservation.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.translate('reservation_canceled_success'))),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ReservationListScreen()),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.translate('error_cancelling_reservation') + ': ${e.toString()}')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      IconButton(
                        icon: const Icon(Icons.room_service, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskManagementScreen(reservationId: reservation.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}