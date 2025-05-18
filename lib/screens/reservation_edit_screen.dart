import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/reservation.dart';
import '../models/service.dart';
import '../services/reservation_service.dart';
import '../services/service_service.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

class ReservationEditScreen extends ConsumerStatefulWidget {
  final Reservation reservation;

  const ReservationEditScreen({required this.reservation, super.key});

  @override
  ConsumerState<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends ConsumerState<ReservationEditScreen> {
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _nombreAdultes;
  late int _nombreEnfants;
  late String _roomTypeId;

  // Variables pour la demande de service
  List<Service> _availableServices = [];
  Service? _selectedService;
  DateTime? _serviceDate;
  TimeOfDay? _serviceTime;
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.reservation.checkInDate;
    _checkOutDate = widget.reservation.checkOutDate;
    _nombreAdultes = widget.reservation.nombreAdultes;
    _nombreEnfants = widget.reservation.nombreEnfants;
    _roomTypeId = widget.reservation.room.type.id.toString();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final serviceService = ServiceService(ApiService());
    try {
      _availableServices = await serviceService.getServices();
      setState(() {
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des services: $e')),
      );
    }
  }

  Future<void> _addServiceRequest() async {
    if (_selectedService == null || _serviceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner un service et une date')),
      );
      return;
    }

    final taskService = TaskService(ApiService());
    try {
      await taskService.createTask(
        reservationId: widget.reservation.id,
        roomId: widget.reservation.room.id,
        serviceId: _selectedService!.id,
        dateService: _serviceDate!.toIso8601String().split('T')[0],
        heureService: _serviceTime != null
            ? '${_serviceTime!.hour.toString().padLeft(2, '0')}:${_serviceTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande de service ajoutée avec succès')),
      );
      setState(() {
        _selectedService = null;
        _serviceDate = null;
        _serviceTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de la demande: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    final reservationService = ReservationService(ApiService());
    try {
      await reservationService.updateReservation(
        widget.reservation.id,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        nombreAdultes: _nombreAdultes,
        nombreEnfants: _nombreEnfants,
        roomTypeId: int.parse(_roomTypeId),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation mise à jour avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier la Réservation'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section pour modifier les détails de la réservation
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('check_in')),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _checkInDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _checkInDate = picked);
                },
                controller: TextEditingController(
                  text: _checkInDate.toIso8601String().split('T')[0],
                ),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('check_out')),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _checkOutDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _checkOutDate = picked);
                },
                controller: TextEditingController(
                  text: _checkOutDate.toIso8601String().split('T')[0],
                ),
                readOnly: true,
              ),
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('adults')),
                keyboardType: TextInputType.number,
                onChanged: (value) => _nombreAdultes = int.tryParse(value) ?? _nombreAdultes,
                controller: TextEditingController(text: _nombreAdultes.toString()),
              ),
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('children')),
                keyboardType: TextInputType.number,
                onChanged: (value) => _nombreEnfants = int.tryParse(value) ?? _nombreEnfants,
                controller: TextEditingController(text: _nombreEnfants.toString()),
              ),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text(l10n.translate('update')),
              ),

              // Section pour ajouter une demande de service
              const SizedBox(height: 20),
              Text(
                'Ajouter une Demande de Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _isLoadingServices
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButton<Service>(
                      value: _selectedService,
                      hint: Text(l10n.translate('select_service')),
                      isExpanded: true,
                      items: _availableServices.map((service) {
                        return DropdownMenuItem<Service>(
                          value: service,
                          child: Text(service.nom),
                        );
                      }).toList(),
                      onChanged: (Service? newValue) {
                        setState(() {
                          _selectedService = newValue;
                        });
                      },
                    ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('select_date')),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.reservation.checkInDate, // Date initiale = début de la réservation
                    firstDate: widget.reservation.checkInDate, // Limite inférieure
                    lastDate: widget.reservation.checkOutDate, // Limite supérieure
                  );
                  if (picked != null) setState(() => _serviceDate = picked);
                },
                controller: TextEditingController(
                  text: _serviceDate != null
                      ? _serviceDate!.toIso8601String().split('T')[0]
                      : '',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: l10n.translate('select_time')),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _serviceTime = picked);
                },
                controller: TextEditingController(
                  text: _serviceTime != null
                      ? '${_serviceTime!.hour.toString().padLeft(2, '0')}:${_serviceTime!.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addServiceRequest,
                child: Text(l10n.translate('add')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}