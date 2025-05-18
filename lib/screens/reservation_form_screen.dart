import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../l10n/app_localizations.dart';
import '../models/room.dart';
import '../models/service.dart';
import '../services/room_service.dart';
import '../services/reservation_service.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ReservationFormScreen extends StatefulWidget {
  final int? roomId;

  const ReservationFormScreen({super.key, this.roomId});

  @override
  _ReservationFormScreenState createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final RoomService roomService = RoomService(ApiService());
  final ReservationService reservationService = ReservationService(ApiService());
  final InvoiceService invoiceService = InvoiceService(ApiService());
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int adults = 1;
  int children = 0;
  bool isLoading = false;
  String? errorMessage;
  Room? selectedRoom;
  List<Room> alternativeRooms = [];
  List<Service> availableServices = [];
  List<int> selectedServices = [];
  Map<int, List<DateTime>> selectedServiceDays = {};
  bool showServiceSelection = false;
  bool showPaymentScreen = false;
  bool servicesLoaded = false;

  final _formKey = GlobalKey<FormState>();
  String? cardType;
  String? cardNumber;
  String? expiryDate;
  String? cvv;

  double loyaltyPoints = 0.0;
  int? reservationId; // Stocker l'ID de la réservation pour annulation si besoin

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _loadRoom();
      _loadServices();
    }
  }

  Future<void> _loadRoom() async {
    try {
      final rooms = await roomService.getRooms();
      if (rooms.isEmpty) {
        setState(() {
          errorMessage = AppLocalizations.of(context).translate('no_rooms_available');
        });
        return;
      }
      final room = rooms.firstWhere((r) => r.id == widget.roomId);
      setState(() {
        selectedRoom = room;
      });
    } catch (e) {
      setState(() {
        errorMessage = AppLocalizations.of(context).translate('error_loading_room', params: {'error': e.toString()});
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      final response = await ApiService().get(servicesEndpoint);
      if (response.data is List) {
        setState(() {
          availableServices = (response.data as List)
              .map((json) => Service.fromJson(json))
              .toList();
          servicesLoaded = true;
        });
      } else {
        setState(() {
          errorMessage = AppLocalizations.of(context).translate('error_loading_services_invalid_data');
          servicesLoaded = true;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des services: $e');
      setState(() {
        errorMessage = AppLocalizations.of(context).translate('error_loading_services', params: {'error': e.toString()});
        servicesLoaded = true;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(2026);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: checkInDate != null && checkOutDate != null
          ? DateTimeRange(start: checkInDate!, end: checkOutDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.lightBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        );
      },
    );

    if (picked != null) {
      if (picked.end.isBefore(picked.start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('checkout_before_checkin_error'))),
        );
        return;
      }
      if (picked.start != checkInDate || picked.end != checkOutDate) {
        setState(() {
          checkInDate = picked.start;
          checkOutDate = picked.end;
          _updateLoyaltyPoints();
        });
      }
    }
  }

  void _updateLoyaltyPoints() {
    if (checkInDate != null && checkOutDate != null) {
      final nights = checkOutDate!.difference(checkInDate!).inDays;
      setState(() {
        loyaltyPoints = nights * 50.0;
      });
    }
  }

  Future<void> _validateAndSelectServices() async {
    final l10n = AppLocalizations.of(context);
    if (checkInDate == null || checkOutDate == null) {
      setState(() {
        errorMessage = l10n.translate('select_dates_error');
      });
      return;
    }
    if (checkOutDate!.isBefore(checkInDate!)) {
      setState(() {
        errorMessage = l10n.translate('checkout_before_checkin_error');
      });
      return;
    }

    if (selectedRoom == null) {
      setState(() {
        errorMessage = l10n.translate('room_not_loaded');
      });
      return;
    }

    if (selectedRoom!.status == 'booked') {
      setState(() {
        errorMessage = l10n.translate('room_already_booked');
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      alternativeRooms = [];
    });

    try {
      final isAvailable = await roomService.checkAvailability(selectedRoom!.id, checkInDate!, checkOutDate!);

      final totalPeople = adults + children;
      final roomCapacity = selectedRoom!.type.maxAdulte + selectedRoom!.type.maxEnfant;

      if (!isAvailable || totalPeople > roomCapacity) {
        final alternatives = await roomService.findAlternativeRooms(
          selectedRoom!,
          checkInDate!,
          checkOutDate!,
          adults,
          children,
        );

        setState(() {
          isLoading = false;
          alternativeRooms = alternatives;
          errorMessage = !isAvailable
              ? l10n.translate('room_unavailable')
              : l10n.translate('room_capacity_exceeded', params: {'total': totalPeople.toString(), 'capacity': roomCapacity.toString()});
        });

        if (alternatives.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('alternative_rooms_available'))),
          );
        } else {
          setState(() {
            errorMessage = l10n.translate('no_alternative_rooms_same_type');
            showServiceSelection = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('no_alternative_rooms')),
              action: SnackBarAction(
                label: l10n.translate('cancel_and_return_home'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
          showServiceSelection = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        if (e.toString().contains('Cette chambre est déjà réservée')) {
          errorMessage = l10n.translate('room_already_booked');
        } else {
          errorMessage = l10n.translate('error', params: {'error': e.toString()});
        }
      });
    }
  }

  void _selectAlternativeRoom(Room room) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      selectedRoom = room;
      alternativeRooms = [];
      errorMessage = null;
      showServiceSelection = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('alternative_room_selected'))),
    );
  }

  void _toggleService(int serviceId, bool applyAllDays) {
    setState(() {
      if (selectedServices.contains(serviceId)) {
        selectedServices.remove(serviceId);
        selectedServiceDays.remove(serviceId);
      } else {
        selectedServices.add(serviceId);
        if (applyAllDays) {
          final days = _getAllDays();
          selectedServiceDays[serviceId] = days;
        } else {
          selectedServiceDays[serviceId] = [];
        }
      }
    });
  }

  List<DateTime> _getAllDays() {
    if (checkInDate == null || checkOutDate == null) return [];
    final days = <DateTime>[];
    var currentDay = checkInDate!.toLocal();
    while (currentDay.isBefore(checkOutDate!) || currentDay.isAtSameMomentAs(checkOutDate!)) {
      days.add(currentDay);
      currentDay = currentDay.add(const Duration(days: 1));
    }
    return days;
  }

  Future<void> _selectSpecificDays(int serviceId) async {
    final l10n = AppLocalizations.of(context);
    final selected = selectedServiceDays[serviceId] ?? [];
    final availableDays = _getAllDays();

    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('no_reservation_period'))),
      );
      return;
    }

    final List<DateTime> picked = await showDialog<List<DateTime>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('select_service_days', params: {'service': availableServices.firstWhere((s) => s.id == serviceId).nom})),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('reservation_dates'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...availableDays.map((day) => CheckboxListTile(
                      title: Text(
                        DateFormat('dd/MM/yyyy (EEEE)').format(day),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: selected.contains(day),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selected.add(day);
                          } else {
                            selected.remove(day);
                          }
                          selectedServiceDays[serviceId] = selected;
                        });
                      },
                      activeColor: const Color.fromARGB(255, 117, 153, 251),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(l10n.translate('ok'), style: const TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(l10n.translate('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    ) ?? selected;

    setState(() {
      selectedServiceDays[serviceId] = picked;
    });
  }

  double _calculateTotal() {
    if (selectedRoom == null || checkInDate == null || checkOutDate == null) return 0.0;
    final nights = checkOutDate!.difference(checkInDate!).inDays;
    double roomTotal = selectedRoom!.type.prixNuit * nights / 1000;
    double serviceTotal = 0.0;
    for (int serviceId in selectedServices) {
      final service = availableServices.firstWhere((s) => s.id == serviceId);
      final days = selectedServiceDays[serviceId] ?? _getAllDays();
      serviceTotal += (service.prixClient ?? 0.0) * days.length;
    }
    return roomTotal + serviceTotal;
  }

  Future<void> _showPaymentScreen() async {
    setState(() {
      showPaymentScreen = true;
    });
  }

  Future<void> _confirmPayment() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Créer la réservation
        final response = await reservationService.createReservation(
          roomId: selectedRoom!.id,
          checkInDate: checkInDate!,
          checkOutDate: checkOutDate!,
          nombreAdultes: adults,
          nombreEnfants: children,
          services: selectedServices,
          serviceDays: selectedServiceDays,
        );
        print('Reservation created: ${response.data}');

        // Récupérer l'invoice_id et reservation_id depuis la réponse
        final invoiceId = response.data['invoice_id'];
        reservationId = response.data['reservation_id'];
        print('Invoice ID: $invoiceId, Reservation ID: $reservationId');

        // Vérifier si invoiceId est null
        if (invoiceId == null) {
          throw Exception('Erreur: invoice_id non reçu de l\'API');
        }

        // Effectuer le paiement
        final paymentResponse = await invoiceService.payInvoice(
          invoiceId: invoiceId,
          paymentMethod: 'card',
          cardNumber: cardNumber!,
          cardExpiry: expiryDate!,
          cardCvc: cvv!,
        );
        print('Payment response: $paymentResponse');

        setState(() {
          isLoading = false;
          showPaymentScreen = false;
          showServiceSelection = false;
          selectedServices.clear();
          selectedServiceDays.clear();
          cardType = null;
          cardNumber = null;
          expiryDate = null;
          cvv = null;
          reservationId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('reservation_confirmed'))),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Payment error: $e');
        // Si le paiement échoue, annuler la réservation
        if (reservationId != null) {
          try {
            await reservationService.cancelReservation(reservationId!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('reservation_cancelled_due_to_payment_failure'))),
            );
          } catch (cancelError) {
            print('Cancel error: $cancelError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('error_cancelling_reservation', params: {'error': cancelError.toString()}))),
            );
          }
        }

        setState(() {
          isLoading = false;
          errorMessage = l10n.translate('payment_error', params: {'error': e.toString()});
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('payment_error', params: {'error': e.toString()}))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('fix_form_errors'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('reservation_form'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 73, 93, 248),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 79, 71, 242)))
          : selectedRoom == null
              ? const Center(child: Text('Loading room...', style: TextStyle(color: Colors.black54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: selectedRoom?.photo != null
                                  ? NetworkImage(selectedRoom!.photo!)
                                  : const AssetImage('assets/images/default_room.jpg') as ImageProvider,
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('Erreur de chargement de l\'image : $exception');
                              },
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.translate('room', params: {'number': selectedRoom!.number.toString()}) + ' - ${selectedRoom!.type.nom}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (selectedRoom?.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            selectedRoom!.description!,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        l10n.translate('price_per_night', params: {'price': (selectedRoom!.type.prixNuit / 1000).toStringAsFixed(1)}),
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      Text(
                        l10n.translate('floor', params: {'floor': selectedRoom!.etage.toString()}),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 24),
                      FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('customer_reviews'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color.fromARGB(255, 83, 110, 248), size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8 (120 avis)',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '"Chambre très propre et confortable, excellent service !"',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.translate('select_dates'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _selectDateRange(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      checkInDate == null
                                          ? l10n.translate('check_in')
                                          : '${l10n.translate('check_in')} ${DateFormat('dd MMMM yyyy').format(checkInDate!)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: checkInDate == null ? Colors.black54 : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      checkOutDate == null
                                          ? l10n.translate('check_out')
                                          : '${l10n.translate('check_out')} ${DateFormat('dd MMMM yyyy').format(checkOutDate!)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: checkOutDate == null ? Colors.black54 : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (checkInDate != null && checkOutDate != null)
                              Text(
                                '${DateFormat('EEEE').format(checkInDate!)} - ${DateFormat('EEEE').format(checkOutDate!)}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.translate('adults'), style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.black54),
                                      onPressed: adults > 1 ? () => setState(() => adults--) : null,
                                    ),
                                    Text('$adults', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.black54),
                                      onPressed: () => setState(() => adults++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.translate('children'), style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.black54),
                                      onPressed: children > 0 ? () => setState(() => children--) : null,
                                    ),
                                    Text('$children', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.black54),
                                      onPressed: () => setState(() => children++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null && errorMessage != l10n.translate('no_alternative_rooms_same_type'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      if (alternativeRooms.isNotEmpty)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('alternative_rooms'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              ...alternativeRooms.map((room) => Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        l10n.translate('room', params: {'number': room.number.toString()}) + ' - ${room.type.nom}',
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        l10n.translate('price', params: {'price': (room.type.prixNuit / 1000).toStringAsFixed(1)}),
                                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () => _selectAlternativeRoom(room),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.translate('select'),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.redAccent,
                                  ),
                                  child: Text(
                                    l10n.translate('cancel_and_return_home'),
                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (alternativeRooms.isEmpty && errorMessage != null && errorMessage == l10n.translate('no_alternative_rooms_same_type'))
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            children: [
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.redAccent,
                                  ),
                                  child: Text(
                                    l10n.translate('cancel_and_return_home'),
                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (checkInDate != null && checkOutDate != null && showServiceSelection)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.translate('estimated_total'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  '${_calculateTotal().toStringAsFixed(2)}k DZD',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 68, 137, 249)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (!showServiceSelection && alternativeRooms.isEmpty && (errorMessage == null || errorMessage != l10n.translate('no_alternative_rooms_same_type')))
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _validateAndSelectServices,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                                shadowColor: Colors.lightBlueAccent,
                              ),
                              child: Text(
                                l10n.translate('validate_and_select_services'),
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      if (showServiceSelection && !showPaymentScreen)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('select_services'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 16),
                                if (!servicesLoaded)
                                  const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 66, 140, 244))),
                                if (servicesLoaded && availableServices.isEmpty)
                                  Text(
                                    l10n.translate('no_services_available'),
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ...availableServices.map((service) => Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: service.photo != null && service.photo!.isNotEmpty
                                            ? Image.network(
                                                service.photo!,
                                                width: 50,
                                                height: 50,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Image error for ${service.nom}: $error');
                                                  return const Icon(Icons.error, color: Colors.red);
                                                },
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const CircularProgressIndicator();
                                                },
                                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                  if (wasSynchronouslyLoaded) return child;
                                                  return AnimatedOpacity(
                                                    opacity: frame == null ? 0 : 1,
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeOut,
                                                    child: child,
                                                  );
                                                },
                                              )
                                            : const Icon(Icons.room_service, size: 50, color: Color.fromARGB(255, 64, 132, 250)),
                                        title: Expanded(
                                          child: Text(
                                            service.nom,
                                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        subtitle: Expanded(
                                          child: Text(
                                            service.prixClient != null
                                                ? l10n.translate('price', params: {'price': service.prixClient.toString()})
                                                : l10n.translate('price_not_available'),
                                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: selectedServices.contains(service.id),
                                              onChanged: (value) {
                                                _toggleService(service.id, true);
                                              },
                                              activeColor: const Color.fromARGB(255, 73, 141, 250),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.calendar_today, color: Colors.black54),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(
                                                      l10n.translate('apply_service', params: {'service': service.nom}),
                                                      style: const TextStyle(color: Colors.black87),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: const Icon(Icons.event, color: Color.fromARGB(255, 50, 105, 245)),
                                                          title: Text(
                                                            l10n.translate('whole_period'),
                                                            style: const TextStyle(color: Colors.black87),
                                                          ),
                                                          onTap: () {
                                                            _toggleService(service.id, true);
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.date_range, color: Color.fromARGB(255, 51, 132, 238)),
                                                          title: Text(
                                                            l10n.translate('specific_days'),
                                                            style: const TextStyle(color: Colors.black87),
                                                          ),
                                                          onTap: () {
                                                            _toggleService(service.id, false);
                                                            _selectSpecificDays(service.id);
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: Text(
                                                          l10n.translate('cancel'),
                                                          style: const TextStyle(color: Colors.grey),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 16),
                                if (selectedServices.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: selectedServices.map((serviceId) {
                                      final days = selectedServiceDays[serviceId] ?? [];
                                      final service = availableServices.firstWhere((s) => s.id == serviceId);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                service.nom,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                days.isEmpty
                                                    ? l10n.translate('whole_period')
                                                    : l10n.translate('days', params: {'days': days.map((d) => DateFormat('dd/MM').format(d)).join(', ')}),
                                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 16),
                                if (selectedServices.isNotEmpty)
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _showPaymentScreen,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.lightBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 5,
                                        shadowColor: Colors.lightBlueAccent,
                                      ),
                                      child: Text(
                                        l10n.translate('view_invoice_and_pay'),
                                        style: const TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (loyaltyPoints > 0 && showServiceSelection && !showPaymentScreen)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Color.fromARGB(255, 79, 144, 249)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.translate('loyalty_points_earned', params: {'points': loyaltyPoints.toStringAsFixed(0)}),
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (showPaymentScreen)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('reservation_invoice'),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F5F2),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l10n.translate('invoice'),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color.fromARGB(255, 59, 151, 237),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                l10n.translate('date') + ': ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(color: Color.fromARGB(255, 53, 110, 233), thickness: 1.5),
                                        const SizedBox(height: 10),
                                        Text(
                                          l10n.translate('reservation_details'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          l10n.translate('room') + ': ${selectedRoom!.number} - ${selectedRoom!.type.nom}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          l10n.translate('period') +
                                              ': ${DateFormat('dd/MM/yyyy').format(checkInDate!)} - ${DateFormat('dd/MM/yyyy').format(checkOutDate!)}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          l10n.translate('nights') + ': ${checkOutDate!.difference(checkInDate!).inDays}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          l10n.translate('room_cost',
                                              params: {'cost': ((selectedRoom!.type.prixNuit * checkOutDate!.difference(checkInDate!).inDays) / 1000).toStringAsFixed(2)}),
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          l10n.translate('selected_services'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 5),
                                        ...selectedServices.map((serviceId) {
                                          final service = availableServices.firstWhere((s) => s.id == serviceId);
                                          final days = selectedServiceDays[serviceId] ?? _getAllDays();
                                          final serviceCost = (service.prixClient ?? 0.0) * days.length;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${service.nom} (${days.length} ${l10n.translate('day', plural: days.length > 1 ? 'days' : null)})',
                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '${serviceCost.toStringAsFixed(2)}k DZD',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        const SizedBox(height: 10),
                                        const Divider(color: Colors.black12),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              l10n.translate('total_to_pay'),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                            Text(
                                              '${_calculateTotal().toStringAsFixed(2)}k DZD',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Color.fromARGB(255, 62, 162, 244)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l10n.translate('loyalty_points_earned', params: {'points': loyaltyPoints.toStringAsFixed(0)}),
                                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.translate('payment_info'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 10),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: l10n.translate('card_type'),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        value: cardType,
                                        items: ['Visa', 'MasterCard', 'American Express']
                                            .map((type) => DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            cardType = value;
                                          });
                                        },
                                        validator: (value) => value == null ? l10n.translate('select_card_type') : null,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: l10n.translate('card_number'),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => cardNumber = value,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return l10n.translate('enter_card_number');
                                          if (value.length != 16) return l10n.translate('card_number_length');
                                          if (!RegExp(r'^\d+$').hasMatch(value)) return l10n.translate('card_number_digits_only');
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              decoration: InputDecoration(
                                                labelText: l10n.translate('expiry_date'),
                                                border: const OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              keyboardType: TextInputType.datetime,
                                              onChanged: (value) => expiryDate = value,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) return l10n.translate('enter_expiry_date');
                                                if (!RegExp(r'^(0[1-9]|1[0-2])/[0-9]{2}$').hasMatch(value))
                                                  return l10n.translate('invalid_expiry_format');
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              decoration: InputDecoration(
                                                labelText: l10n.translate('cvv'),
                                                border: const OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) => cvv = value,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) return l10n.translate('enter_cvv');
                                                if (value.length != 3) return l10n.translate('cvv_length');
                                                if (!RegExp(r'^\d+$').hasMatch(value)) return l10n.translate('cvv_digits_only');
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _confirmPayment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.greenAccent,
                                    ),
                                    child: Text(
                                      l10n.translate('pay_and_confirm'),
                                      style: const TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      showPaymentScreen = false;
                                      cardType = null;
                                      cardNumber = null;
                                      expiryDate = null;
                                      cvv = null;
                                    }),
                                    child: Text(l10n.translate('back'), style: const TextStyle(color: Color.fromARGB(255, 44, 145, 246))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}