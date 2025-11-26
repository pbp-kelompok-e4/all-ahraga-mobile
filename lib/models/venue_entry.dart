// To parse this JSON data, do
//
//     final venueEntry = venueEntryFromJson(jsonString);

import 'dart:convert';

List<VenueEntry> venueEntryFromJson(String str) => List<VenueEntry>.from(json.decode(str).map((x) => VenueEntry.fromJson(x)));

String venueEntryToJson(List<VenueEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class VenueEntry {
    String model;
    int pk;
    Fields fields;

    VenueEntry({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory VenueEntry.fromJson(Map<String, dynamic> json) => VenueEntry(
        model: json["model"],
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
    int owner;
    String name;
    String description;
    int location;
    String pricePerHour;
    int sportCategory;
    String mainImage;
    String paymentOptions;

    Fields({
        required this.owner,
        required this.name,
        required this.description,
        required this.location,
        required this.pricePerHour,
        required this.sportCategory,
        required this.mainImage,
        required this.paymentOptions,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        owner: json["owner"],
        name: json["name"],
        description: json["description"],
        location: json["location"],
        pricePerHour: json["price_per_hour"],
        sportCategory: json["sport_category"],
        mainImage: json["main_image"],
        paymentOptions: json["payment_options"],
    );

    Map<String, dynamic> toJson() => {
        "owner": owner,
        "name": name,
        "description": description,
        "location": location,
        "price_per_hour": pricePerHour,
        "sport_category": sportCategory,
        "main_image": mainImage,
        "payment_options": paymentOptions,
    };
}
