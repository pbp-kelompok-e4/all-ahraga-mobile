// File: lib/models/location_area.dart

import 'dart:convert';

List<LocationArea> locationAreaFromJson(String str) => 
    List<LocationArea>.from(json.decode(str).map((x) => LocationArea.fromJson(x)));

String locationAreaToJson(List<LocationArea> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LocationArea {
    int id;
    String name;

    LocationArea({
        required this.id,
        required this.name,
    });

    factory LocationArea.fromJson(Map<String, dynamic> json) => LocationArea(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}