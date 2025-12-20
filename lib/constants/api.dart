class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String myBookings = '$baseUrl/my-bookings/json/';
  static const String bookingHistory = '$baseUrl/booking-history/json/';
  static const String venues = '$baseUrl/api/venues/';

  static String bookingForm(int venueId) =>
      '$baseUrl/api/booking/$venueId/form/';
  static String createBooking(int venueId) =>
      '$baseUrl/api/booking/$venueId/create/';
  static String scheduledCoaches(int scheduleId, {int? editingBookingId}) {
    String url = '$baseUrl/api/schedule/$scheduleId/coaches/';
    if (editingBookingId != null) {
      url += '?editing_booking_id=$editingBookingId';
    }
    return url;
  }

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

  // Coach endpoints
  static const String coachSchedule = '$baseUrl/coach/schedule/';
  static const String coachScheduleDelete = '$baseUrl/coach/schedule/delete/';
  static const String sportCategories = '$baseUrl/api/sport-categories/';
  static const String locationAreas = '$baseUrl/api/location-areas/';
  static const String coachList = '$baseUrl/api/coaches/';
  static String coachDetail(int coachId) =>
      '$baseUrl/api/coach/$coachId/';
  static const String coachProfileSave = '$baseUrl/coach/profile/save/';
  static const String coachProfileJson = '$baseUrl/coach/profile/json/';
  static const String coachProfileDelete = '$baseUrl/coach/profile/delete/';
  static const String coachRevenue = '$baseUrl/api/coach/revenue/';

  // Review endpoints
  static String upsertReview(int bookingId, {required String target}) =>
      '$baseUrl/review/$bookingId/new/?target=$target';
  static String deleteReview(int reviewId) =>
      '$baseUrl/review/$reviewId/delete/';
  static String reviewsList(int bookingId) =>
      '$baseUrl/review/$bookingId/list/json/';
}
