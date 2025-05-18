import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import '../providers/theme_provider.dart';

class RoomCard extends ConsumerWidget {
  final Room room;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const RoomCard({
    super.key,
    required this.room,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      color: theme.isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: room.photo != null
            ? Image.network(
                room.photo!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              )
            : const Icon(Icons.hotel),
        title: Text(
          'Chambre ${room.number}',
          style: TextStyle(
            color: theme.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.description ?? 'Pas de description',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Type: ${room.type.nom}',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Prix: ${room.type.prixNuit} DZD/nuit',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Étage: ${room.etage}',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Statut: ${room.status ?? 'Inconnu'}',
              style: TextStyle(
                color: theme.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : (theme.isDarkMode ? Colors.white70 : Colors.grey),
          ),
          onPressed: onFavorite,
        ),
      ),
    );
  }
}