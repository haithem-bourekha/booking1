import '../constants/api_constants.dart';

class HotelPhoto {
    final int id;
    final String imageUrl;

    HotelPhoto({
        required this.id,
        required this.imageUrl,
    });

    factory HotelPhoto.fromJson(Map<String, dynamic> json) {
        return HotelPhoto(
            id: json['id'],
            imageUrl: json['image'] != null ? '$baseUrl${json['image']}' : '',
        );
    }
}

class Hotel {
    final int id;
    final String name;
    final int stars;
    final String location;
    final String description;
    final Map<String, String> contact;
    final List<HotelPhoto> photos; // Changed to List<HotelPhoto>

    Hotel({
        required this.id,
        required this.name,
        required this.stars,
        required this.location,
        required this.description,
        required this.contact,
        required this.photos,
    });

    factory Hotel.fromJson(Map<String, dynamic> json) {
        return Hotel(
            id: json['id'],
            name: json['name'],
            stars: json['stars'],
            location: json['location'],
            description: json['description'],
            contact: Map<String, String>.from(json['contact']),
            photos: (json['photos'] as List)
                .map((p) => HotelPhoto.fromJson(p))
                .where((photo) => photo.imageUrl.isNotEmpty)
                .toList(),
        );
    }
}