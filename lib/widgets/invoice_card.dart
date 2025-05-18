import 'package:flutter/material.dart';
import '../models/invoice.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const InvoiceCard({required this.invoice, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Facture #${invoice.id}'),
        subtitle: Text('Total: ${invoice.totalAmount} DZD - Statut: ${invoice.paymentStatus ? "Payé" : "En attente"}'),
        trailing: Text('Réservation #${invoice.reservationId}'),
      ),
    );
  }
}