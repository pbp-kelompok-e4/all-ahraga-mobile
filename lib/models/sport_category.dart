// File: lib/models/sport_category.dart

import 'dart:convert';

List<SportCategory> sportCategoryFromJson(String str) => 
    List<SportCategory>.from(json.decode(str).map((x) => SportCategory.fromJson(x)));

String sportCategoryToJson(List<SportCategory> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SportCategory {
    int id;
    String name;

    SportCategory({
        required this.id,
        required this.name,
    });

    factory SportCategory.fromJson(Map<String, dynamic> json) => SportCategory(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}