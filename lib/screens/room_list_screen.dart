import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/room.dart';
import '../services/room_service.dart';
import '../services/api_service.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomService = RoomService(ApiService());
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('room_tab')),
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
      body: FutureBuilder<List<Room>>(
        future: roomService.getRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(l10n.translate('error', params: {'error': snapshot.error.toString()})));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.translate('no_rooms_available')));
          }
          print('Chambres chargées: ${snapshot.data!.length}');
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final room = snapshot.data![index];
              return FutureBuilder<bool>(
                future: roomService.isFavorite(room.id),
                builder: (context, favoriteSnapshot) {
                  bool isFavorite = favoriteSnapshot.data ?? false;
                  return RoomCard(
                    room: room,
                    isFavorite: isFavorite,
                    onFavorite: () async {
                      try {
                        if (isFavorite) {
                          await roomService.removeFavorite(room.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.translate('removed_from_favorites'))),
                          );
                        } else {
                          await roomService.addFavorite(room.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.translate('added_to_favorites'))),
                          );
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RoomListScreen()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}