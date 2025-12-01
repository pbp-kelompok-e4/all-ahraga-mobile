// models/coach_entry.dart

import 'dart:convert';

List<CoachEntry> coachEntryFromJson(String str) => List<CoachEntry>.from(json.decode(str).map((x) => CoachEntry.fromJson(x)));

String coachEntryToJson(List<CoachEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CoachEntry {
    String model;
    int pk;
    Fields fields;

    CoachEntry({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory CoachEntry.fromJson(Map<String, dynamic> json) => CoachEntry(
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
    int user;
    int? age;
    String experienceDesc;
    String ratePerHour; // DecimalField di Django seringkali jadi String di JSON serializer bawaan
    String? profilePicture;
    int mainSportTrained; // Ini akan menerima ID (integer)
    List<int> serviceAreas; // ManyToMany field menjadi List of integers
    bool isVerified;

    Fields({
        required this.user,
        required this.age,
        required this.experienceDesc,
        required this.ratePerHour,
        required this.profilePicture,
        required this.mainSportTrained,
        required this.serviceAreas,
        required this.isVerified,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        user: json["user"],
        age: json["age"],
        experienceDesc: json["experience_desc"] ?? "",
        ratePerHour: json["rate_per_hour"],
        profilePicture: json["profile_picture"],
        mainSportTrained: json["main_sport_trained"],
        serviceAreas: List<int>.from(json["service_areas"].map((x) => x)),
        isVerified: json["is_verified"],
    );

    Map<String, dynamic> toJson() => {
        "user": user,
        "age": age,
        "experience_desc": experienceDesc,
        "rate_per_hour": ratePerHour,
        "profile_picture": profilePicture,
        "main_sport_trained": mainSportTrained,
        "service_areas": List<dynamic>.from(serviceAreas.map((x) => x)),
        "is_verified": isVerified,
    };
}