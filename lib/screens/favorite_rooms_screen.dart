import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/room.dart';
import '../services/room_service.dart';
import '../services/api_service.dart';
import '../widgets/room_card.dart';
import '../providers/theme_provider.dart';

class FavoriteRoomsScreen extends ConsumerWidget {
  const FavoriteRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomService = RoomService(ApiService());
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('favorite_rooms')),
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
      body: FutureBuilder<List<Room>>(
        future: roomService.getFavoriteRooms(),
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
                l10n.translate('no_favorite_rooms'),
                style: TextStyle(
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            );
          }
          print('Favoris chargés: ${snapshot.data!.length}');
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final room = snapshot.data![index];
              return RoomCard(
                room: room,
                isFavorite: true,
                onFavorite: () async {
                  try {
                    await roomService.removeFavorite(room.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('removed_from_favorites'))),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoriteRoomsScreen()),
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
      ),
    );
  }
}