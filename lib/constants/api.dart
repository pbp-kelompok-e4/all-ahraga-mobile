class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String myBookings = '$baseUrl/my-bookings/json/';
  static const String bookingHistory = '$baseUrl/booking-history/json/';
  static const String venues = '$baseUrl/api/venues/';

  static String bookingForm(int venueId) => '$baseUrl/api/booking/$venueId/form/';
  static String createBooking(int venueId) => '$baseUrl/api/booking/$venueId/create/';
  static String scheduledCoaches(int scheduleId) => '$baseUrl/api/schedule/$scheduleId/coaches/';
}