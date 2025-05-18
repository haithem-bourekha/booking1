import 'package:flutter/material.dart';
import './room.dart';

class Reservation {
  final int id;
  final Room room;
  final int user;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nombreAdultes;
  final int nombreEnfants;
  final String? status;
  final DateTime createdAt;
  final double totalPrice;

  Reservation({
    required this.id,
    required this.room,
    required this.user,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nombreAdultes,
    required this.nombreEnfants,
    this.status,
    required this.createdAt,
    required this.totalPrice,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: int.parse(json['id'].toString()),
      room: Room.fromJson(json['room']),
      user: int.parse(json['client']['id'].toString()),
      checkInDate: DateTime.parse(json['date_debut']),
      checkOutDate: DateTime.parse(json['date_fin']),
      nombreAdultes: int.parse(json['nombre_adultes'].toString()),
      nombreEnfants: int.parse(json['nombre_enfants'].toString()),
      status: json['statut'],
      createdAt: DateTime.parse(json['created_at']),
      totalPrice: double.parse(json['prix_total'].toString()),
    );
  }
}