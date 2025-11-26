// To parse this JSON data, do
//
//     final equipmentEntry = equipmentEntryFromJson(jsonString);

import 'dart:convert';

List<EquipmentEntry> equipmentEntryFromJson(String str) => List<EquipmentEntry>.from(json.decode(str).map((x) => EquipmentEntry.fromJson(x)));

String equipmentEntryToJson(List<EquipmentEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EquipmentEntry {
    String model;
    int pk;
    Fields fields;

    EquipmentEntry({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory EquipmentEntry.fromJson(Map<String, dynamic> json) => EquipmentEntry(
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
    int venue;
    String name;
    String rentalPrice;
    int stockQuantity;

    Fields({
        required this.venue,
        required this.name,
        required this.rentalPrice,
        required this.stockQuantity,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        venue: json["venue"],
        name: json["name"],
        rentalPrice: json["rental_price"],
        stockQuantity: json["stock_quantity"],
    );

    Map<String, dynamic> toJson() => {
        "venue": venue,
        "name": name,
        "rental_price": rentalPrice,
        "stock_quantity": stockQuantity,
    };
}
