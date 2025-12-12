class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String myBookings = '$baseUrl/my-bookings/json/';
  static const String bookingHistory = '$baseUrl/booking-history/json/';
  static const String venues = '$baseUrl/api/venues/';

  static String bookingForm(int venueId) =>
      '$baseUrl/api/booking/$venueId/form/';
  static String createBooking(int venueId) =>
      '$baseUrl/api/booking/$venueId/create/';
  static String scheduledCoaches(int scheduleId) =>
      '$baseUrl/api/schedule/$scheduleId/coaches/';
  static String cancelBooking(int bookingId) =>
      '$baseUrl/api/booking/$bookingId/cancel/';
  static String updateBooking(int bookingId) =>
      '$baseUrl/api/booking/$bookingId/update/';
  static String bookingDetail(int bookingId) =>
      '$baseUrl/api/booking/$bookingId/detail/';
  static String confirmPayment(int bookingId) =>
      '$baseUrl/customer/payment/$bookingId/';

  // Venue endpoints
  static const String venueDashboard = '$baseUrl/api/venue/dashboard/';
  static const String venueAdd = '$baseUrl/api/venue/add/';
  static const String venueRevenue = '$baseUrl/api/venue/revenue/';
  static String venueManage(int venueId) =>
      '$baseUrl/api/venue/$venueId/manage/';
  static String venueDelete(int venueId) =>
      '$baseUrl/api/venue/$venueId/delete/';
  static String venueManageSchedule(int venueId) =>
      '$baseUrl/dashboard/venue/$venueId/schedules/manage/';
  static String venueDeleteSchedule(int venueId) =>
      '$baseUrl/venue/$venueId/schedules/delete/';
}
