class Comment {
    final int id;
    final int rating;
    final String text;
    final String user;
    final int hotel;
    final DateTime createdAt;
    final DateTime updatedAt; // Added updatedAt field
    final String? adminResponse;
    final DateTime? responseAt;
    final bool isEdited;
    final DateTime? lastEditedAt;

    Comment({
        required this.id,
        required this.rating,
        required this.text,
        required this.user,
        required this.hotel,
        required this.createdAt,
        required this.updatedAt, // Added to constructor
        this.adminResponse,
        this.responseAt,
        this.isEdited = false,
        this.lastEditedAt,
    });

    factory Comment.fromJson(Map<String, dynamic> json) {
        print('Parsing comment JSON: $json'); // Debug log
        try {
            return Comment(
                id: json['id'] is String ? (int.tryParse(json['id']) ?? (throw Exception('Invalid id: ${json['id']}'))) : json['id'],
                rating: json['rating'] is String ? (int.tryParse(json['rating']) ?? (throw Exception('Invalid rating: ${json['rating']}'))) : json['rating'],
                text: json['text'] ?? (throw Exception('Missing text field')),
                user: json['user'] ?? (throw Exception('Missing user field')),
                hotel: json['hotel'] is String ? (int.tryParse(json['hotel']) ?? (throw Exception('Invalid hotel: ${json['hotel']}'))) : json['hotel'],
                createdAt: DateTime.parse(json['created_at'] ?? (throw Exception('Missing created_at field'))),
                updatedAt: DateTime.parse(json['updated_at'] ?? (throw Exception('Missing updated_at field'))), // Added parsing for updated_at
                adminResponse: json['admin_response'],
                responseAt: json['response_at'] != null ? DateTime.parse(json['response_at']) : null,
                isEdited: json['is_edited'] ?? false,
                lastEditedAt: json['last_edited_at'] != null ? DateTime.parse(json['last_edited_at']) : null,
            );
        } catch (e) {
            print('Erreur lors du parsing du commentaire : $e');
            rethrow;
        }
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'rating': rating,
            'text': text,
            'user': user,
            'hotel': hotel,
            'created_at': createdAt.toIso8601String(),
            'updated_at': updatedAt.toIso8601String(), // Added updated_at to serialization
            'admin_response': adminResponse,
            'response_at': responseAt?.toIso8601String(),
            'is_edited': isEdited,
            'last_edited_at': lastEditedAt?.toIso8601String(),
        };
    }
}