import 'dart:convert';

List<BookingListEntry> bookingListEntryFromJson(String str) => List<BookingListEntry>.from(json.decode(str).map((x) => BookingListEntry.fromJson(x)));

String bookingListEntryToJson(List<BookingListEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BookingListEntry {
    Model model;
    int pk;
    Fields fields;

    BookingListEntry({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory BookingListEntry.fromJson(Map<String, dynamic> json) => BookingListEntry(
        model: modelValues.map[json["model"]]!,
        pk: json["pk"],
        fields: Fields.fromJson(json["fields"]),
    );

    Map<String, dynamic> toJson() => {
        "model": modelValues.reverse[model],
        "pk": pk,
        "fields": fields.toJson(),
    };
}

class Fields {
    int customer;
    int venueSchedule;
    int? coachSchedule;
    DateTime bookingTime;
    String totalPrice;

    Fields({
        required this.customer,
        required this.venueSchedule,
        required this.coachSchedule,
        required this.bookingTime,
        required this.totalPrice,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        customer: json["customer"],
        venueSchedule: json["venue_schedule"],
        coachSchedule: json["coach_schedule"],
        bookingTime: DateTime.parse(json["booking_time"]),
        totalPrice: json["total_price"],
    );

    Map<String, dynamic> toJson() => {
        "customer": customer,
        "venue_schedule": venueSchedule,
        "coach_schedule": coachSchedule,
        "booking_time": bookingTime.toIso8601String(),
        "total_price": totalPrice,
    };
}

enum Model {
    MAIN_BOOKING
}

final modelValues = EnumValues({
    "main.booking": Model.MAIN_BOOKING
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
