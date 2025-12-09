class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String myBookings = '$baseUrl/my-bookings/json/';
  static const String bookingHistory = '$baseUrl/booking-history/json/';

  // Venue endpoints
  static const String venueDashboard = '$baseUrl/api/venue/dashboard/';
  static const String venueAdd = '$baseUrl/api/venue/add/';
  static const String venueRevenue = '$baseUrl/api/venue/revenue/';
  static String venueManage(int venueId) => '$baseUrl/api/venue/$venueId/manage/';
  static String venueDelete(int venueId) => '$baseUrl/api/venue/$venueId/delete/';
}