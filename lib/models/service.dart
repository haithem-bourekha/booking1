class Service {
  final int id;
  final String nom;
  final String? description;
  final double? salaireEmploye;
  final double? prixClient;
  final String? photo;

  Service({
    required this.id,
    required this.nom,
    this.description,
    this.salaireEmploye,
    this.prixClient,
    this.photo,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: int.parse(json['id'].toString()),
      nom: json['nom'] ?? 'Sans nom',
      description: json['description'],
      salaireEmploye: json['salaire_employe'] != null ? double.parse(json['salaire_employe'].toString()) : null,
      prixClient: json['prix_client'] != null ? double.parse(json['prix_client'].toString()) : null,
      photo: json['photo'],
    );
  }
}