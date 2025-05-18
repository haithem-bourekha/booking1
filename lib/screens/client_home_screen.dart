import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Ajout pour formater la date
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/profile_update_screen.dart';
import '../screens/hotel_info_screen.dart';
import '../screens/room_list_screen.dart';
import '../screens/reservation_form_screen.dart';
import '../screens/favorite_rooms_screen.dart';
import '../screens/reservation_list_screen.dart';
import '../screens/room_detail_screen.dart';
import '../screens/invoice_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/task_management_screen.dart';
import '../models/room.dart';
import '../models/hotel.dart';
import '../models/task.dart';
import '../services/room_service.dart';
import '../services/hotel_service.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';
import '../widgets/room_card.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final RoomService roomService = RoomService(ApiService());
  final HotelService hotelService = HotelService(ApiService());
  final TaskService taskService = TaskService(ApiService());
  List<Room> allRooms = [];
  List<Room> filteredRooms = [];
  List<Task> allTasks = [];
  List<Task> todayTasks = [];
  bool isLoading = true;
  bool isTasksLoading = true;
  String? errorMessage;
  String? hotelName;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
    fetchHotelInfo();
    fetchRooms();
    fetchTasks();
    _searchController.addListener(_filterRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHotelInfo() async {
    try {
      final hotels = await hotelService.getHotels();
      if (hotels.isNotEmpty) {
        setState(() {
          hotelName = hotels[0].name;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = AppLocalizations.of(context).translate('error', params: {'error': e.toString()});
      });
    }
  }

  Future<void> fetchRooms() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final rooms = await roomService.getRooms();
      setState(() {
        allRooms = rooms;
        filteredRooms = rooms;
        isLoading = false;
      });
      print('Chambres chargées: ${allRooms.length}');
    } catch (e) {
      setState(() {
        errorMessage = AppLocalizations.of(context).translate('error', params: {'error': e.toString()});
        isLoading = false;
      });
    }
  }

  Future<void> fetchTasks() async {
    setState(() {
      isTasksLoading = true;
    });
    try {
      final tasks = await taskService.getTasks();
      final user = ref.read(authProvider);
      if (user == null) {
        setState(() {
          allTasks = [];
          todayTasks = [];
          isTasksLoading = false;
          errorMessage = AppLocalizations.of(context).translate('not_logged_in');
        });
        return;
      }
      allTasks = tasks.where((task) => task.clientId == user.id).toList();
      final today = DateTime.now();
      todayTasks = allTasks.where((task) {
        final taskDate = task.dateService.toLocal(); // Plus besoin de DateTime.parse()
        return taskDate.year == today.year &&
               taskDate.month == today.month &&
               taskDate.day == today.day;
      }).toList();
      setState(() {
        isTasksLoading = false;
      });
      print('Tâches chargées: ${allTasks.length}, Tâches du jour: ${todayTasks.length}');
    } catch (e) {
      setState(() {
        errorMessage = AppLocalizations.of(context).translate('error', params: {'error': e.toString()});
        isTasksLoading = false;
      });
    }
  }

  void _filterRooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredRooms = allRooms;
      } else {
        filteredRooms = allRooms
            .where((room) => room.type.nom.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomListScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteRoomsScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileUpdateScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelInfoScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hotelName ?? l10n.translate('loading_hotel_name')),
        backgroundColor: const Color.fromARGB(255, 100, 189, 249),
        foregroundColor: const Color.fromARGB(255, 235, 244, 251),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color.fromARGB(255, 91, 148, 240)),
              child: Column(
                crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('menu'),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('user'),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              title: DropdownButton<Locale>(
                value: language.locale,
                isExpanded: true,
                items: AppLocalizations.supportedLocales.map((locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(l10n.translate('language_${locale.languageCode}')),
                  );
                }).toList(),
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    ref.read(languageProvider.notifier).setLocale(newLocale);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              title: Text(theme.isDarkMode ? l10n.translate('light_mode') : l10n.translate('dark_mode')),
              onTap: () {
                theme.toggleTheme();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: Text(l10n.translate('reservations_list')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReservationListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(l10n.translate('favorite_rooms')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoriteRoomsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: Text(l10n.translate('invoices')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoiceListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.translate('services_today')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodayTasksScreen(tasks: todayTasks, isLoading: isTasksLoading),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.translate('logout')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.translate('search'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            // Section "Recommended Hotel" avec Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('recommended_room'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.translate('see_all'),
                    style: const TextStyle(color: Color.fromARGB(255, 77, 161, 240)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filteredRooms.length > 5
                      ? filteredRooms.sublist(0, 5).map((room) {
                          return _buildRoomCard(room);
                        }).toList()
                      : filteredRooms.map((room) {
                          return _buildRoomCard(room);
                        }).toList(),
                ),
              ),
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(child: Text(errorMessage!))
            else
              Column(
                children: [
                  // Section "Nearby Hotel" avec Column (unchanged)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('nearby_hotel'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.translate('see_all'),
                          style: const TextStyle(color: Color.fromARGB(255, 79, 143, 240)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: filteredRooms.length > 5
                        ? filteredRooms.sublist(5).map((room) {
                            return FutureBuilder<bool>(
                              future: roomService.isFavorite(room.id),
                              builder: (context, favoriteSnapshot) {
                                bool isFavorite = favoriteSnapshot.data ?? false;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RoomDetailScreen(room: room),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                          child: room.photo != null
                                              ? Image.network(
                                                  room.photo!,
                                                  height: 100,
                                                  width: 100,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(Icons.hotel, size: 100),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.translate('room', params: {'number': room.number.toString()}),
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, size: 16, color: Color.fromARGB(255, 64, 182, 241)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.translate('price', params: {
                                                        'price': (room.type.prixNuit ~/ 1000).toString(),
                                                      }),
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                                Text('${room.type.nom}', style: const TextStyle(fontSize: 14)),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => ReservationFormScreen(roomId: room.id),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color.fromARGB(255, 93, 167, 251),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      ),
                                                      child: Text(
                                                        l10n.translate('booking'),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                                        color: isFavorite ? Colors.red : Colors.grey,
                                                      ),
                                                      onPressed: () async {
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
                                                          setState(() {});
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                l10n.translate('error', params: {'error': e.toString()}),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList()
                        : [],
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.translate('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.room), label: l10n.translate('room_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.translate('favorite_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.translate('update_profile_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.hotel), label: l10n.translate('hotel_tab')),
        ],
        selectedItemColor: const Color.fromARGB(255, 82, 160, 239),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<bool>(
      future: roomService.isFavorite(room.id),
      builder: (context, favoriteSnapshot) {
        bool isFavorite = favoriteSnapshot.data ?? false;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomDetailScreen(room: room),
                ),
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Container(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: room.photo != null
                              ? Image.network(
                                  room.photo!,
                                  height: 100,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 100),
                                )
                              : const Icon(Icons.hotel, size: 100),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.translate('room', params: {'number': room.number.toString()}),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Color.fromARGB(255, 77, 140, 241)),
                                  Text(
                                    '4.8', // Placeholder rating, adjust as needed
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            'New York, USA', // Placeholder location, adjust as needed
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            l10n.translate('price', params: {
                              'price': (room.type.prixNuit ~/ 1000).toString(),
                            }) + '/Day',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Écran pour afficher les tâches du jour
class TodayTasksScreen extends ConsumerWidget {
  final List<Task> tasks;
  final bool isLoading;

  const TodayTasksScreen({required this.tasks, required this.isLoading, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('services_today')),
        backgroundColor: const Color.fromARGB(255, 84, 150, 249),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('no_tasks_today'),
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.translate('no_tasks_today_subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4,
                      color: theme.isDarkMode ? Colors.grey[800] : Colors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.room_service,
                          color: Colors.blue,
                        ),
                        title: Text(
                          '${task.serviceName} - ${DateFormat('dd/MM/yyyy').format(task.dateService)} ${task.heureService ?? ''}',
                          style: TextStyle(
                            color: theme.isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${l10n.translate('status')}: ${task.etat}',
                          style: TextStyle(
                            color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskManagementScreen(reservationId: task.reservationId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// Écran pour afficher toutes les tâches (conservé mais non utilisé dans le drawer)
class AllTasksScreen extends ConsumerWidget {
  final List<Task> tasks;
  final bool isLoading;

  const AllTasksScreen({required this.tasks, required this.isLoading, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('all_services')),
        backgroundColor: const Color.fromARGB(255, 89, 149, 240),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('no_tasks'),
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.translate('no_tasks_subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4,
                      color: theme.isDarkMode ? Colors.grey[800] : Colors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.room_service,
                          color: Colors.blue,
                        ),
                        title: Text(
                          '${task.serviceName} - ${DateFormat('dd/MM/yyyy').format(task.dateService)} ${task.heureService ?? ''}',
                          style: TextStyle(
                            color: theme.isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${l10n.translate('status')}: ${task.etat}',
                          style: TextStyle(
                            color: theme.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskManagementScreen(reservationId: task.reservationId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}