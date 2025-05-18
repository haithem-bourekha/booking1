class Task {
  final int id;
  final int reservationId;
  final int roomId;
  final int serviceId;
  final String serviceName; // Ajout pour service.nom
  final String etat;
  final DateTime dateService; // Changé de String à DateTime
  final String? heureService;
  final int clientId; // Ajout pour reservation.client.id

  Task({
    required this.id,
    required this.reservationId,
    required this.roomId,
    required this.serviceId,
    required this.serviceName,
    required this.etat,
    required this.dateService,
    this.heureService,
    required this.clientId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reservationId: int.tryParse(json['reservation']?['id']?.toString() ?? '') ?? 0,
      roomId: int.tryParse(json['room']?['id']?.toString() ?? '') ?? 0,
      serviceId: int.tryParse(json['service']?['id']?.toString() ?? '') ?? 0,
      serviceName: json['service']?['nom']?.toString() ?? 'Inconnu',
      etat: json['etat']?.toString() ?? 'inconnu',
      dateService: DateTime.tryParse(json['date_service']?.toString() ?? '') ?? DateTime(2000, 1, 1), // Conversion en DateTime
      heureService: json['heure_service']?.toString(),
      clientId: int.tryParse(json['reservation']?['client']?['id']?.toString() ?? '') ?? 0,
    );
  }
}