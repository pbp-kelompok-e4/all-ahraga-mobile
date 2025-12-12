import 'dart:convert';

List<VenueSchedule> venueScheduleFromJson(String str) =>
    List<VenueSchedule>.from(json.decode(str).map((x) => VenueSchedule.fromJson(x)));

String venueScheduleToJson(List<VenueSchedule> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VenueSchedule {
  int id;
  String date;        // Format YYYY-MM-DD
  String startTime;   // Format HH:MM
  String endTime;     // Format HH:MM
  bool isBooked;
  bool isAvailable;
  
  // Helper untuk checkbox di Flutter (tidak ada di database Django, cuma state lokal UI)
  bool isSelected; 

  VenueSchedule({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    required this.isAvailable,
    this.isSelected = false,
  });

  factory VenueSchedule.fromJson(Map<String, dynamic> json) => VenueSchedule(
        id: json["id"],
        date: json["date"],
        startTime: json["start_time"], // Sesuai key di views.py
        endTime: json["end_time"],     // Sesuai key di views.py
        isBooked: json["is_booked"],
        isAvailable: json["is_available"],
        isSelected: false, // Default false saat baru load
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date,
        "start_time": startTime,
        "end_time": endTime,
        "is_booked": isBooked,
        "is_available": isAvailable,
      };
}