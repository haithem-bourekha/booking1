import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import '../models/hotel.dart';
import '../models/comment.dart';
import '../services/hotel_service.dart';
import '../services/api_service.dart';

class HotelInfoScreen extends StatefulWidget {
  const HotelInfoScreen({super.key});

  @override
  _HotelInfoScreenState createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HotelService _hotelService = HotelService(ApiService());
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _adminResponseController = TextEditingController();
  final TextEditingController _deleteReasonController = TextEditingController();
  int _rating = 1;
  String? _userRole;
  String? _username;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Comment> _comments = [];
  List<Hotel> _hotels = [];
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserInfo();
    _loadHotels();
  }

  Future<void> _loadUserInfo() async {
    final role = await _storage.read(key: 'user_role');
    final username = await _storage.read(key: 'username');
    print('User Role: $role, Username: $username');
    setState(() {
      _userRole = role;
      _username = username;
    });
  }

  Future<void> _loadHotels() async {
    try {
      final hotels = await _hotelService.getHotels();
      setState(() {
        _hotels = hotels;
      });
    } catch (e) {
      print('Erreur lors du chargement des hôtels : $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _adminResponseController.dispose();
    _deleteReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _hotels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  for (final hotel in _hotels)
                    _buildHotelSection(hotel),
                ],
              ),
            ),
    );
  }

  Widget _buildHotelSection(Hotel hotel) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: hotel.photos.isNotEmpty
                  ? Image.network(
                      hotel.photos[0].imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Erreur de chargement de l\'image principale : $error, URL : ${hotel.photos[0].imageUrl}');
                        return const Icon(Icons.error, size: 300);
                      },
                    )
                  : const Icon(Icons.hotel, size: 300),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: hotel.photos.length,
                  itemBuilder: (context, index) {
                    final photo = hotel.photos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photo.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Erreur de chargement de l\'image galerie : $error, URL : ${photo.imageUrl}');
                                return const Icon(Icons.error, size: 80);
                              },
                            ),
                          ),
                          if (_userRole == 'admin')
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePhoto(context, hotel.id, photo.id, index),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        hotel.stars.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future: _hotelService.getReviewCount(hotel.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '(${snapshot.data} ${l10n.translate('reviews')})',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hotel.location,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.orange,
                tabs: [
                  Tab(text: l10n.translate('about')),
                  Tab(text: l10n.translate('gallery')),
                  Tab(text: l10n.translate('review')),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('description'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hotel.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.translate('details'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.location_on, l10n.translate('location'), hotel.location),
                              _buildDetailRow(Icons.star, l10n.translate('stars'), hotel.stars.toString()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    hotel.photos.isEmpty
                        ? Center(child: Text(l10n.translate('no_photos')))
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: hotel.photos.length,
                            itemBuilder: (context, index) {
                              final photo = hotel.photos[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      photo.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Erreur de chargement de l\'image grille : $error, URL : ${photo.imageUrl}');
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ),
                                  if (_userRole == 'admin')
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deletePhoto(context, hotel.id, photo.id, index),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                    FutureBuilder<List<Comment>>(
                      future: _hotelService.getComments(hotel.id),
                      builder: (context, commentSnapshot) {
                        if (commentSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (commentSnapshot.hasError) {
                          print('Erreur lors de la récupération des commentaires : ${commentSnapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l10n.translate('error', params: {'error': commentSnapshot.error.toString()})),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: Text(l10n.translate('retry')),
                                ),
                              ],
                            ),
                          );
                        }
                        _comments = commentSnapshot.data ?? [];
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (_userRole == 'client')
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.translate('add_comment'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButton<int>(
                                            value: _rating,
                                            items: List.generate(5, (index) => index + 1)
                                                .map((value) => DropdownMenuItem(
                                                      value: value,
                                                      child: Text('$value ${l10n.translate('stars')}'),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _rating = value!;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _commentController,
                                            decoration: InputDecoration(
                                              labelText: l10n.translate('comment'),
                                              border: const OutlineInputBorder(),
                                              hintText: l10n.translate('write_your_comment'),
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                            ),
                                            maxLines: 3,
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: l10n.isRtl ? Alignment.centerRight : Alignment.centerLeft,
                                            child: ElevatedButton(
                                              onPressed: _isAddingComment
                                                  ? null
                                                  : () => _addComment(context, hotel.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              ),
                                              child: _isAddingComment
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Text(
                                                      l10n.translate('submit'),
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (_comments.isEmpty && _userRole != 'client')
                                Center(child: Text(l10n.translate('no_comments'))),
                              AnimatedList(
                                key: _listKey,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                initialItemCount: _comments.length,
                                itemBuilder: (context, index, animation) {
                                  final comment = _comments[index];
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    child: _buildCommentTile(context, comment, hotel.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAmenity(Icons.photo, '${hotel.photos.length} ${l10n.translate('photos')}'),
                  _buildAmenity(Icons.directions_walk, '0.5km'),
                  _buildAmenity(Icons.phone, l10n.translate('contact')),
                  _buildAmenity(Icons.star, '${hotel.stars} ${l10n.translate('stars')}'),
                  _buildAmenity(Icons.email, l10n.translate('email')),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('contact'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Téléphone: ${hotel.contact['phone'] ?? l10n.translate('not_available')}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Email: ${hotel.contact['email'] ?? l10n.translate('not_available')}',
                style: const TextStyle(fontSize: 16),
              ),
              if (hotel.contact.containsKey('facebook') && hotel.contact['facebook']!.isNotEmpty)
                Text(
                  'Facebook: ${hotel.contact['facebook']}',
                  style: const TextStyle(fontSize: 16),
                ),
              if (hotel.contact.containsKey('instagram') && hotel.contact['instagram']!.isNotEmpty)
                Text(
                  'Instagram: ${hotel.contact['instagram']}',
                  style: const TextStyle(fontSize: 16),
                ),
              if (hotel.contact.containsKey('website') && hotel.contact['website']!.isNotEmpty)
                Text(
                  'Site Web: ${hotel.contact['website']}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.translate('contact_for_price'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Implémenter l'action de contact
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(l10n.translate('contact_now'), style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _deletePhoto(BuildContext context, int hotelId, int photoId, int index) async {
    final l10n = AppLocalizations.of(context);

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_photo')),
        content: Text(l10n.translate('confirm_delete_photo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _hotelService.deletePhoto(hotelId, photoId);
      setState(() {
        _hotels = _hotels.map((hotel) {
          if (hotel.id == hotelId) {
            final updatedPhotos = List<HotelPhoto>.from(hotel.photos)..removeAt(index);
            return Hotel(
              id: hotel.id,
              name: hotel.name,
              stars: hotel.stars,
              location: hotel.location,
              description: hotel.description,
              contact: hotel.contact,
              photos: updatedPhotos,
            );
          }
          return hotel;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('photo_deleted'))),
      );
    } catch (e) {
      print('Erreur lors de la suppression de la photo : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(BuildContext context, Comment comment, int hotelId) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.user,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(comment.rating.toString()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('posted_on', params: {
                    'date': comment.createdAt.toLocal().toString()
                  }),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (comment.isEdited && comment.lastEditedAt != null)
                  Text(
                    l10n.translate('edited_on', params: {
                      'date': comment.lastEditedAt!.toLocal().toString()
                    }),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            if (comment.adminResponse != null)
              Column(
                crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    l10n.translate('admin_response'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(comment.adminResponse!),
                  Text(
                    l10n.translate('responded_on', params: {
                      'date': comment.responseAt!.toLocal().toString()
                    }),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            if (_userRole == 'client' && comment.user == _username)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _confirmEditComment(context, hotelId, comment),
                    child: Text(l10n.translate('edit')),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  TextButton(
                    onPressed: () => _deleteComment(context, hotelId, comment.id, _comments.indexOf(comment)),
                    child: Text(l10n.translate('delete')),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            if (_userRole == 'admin')
              Column(
                crossAxisAlignment: l10n.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _adminResponseController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('admin_response'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _addAdminResponse(context, hotelId, comment.id),
                        child: Text(l10n.translate('submit_response')),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _deleteComment(context, hotelId, comment.id, _comments.indexOf(comment)),
                        child: Text(l10n.translate('delete')),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment(BuildContext context, int hotelId) async {
    final l10n = AppLocalizations.of(context);

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('comment_empty'))),
      );
      return;
    }

    setState(() {
      _isAddingComment = true;
    });

    try {
      final newComment = Comment(
        id: 0,
        rating: _rating,
        text: _commentController.text.trim(),
        user: _username ?? 'Unknown',
        hotel: hotelId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _hotelService.addComment(hotelId, newComment);

      _comments.insert(0, newComment);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));

      _commentController.clear();
      setState(() {
        _rating = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('comment_added'))),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  Future<void> _confirmEditComment(BuildContext context, int hotelId, Comment comment) async {
    final l10n = AppLocalizations.of(context);

    bool? confirmEdit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_edit')),
        content: Text(l10n.translate('confirm_edit_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmEdit == true) {
      _editComment(context, hotelId, comment);
    }
  }

  Future<void> _editComment(BuildContext context, int hotelId, Comment comment) async {
    final l10n = AppLocalizations.of(context);

    final editController = TextEditingController(text: comment.text);
    int editRating = comment.rating;
    bool showPreview = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.translate('edit_comment')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    value: editRating,
                    items: List.generate(5, (index) => index + 1)
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value ${l10n.translate('stars')}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        editRating = value!;
                      });
                    },
                  ),
                  TextField(
                    controller: editController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('comment'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        showPreview = !showPreview;
                      });
                    },
                    child: Text(showPreview ? l10n.translate('hide_preview') : l10n.translate('show_preview')),
                  ),
                  if (showPreview)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('preview'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rating: $editRating ${l10n.translate('stars')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            editController.text,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (editController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('comment_empty'))),
                      );
                      return;
                    }
                    try {
                      final updatedComment = Comment(
                        id: comment.id,
                        rating: editRating,
                        text: editController.text.trim(),
                        user: comment.user,
                        hotel: hotelId,
                        createdAt: comment.createdAt,
                        updatedAt: DateTime.now(),
                        isEdited: true,
                        lastEditedAt: DateTime.now(),
                        adminResponse: comment.adminResponse,
                        responseAt: comment.responseAt,
                      );

                      await _hotelService.editComment(hotelId, comment.id, updatedComment);

                      final index = _comments.indexOf(comment);
                      _comments[index] = updatedComment;

                      Navigator.pop(context);
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('comment_updated'))),
                      );
                    } catch (e) {
                      print('Erreur lors de la modification du commentaire : $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
                      );
                    }
                  },
                  child: Text(l10n.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteComment(BuildContext context, int hotelId, int commentId, int index) async {
    final l10n = AppLocalizations.of(context);

    bool requireReason = _userRole == 'admin';
    String? deleteReason;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_comment')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.translate('confirm_delete')),
            if (requireReason) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _deleteReasonController,
                decoration: InputDecoration(
                  labelText: l10n.translate('reason_for_deletion'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (requireReason && _deleteReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('reason_empty'))),
                );
                return;
              }
              if (requireReason) {
                deleteReason = _deleteReasonController.text.trim();
              }
              Navigator.pop(context, true);
            },
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _hotelService.deleteComment(hotelId, commentId);
      final removedComment = _comments.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _buildCommentTile(context, removedComment, hotelId),
        ),
        duration: const Duration(milliseconds: 300),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('comment_deleted'))),
      );
      if (deleteReason != null) {
        print('Raison de la suppression : $deleteReason');
      }
    } catch (e) {
      print('Erreur lors de la suppression du commentaire : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _addAdminResponse(BuildContext context, int hotelId, int commentId) async {
    final l10n = AppLocalizations.of(context);

    if (_adminResponseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('response_empty'))),
      );
      return;
    }
    try {
      await _hotelService.addAdminResponse(hotelId, commentId, _adminResponseController.text.trim());
      _adminResponseController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('response_added'))),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout de la réponse admin : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error', params: {'error': e.toString()}))),
      );
    }
  }

  Widget _buildAmenity(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}