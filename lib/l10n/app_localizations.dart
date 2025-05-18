import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('fr', ''), // French
    Locale('ar', ''), // Arabic
  ];

  bool get isRtl => locale.languageCode == 'ar';

  String translate(String key, {Map<String, String>? params, String? plural}) {
    final translations = _translations[locale.languageCode] ?? _translations['en']!;
    String? result;

    if (plural != null) {
      result = translations['${key}_$plural'] ?? translations[key] ?? key;
    } else {
      result = translations[key] ?? key;
    }

    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result!.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Languages
      'language_en': 'English',
      'language_fr': 'French',
      'language_ar': 'Arabic',

      // General
      'error': 'Error: {error}',
      'ok': 'OK',
      'cancel': 'Cancel',
      'select': 'Select',
      'back': 'Back',
      'update': 'Update',
      'field_required': 'This field is required',
      'not_available': 'Not available',
      'unknown': 'Unknown',
      'email': 'Email',

      // FavoriteRoomsScreen
      'favorite_rooms': 'Favorite Rooms',
      'no_favorite_rooms': 'No favorite rooms',
      'removed_from_favorites': 'Removed from favorites',
      'added_to_favorites': 'Added to favorites',

      // HotelInfoScreen
      'no_hotel_found': 'No hotel found',
      'about': 'About',
      'gallery': 'Gallery',
      'review': 'Review',
      'photos': 'Photos',
      'contact': 'Contact',
      'stars': 'Stars',
      'description': 'Description:',
      'contact_for_price': 'Contact for Price',
      'contact_now': 'Contact Now',

      // InvoiceListScreen
      'invoices': 'My Invoices',
      'no_invoices_found': 'No invoices found',

      // ProfileUpdateScreen
      'update_profile': 'Update Profile',
      'username': 'Username',
      'nom': 'Last Name',
      'prenom': 'First Name',
      'phone': 'Phone',
      'address': 'Address',
      'id_nationale': 'National ID',
      'invalid_email': 'Invalid email',
      'profile_updated_success': 'Profile updated successfully',

      // ReservationFormScreen
      'reservation_form': 'Reservation Form',
      'room': 'Room {number}',
      'price_per_night': 'Price per night: {price}k DZD',
      'price': 'Price: {price} DZD',
      'check_in': 'Check-in',
      'check_out': 'Check-out',
      'check_in_date': 'Check-in: {date}',
      'check_out_date': 'Check-out: {date}',
      'adults': 'Adults:',
      'children': 'Children:',
      'select_dates_error': 'Please select check-in and check-out dates.',
      'room_not_loaded': 'Room not loaded.',
      'room_unavailable': 'This room is not available for the selected dates.',
      'room_capacity_exceeded': 'Room capacity exceeded ({total} people for {capacity} max).',
      'alternative_rooms_available': 'Room not available. Here are other options.',
      'no_alternative_rooms': 'No other rooms available for these criteria.',
      'alternative_room_selected': 'Alternative room selected.',
      'no_reservation_period': 'No reservation period defined.',
      'select_service_days': 'Select days for {service}',
      'reservation_dates': 'Your reservation dates:',
      'price_not_available': 'Price not available',
      'alternative_rooms': 'Alternative Rooms:',
      'validate_and_select_services': 'Validate and Select Services',
      'select_services': 'Select Services:',
      'no_services_available': 'No services available at the moment.',
      'apply_service': 'Apply {service}',
      'whole_period': 'Whole period',
      'specific_days': 'Specific days',
      'day': 'day',
      'days': 'Days: {days}',

      'view_invoice_and_pay': 'View Invoice and Pay',
      'reservation_invoice': 'Reservation Invoice',
      'invoice': 'INVOICE',
      'date': 'Date',
      'reservation_details': 'Reservation Details:',
      'period': 'Period',
      'nights': 'Number of nights',
      'room_cost': 'Room cost: {cost}k DZD',
      'selected_services': 'Selected Services:',
      'total_to_pay': 'Total to Pay:',
      'payment_info': 'Payment Information',
      'card_type': 'Card Type',
      'select_card_type': 'Select a card type',
      'card_number': 'Card Number (16 digits)',
      'enter_card_number': 'Enter card number',
      'card_number_length': 'The number must be 16 digits',
      'card_number_digits_only': 'Use digits only',
      'expiry_date': 'Expiry Date (MM/YY)',
      'enter_expiry_date': 'Enter expiry date',
      'invalid_expiry_format': 'Invalid format (MM/YY)',
      'cvv': 'CVV (3 digits)',
      'enter_cvv': 'Enter CVV',
      'cvv_length': 'CVV must be 3 digits',
      'cvv_digits_only': 'Use digits only',
      'pay_and_confirm': 'Pay and Confirm',
      'fix_form_errors': 'Please correct the errors in the form.',
      'reservation_confirmed': 'Reservation confirmed successfully!',
      'error_loading_room': 'Error loading the room: {error}',
      'error_loading_services': 'Error loading services: {error}',
      'error_loading_services_invalid_data': 'Could not load services: invalid data.',

      // ReservationListScreen
      'reservations_list': 'My Reservations',
      'no_reservations_found': 'No reservations found',
      'reservation': 'Reservation',
      'from_to': 'From {from} to {to}',
      'adults_children': 'Adults: {adults}, Children: {children}',
      'status': 'Status',
      'total_price': 'Total price',
      'created_on': 'Created on',
      'cancellation_not_implemented': 'Cancellation not implemented',

      // RoomDetailScreen
      'beds': 'Beds',
      'bath': 'Bath',
      'wifi': 'WiFi',
      'breakfast': 'Breakfast',
      'book_now': 'Book Now',
    },
    'fr': {
      // Languages
      'language_en': 'Anglais',
      'language_fr': 'Français',
      'language_ar': 'Arabe',

      // General
      'error': 'Erreur : {error}',
      'ok': 'OK',
      'cancel': 'Annuler',
      'select': 'Sélectionner',
      'back': 'Retour',
      'update': 'Mettre à jour',
      'field_required': 'Champ requis',
      'not_available': 'Non disponible',
      'unknown': 'Inconnu',
      'email': 'Email',

      // FavoriteRoomsScreen
      'favorite_rooms': 'Chambres Favorites',
      'no_favorite_rooms': 'Aucune chambre favorite',
      'removed_from_favorites': 'Retiré des favoris',
      'added_to_favorites': 'Ajouté aux favoris',

      // HotelInfoScreen
      'no_hotel_found': 'Aucun hôtel trouvé',
      'about': 'À propos',
      'gallery': 'Galerie',
      'review': 'Avis',
      'photos': 'Photos',
      'contact': 'Contact',
      'stars': 'Étoiles',
      'description': 'Description :',
      'contact_for_price': 'Contacter pour le prix',
      'contact_now': 'Contacter maintenant',

      // InvoiceListScreen
      'invoices': 'Mes Factures',
      'no_invoices_found': 'Aucune facture trouvée',

      // ProfileUpdateScreen
      'update_profile': 'Mettre à jour le profil',
      'username': 'Nom d\'utilisateur',
      'nom': 'Nom',
      'prenom': 'Prénom',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'id_nationale': 'ID Nationale',
      'invalid_email': 'Email invalide',
      'profile_updated_success': 'Profil mis à jour avec succès',

      // ReservationFormScreen
      'reservation_form': 'Formulaire de Réservation',
      'room': 'Chambre {number}',
      'price_per_night': 'Prix par nuit : {price}k DZD',
      'price': 'Prix : {price} DZD',
      'check_in': 'Check-in',
      'check_out': 'Check-out',
      'check_in_date': 'Check-in : {date}',
      'check_out_date': 'Check-out : {date}',
      'adults': 'Adultes :',
      'children': 'Enfants :',
      'select_dates_error': 'Veuillez sélectionner les dates de check-in et check-out.',
      'room_not_loaded': 'Chambre non chargée.',
      'room_unavailable': 'Cette chambre n\'est pas disponible pour les dates sélectionnées.',
      'room_capacity_exceeded': 'La capacité de cette chambre est dépassée ({total} personnes pour {capacity} max).',
      'alternative_rooms_available': 'Chambre non disponible. Voici d\'autres options.',
      'no_alternative_rooms': 'Aucune autre chambre disponible pour ces critères.',
      'alternative_room_selected': 'Chambre alternative sélectionnée.',
      'no_reservation_period': 'Aucune période de réservation définie.',
      'select_service_days': 'Choisir les jours pour {service}',
      'reservation_dates': 'Dates de votre réservation :',
      'price_not_available': 'Prix non disponible',
      'alternative_rooms': 'Chambres Alternatives :',
      'validate_and_select_services': 'Valider et Choisir Services',
      'select_services': 'Choisir des Services :',
      'no_services_available': 'Aucun service disponible pour le moment.',
      'apply_service': 'Appliquer {service}',
      'whole_period': 'Toute la période',
      'specific_days': 'Jours spécifiques',
      'day': 'jour',
      'days': 'Jours : {days}',

      'view_invoice_and_pay': 'Voir la Facture et Payer',
      'reservation_invoice': 'Facture de Réservation',
      'invoice': 'FACTURE',
      'date': 'Date',
      'reservation_details': 'Détails de la Réservation :',
      'period': 'Période',
      'nights': 'Nombre de nuits',
      'room_cost': 'Coût de la chambre : {cost}k DZD',
      'selected_services': 'Services Sélectionnés :',
      'total_to_pay': 'Total à Payer :',
      'payment_info': 'Informations de Paiement',
      'card_type': 'Type de Carte',
      'select_card_type': 'Choisissez un type de carte',
      'card_number': 'Numéro de Carte (16 chiffres)',
      'enter_card_number': 'Entrez le numéro de carte',
      'card_number_length': 'Le numéro doit contenir 16 chiffres',
      'card_number_digits_only': 'Utilisez uniquement des chiffres',
      'expiry_date': 'Date d\'Expiration (MM/AA)',
      'enter_expiry_date': 'Entrez la date d\'expiration',
      'invalid_expiry_format': 'Format invalide (MM/AA)',
      'cvv': 'CVV (3 chiffres)',
      'enter_cvv': 'Entrez le CVV',
      'cvv_length': 'Le CVV doit contenir 3 chiffres',
      'cvv_digits_only': 'Utilisez uniquement des chiffres',
      'pay_and_confirm': 'Payer et Confirmer',
      'fix_form_errors': 'Veuillez corriger les erreurs dans le formulaire.',
      'reservation_confirmed': 'Réservation confirmée avec succès !',
      'error_loading_room': 'Erreur lors du chargement de la chambre : {error}',
      'error_loading_services': 'Erreur lors du chargement des services : {error}',
      'error_loading_services_invalid_data': 'Les services n\'ont pas pu être chargés : données invalides.',

      // ReservationListScreen
      'reservations_list': 'Mes Réservations',
      'no_reservations_found': 'Aucune réservation trouvée',
      'reservation': 'Réservation',
      'from_to': 'Du {from} au {to}',
      'adults_children': 'Adultes : {adults}, Enfants : {children}',
      'status': 'Statut',
      'total_price': 'Prix total',
      'created_on': 'Créée le',
      'cancellation_not_implemented': 'Annulation non implémentée',

      // RoomDetailScreen
      'beds': 'Lits',
      'bath': 'Bain',
      'wifi': 'WiFi',
      'breakfast': 'Petit-déjeuner',
      'book_now': 'Réserver maintenant',
    },
    'ar': {
      // Languages
      'language_en': 'الإنجليزية',
      'language_fr': 'الفرنسية',
      'language_ar': 'العربية',

      // General
      'error': 'خطأ: {error}',
      'ok': 'موافق',
      'cancel': 'إلغاء',
      'select': 'اختر',
      'back': 'رجوع',
      'update': 'تحديث',
      'field_required': 'هذا الحقل مطلوب',
      'not_available': 'غير متوفر',
      'unknown': 'غير معروف',
      'email': 'بريد إلكتروني',

      // FavoriteRoomsScreen
      'favorite_rooms': 'الغرف المفضلة',
      'no_favorite_rooms': 'لا توجد غرف مفضلة',
      'removed_from_favorites': 'تمت الإزالة من المفضلة',
      'added_to_favorites': 'تمت الإضافة إلى المفضلة',

      // HotelInfoScreen
      'no_hotel_found': 'لم يتم العثور على فندق',
      'about': 'حول',
      'gallery': 'معرض الصور',
      'review': 'مراجعة',
      'photos': 'صور',
      'contact': 'اتصال',
      'stars': 'نجوم',
      'description': 'الوصف:',
      'contact_for_price': 'اتصل لمعرفة السعر',
      'contact_now': 'اتصل الآن',

      // InvoiceListScreen
      'invoices': 'فواتيري',
      'no_invoices_found': 'لم يتم العثور على فواتير',

      // ProfileUpdateScreen
      'update_profile': 'تحديث الملف الشخصي',
      'username': 'اسم المستخدم',
      'nom': 'اللقب',
      'prenom': 'الاسم الأول',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'id_nationale': 'الهوية الوطنية',
      'invalid_email': 'بريد إلكتروني غير صالح',
      'profile_updated_success': 'تم تحديث الملف الشخصي بنجاح',

      // ReservationFormScreen
      'reservation_form': 'نموذج الحجز',
      'room': 'غرفة {number}',
      'price_per_night': 'السعر لليلة: {price} ألف دينار جزائري',
      'price': 'السعر: {price} دينار جزائري',
      'check_in': 'تسجيل الوصول',
      'check_out': 'تسجيل المغادرة',
      'check_in_date': 'تسجيل الوصول: {date}',
      'check_out_date': 'تسجيل المغادرة: {date}',
      'adults': 'البالغون:',
      'children': 'الأطفال:',
      'select_dates_error': 'يرجى تحديد تواريخ تسجيل الوصول والمغادرة.',
      'room_not_loaded': 'لم يتم تحميل الغرفة.',
      'room_unavailable': 'هذه الغرفة غير متوفرة للتواريخ المحددة.',
      'room_capacity_exceeded': 'تجاوزت سعة الغرفة ({total} أشخاص لـ {capacity} كحد أقصى).',
      'alternative_rooms_available': 'الغرفة غير متوفرة. إليك خيارات أخرى.',
      'no_alternative_rooms': 'لا توجد غرف أخرى متوفرة لهذه المعايير.',
      'alternative_room_selected': 'تم اختيار غرفة بديلة.',
      'no_reservation_period': 'لم يتم تحديد فترة الحجز.',
      'select_service_days': 'اختر الأيام لـ {service}',
      'reservation_dates': 'تواريخ الحجز الخاصة بك:',
      'price_not_available': 'السعر غير متوفر',
      'alternative_rooms': 'غرف بديلة:',
      'validate_and_select_services': 'تحقق واختر الخدمات',
      'select_services': 'اختر الخدمات:',
      'no_services_available': 'لا توجد خدمات متاحة حاليًا.',
      'apply_service': 'تطبيق {service}',
      'whole_period': 'الفترة الكاملة',
      'specific_days': 'أيام محددة',
      'day': 'يوم',
      'days': 'أيام: {days}',

      'view_invoice_and_pay': 'عرض الفاتورة والدفع',
      'reservation_invoice': 'فاتورة الحجز',
      'invoice': 'فاتورة',
      'date': 'التاريخ',
      'reservation_details': 'تفاصيل الحجز:',
      'period': 'الفترة',
      'nights': 'عدد الليالي',
      'room_cost': 'تكلفة الغرفة: {cost} ألف دينار جزائري',
      'selected_services': 'الخدمات المختارة:',
      'total_to_pay': 'المجموع للدفع:',
      'payment_info': 'معلومات الدفع',
      'card_type': 'نوع البطاقة',
      'select_card_type': 'اختر نوع البطاقة',
      'card_number': 'رقم البطاقة (16 رقمًا)',
      'enter_card_number': 'أدخل رقم البطاقة',
      'card_number_length': 'يجب أن يحتوي الرقم على 16 رقمًا',
      'card_number_digits_only': 'استخدم الأرقام فقط',
      'expiry_date': 'تاريخ الانتهاء (MM/YY)',
      'enter_expiry_date': 'أدخل تاريخ الانتهاء',
      'invalid_expiry_format': 'صيغة غير صالحة (MM/YY)',
      'cvv': 'CVV (3 أرقام)',
      'enter_cvv': 'أدخل CVV',
      'cvv_length': 'يجب أن يحتوي CVV على 3 أرقام',
      'cvv_digits_only': 'استخدم الأرقام فقط',
      'pay_and_confirm': 'ادفع وتأكيد',
      'fix_form_errors': 'يرجى تصحيح الأخطاء في النموذج.',
      'reservation_confirmed': 'تم تأكيد الحجز بنجاح!',
      'error_loading_room': 'خطأ أثناء تحميل الغرفة: {error}',
      'error_loading_services': 'خطأ أثناء تحميل الخدمات: {error}',
      'error_loading_services_invalid_data': 'تعذر تحميل الخدمات: بيانات غير صالحة.',

      // ReservationListScreen
      'reservations_list': 'حجوزاتي',
      'no_reservations_found': 'لم يتم العثور على حجوزات',
      'reservation': 'حجز',
      'from_to': 'من {from} إلى {to}',
      'adults_children': 'البالغون: {adults}، الأطفال: {children}',
      'status': 'الحالة',
      'total_price': 'السعر الإجمالي',
      'created_on': 'تم الإنشاء في',
      'cancellation_not_implemented': 'الإلغاء غير مطبق',

      // RoomDetailScreen
      'beds': 'أسرّة',
      'bath': 'حمام',
      'wifi': 'واي فاي',
      'breakfast': 'إفطار',
      'book_now': 'احجز الآن',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}