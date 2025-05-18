class Room {
  final int id;
  final String number;
  final String? description; // Nullable
  final int etage;
  final String? photo; // Nullable
  final RoomType type;
  final String? status; // Nullable

  Room({
    required this.id,
    required this.number,
    this.description,
    required this.etage,
    this.photo,
    required this.type,
    this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: int.parse(json['id'].toString()),
      number: json['number'],
      description: json['description'],
      etage: int.parse(json['etage'].toString()),
      photo: json['photo'],
      type: RoomType.fromJson(json['type']),
      status: json['status'],
    );
  }
}

class RoomType {
  final int id;
  final String nom;
  final double prixNuit;
  final int maxAdulte;
  final int maxEnfant;

  RoomType({
    required this.id,
    required this.nom,
    required this.prixNuit,
    required this.maxAdulte,
    required this.maxEnfant,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: int.parse(json['id'].toString()),
      nom: json['nom'],
      prixNuit: double.parse(json['prix_nuit'].toString()),
      maxAdulte: int.parse(json['max_adulte'].toString()),
      maxEnfant: int.parse(json['max_enfant'].toString()),
    );
  }
}