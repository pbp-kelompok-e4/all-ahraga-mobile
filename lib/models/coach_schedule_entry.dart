import 'dart:convert';

List<CoachSchedule> coachScheduleFromJson(String str) =>
    List<CoachSchedule>.from(json.decode(str).map((x) => CoachSchedule.fromJson(x)));

String coachScheduleToJson(List<CoachSchedule> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CoachSchedule {
  int id;
  String date; // YYYY-MM-DD
  String startTime; // HH:MM
  String endTime; // HH:MM
  bool isBooked;
  bool isAvailable;
  
  // Helper UI Flutter
  bool isSelected;

  CoachSchedule({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    required this.isAvailable,
    this.isSelected = false,
  });

  factory CoachSchedule.fromJson(Map<String, dynamic> json) => CoachSchedule(
        id: json["id"],
        date: json["date"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        isBooked: json["is_booked"],
        isAvailable: json["is_available"],
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