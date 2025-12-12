// To parse this JSON data, do
//
//     final coachEntry = coachEntryFromJson(jsonString);

import 'dart:convert';

CoachEntry coachEntryFromJson(String str) => CoachEntry.fromJson(json.decode(str));

String coachEntryToJson(CoachEntry data) => json.encode(data.toJson());

class CoachEntry {
    int? id;
    String? userId;
    String? username;
    String? firstName;
    String? lastName;
    String? email;
    int? age;
    String? experienceDesc;
    double? ratePerHour;
    String? mainSportTrained;
    int? mainSportTrainedId;
    List<String>? serviceAreas;
    List<int>? serviceAreaIds;
    bool? isVerified;
    String? profilePicture;
    DateTime? createdAt;
    DateTime? updatedAt;

    CoachEntry({
        this.id,
        this.userId,
        this.username,
        this.firstName,
        this.lastName,
        this.email,
        this.age,
        this.experienceDesc,
        this.ratePerHour,
        this.mainSportTrained,
        this.mainSportTrainedId,
        this.serviceAreas,
        this.serviceAreaIds,
        this.isVerified,
        this.profilePicture,
        this.createdAt,
        this.updatedAt,
    });

    factory CoachEntry.fromJson(Map<String, dynamic> json) => CoachEntry(
        id: json["id"],
        userId: json["user_id"],
        username: json["username"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        age: json["age"],
        experienceDesc: json["experience_desc"],
        ratePerHour: json["rate_per_hour"]?.toDouble(),
        mainSportTrained: json["main_sport_trained"],
        mainSportTrainedId: json["main_sport_trained_id"],
        serviceAreas: json["service_areas"] == null 
            ? [] 
            : List<String>.from(json["service_areas"].map((x) => x)),
        serviceAreaIds: json["service_area_ids"] == null
            ? []
            : List<int>.from(json["service_area_ids"].map((x) => x)),
        isVerified: json["is_verified"],
        profilePicture: json["profile_picture"],
        createdAt: json["created_at"] == null 
            ? null 
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null 
            ? null 
            : DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "username": username,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "age": age,
        "experience_desc": experienceDesc,
        "rate_per_hour": ratePerHour,
        "main_sport_trained": mainSportTrained,
        "main_sport_trained_id": mainSportTrainedId,
        "service_areas": serviceAreas == null 
            ? [] 
            : List<dynamic>.from(serviceAreas!.map((x) => x)),
        "service_area_ids": serviceAreaIds == null
            ? []
            : List<dynamic>.from(serviceAreaIds!.map((x) => x)),
        "is_verified": isVerified,
        "profile_picture": profilePicture,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
    };

    // Helper getter untuk nama lengkap
    String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
    
    // Helper getter untuk cek apakah profile complete
    bool get isProfileComplete => 
        age != null && 
        experienceDesc != null && 
        ratePerHour != null && 
        mainSportTrained != null;
}