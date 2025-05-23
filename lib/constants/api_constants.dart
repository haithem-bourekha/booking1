const String baseUrl = 'http://localhost:8000/api';
const String loginEndpoint = '/auth/login/';
const String signupEndpoint = '/auth/signup/';
const String profileEndpoint = '/auth/profile/';
const String hotelsEndpoint = '/hotels/';
const String commentsEndpoint = '/hotels/%s/comments/';
const String roomsEndpoint = '/rooms/rooms/';
const String availableRoomsEndpoint = '/rooms/rooms/search/';
const String favoritesEndpoint = '/rooms/favorites/';
const String tasksEndpoint = '/services/tasks/';
const String reservationsEndpoint = '/reservations/reservations/';
const String clientReservationsEndpoint = '/reservations/client-reservations/';
const String invoicesEndpoint = '/invoices/client-invoices/';
const String servicesEndpoint = '/services/services/';
const String cancelReservationEndpoint = '/reservations/reservations/<id>/cancel/';
const String cancelTaskEndpoint = '/services/tasks/<id>/cancel/';
const String forgotPasswordStep1Endpoint = '/auth/forgot-password-step1/';
const String forgotPasswordStep2Endpoint = '/auth/forgot-password-step2/';
const String verifyResetCodeEndpoint = '/auth/verify-reset-code/';
const String resetPasswordEndpoint = '/auth/reset-password/';
const String payEndpoint = '/invoices/pay/'; // Nouvelle constante