import 'dart:convert';

List<BookingListEntry> bookingListEntryFromJson(String str) =>
    List<BookingListEntry>.from(
        json.decode(str).map((x) => BookingListEntry.fromJson(x)));

String bookingListEntryToJson(List<BookingListEntry> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BookingListEntry {
  String model;
  int pk;
  Fields fields;

  BookingListEntry({
    required this.model,
    required this.pk,
    required this.fields,
  });

  factory BookingListEntry.fromJson(Map<String, dynamic> json) =>
      BookingListEntry(
        model: json["model"] ?? "main.booking",
        pk: json["pk"],
        fields: Fields.fromJson(json["fields"]),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "pk": pk,
        "fields": fields.toJson(),
      };
}

class Fields {
  int venueSchedule;
  int? coachSchedule;
  int customer;
  String customerName;
  String venueName;
  DateTime date;
  String startTime;
  String endTime;
  String? coachName;
  String totalPrice;
  DateTime bookingTime;
  String paymentMethod;
  bool isPaid;  // TAMBAHKAN
  List<EquipmentItem> equipments; 

  Fields({
    required this.venueSchedule,
    this.coachSchedule,
    required this.customer,
    required this.customerName,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.coachName,
    required this.totalPrice,
    required this.bookingTime,
    required this.paymentMethod, 
    this.isPaid = false, 
    required this.equipments, 
  });

  factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        venueSchedule: json["venue_schedule"] ?? 0,
        coachSchedule: json["coach_schedule"],
        customer: json["customer"] ?? 0,
        customerName: json["customer_name"]?.toString() ?? "Unknown",
        venueName: json["venue_name"]?.toString() ?? "Unknown Venue",
        date: _parseDate(json["date"]),
        startTime: json["start_time"]?.toString() ?? "00:00",
        endTime: json["end_time"]?.toString() ?? "00:00",
        coachName: _parseCoachName(json["coach_name"]),
        totalPrice: json["total_price"]?.toString() ?? "0",
        bookingTime: _parseDateTime(json["booking_time"]),
        paymentMethod: json["payment_method"]?.toString() ?? "CASH",
        isPaid: json["is_paid"] ?? false,  
        equipments: json["equipments"] != null
            ? List<EquipmentItem>.from(
                json["equipments"].map((x) => EquipmentItem.fromJson(x)))
            : [],
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static String? _parseCoachName(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    if (str == "-" || str.isEmpty) return null;
    return str;
  }

  Map<String, dynamic> toJson() => {
        "venue_schedule": venueSchedule,
        "coach_schedule": coachSchedule,
        "customer": customer,
        "customer_name": customerName,
        "venue_name": venueName,
        "date":
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "start_time": startTime,
        "end_time": endTime,
        "coach_name": coachName ?? "-",
        "total_price": totalPrice,
        "booking_time": bookingTime.toIso8601String(),
        "payment_method": paymentMethod,
        "is_paid": isPaid,  
        "equipments": equipments.map((x) => x.toJson()).toList(), 
      };
}

class EquipmentItem {
  String name;
  int quantity;

  EquipmentItem({
    required this.name,
    required this.quantity,
  });

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
        name: json["name"]?.toString() ?? "",
        quantity: json["quantity"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "quantity": quantity,
      };
}