class User {
  final int? id;  // Made nullable to handle potential null responses
  final String username;
  final String email;
  final String role;
  final String? subRole;
  final String? nom;
  final String? prenom;
  final String? photo;
  final String? codeQR;
  final String? serviceId;
  final String? phone;
  final String? address;
  final String? idNationale;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.role,
    this.subRole,
    this.nom,
    this.prenom,
    this.photo,
    this.codeQR,
    this.serviceId,
    this.phone,
    this.address,
    this.idNationale,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],  // Will be null if json['id'] is null
      username: json['username'],
      email: json['email'],
      role: json['role'],
      subRole: json['sub_role'],
      nom: json['nom'],
      prenom: json['prenom'],
      photo: json['photo'],
      codeQR: json['codeQR'],
      serviceId: json['service']?.toString(),
      phone: json['phone'],
      address: json['address'],
      idNationale: json['id_nationale'],
    );
  }
}