// lib/models/coach_list_models.dart

import 'package:intl/intl.dart';

class CoachListResponse {
  final bool success;
  final List<CoachProfile> coaches;
  final PaginationInfo pagination;
  final String? message;

  CoachListResponse({
    required this.success,
    required this.coaches,
    required this.pagination,
    this.message,
  });

  factory CoachListResponse.fromJson(Map<String, dynamic> json) {
    return CoachListResponse(
      success: json['success'] ?? false,
      coaches: json['coaches'] != null
          ? (json['coaches'] as List)
              .map((item) => CoachProfile.fromJson(item))
              .toList()
          : [],
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : PaginationInfo.empty(),
      message: json['message'],
    );
  }
}

class CoachProfile {
  final int id;
  final CoachUser user;
  final String? profilePicture;
  final int? age;
  final SportCategory? mainSportTrained;
  final double ratePerHour;
  final List<ServiceArea> serviceAreas;
  final String experienceDesc;

  CoachProfile({
    required this.id,
    required this.user,
    this.profilePicture,
    this.age,
    this.mainSportTrained,
    required this.ratePerHour,
    required this.serviceAreas,
    required this.experienceDesc,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      id: json['id'] ?? 0,
      user: CoachUser.fromJson(json['user'] ?? {}),
      profilePicture: json['profile_picture'],
      age: json['age'],
      mainSportTrained: json['main_sport_trained'] != null
          ? SportCategory.fromJson(json['main_sport_trained'])
          : null,
      ratePerHour: (json['rate_per_hour'] ?? 0).toDouble(),
      serviceAreas: json['service_areas'] != null
          ? (json['service_areas'] as List)
              .map((item) => ServiceArea.fromJson(item))
              .toList()
          : [],
      experienceDesc: json['experience_desc'] ?? '',
    );
  }

  // Helper method untuk format rupiah
  String get formattedRate {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return '${formatter.format(ratePerHour)}/jam';
  }

  // Helper method untuk service areas text
  String get serviceAreasText {
    if (serviceAreas.isEmpty) return '-';
    return serviceAreas.map((area) => area.name).join(', ');
  }

  // Helper method untuk experience description
  String get displayExperience {
    if (experienceDesc.isEmpty) {
      return 'Belum ada deskripsi pengalaman.';
    }
    return experienceDesc;
  }
}

class CoachUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;

  CoachUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory CoachUser.fromJson(Map<String, dynamic> json) {
    return CoachUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
    );
  }
}

class SportCategory {
  final int id;
  final String name;

  SportCategory({
    required this.id,
    required this.name,
  });

  factory SportCategory.fromJson(Map<String, dynamic> json) {
    return SportCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ServiceArea {
  final int id;
  final String name;

  ServiceArea({
    required this.id,
    required this.name,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final int? previousPage;
  final int? nextPage;
  final int totalCount;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    this.previousPage,
    this.nextPage,
    required this.totalCount,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      hasPrevious: json['has_previous'] ?? false,
      hasNext: json['has_next'] ?? false,
      previousPage: json['previous_page'],
      nextPage: json['next_page'],
      totalCount: json['total_count'] ?? 0,
    );
  }

  factory PaginationInfo.empty() {
    return PaginationInfo(
      currentPage: 1,
      totalPages: 1,
      hasPrevious: false,
      hasNext: false,
      totalCount: 0,
    );
  }
}

// Response untuk kategori olahraga
class SportCategoriesResponse {
  final bool success;
  final List<SportCategory> categories;
  final String? message;

  SportCategoriesResponse({
    required this.success,
    required this.categories,
    this.message,
  });

  factory SportCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return SportCategoriesResponse(
      success: json['success'] ?? false,
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((item) => SportCategory.fromJson(item))
              .toList()
          : [],
      message: json['message'],
    );
  }
}

// Response untuk area lokasi
class LocationAreasResponse {
  final bool success;
  final List<ServiceArea> areas;
  final String? message;

  LocationAreasResponse({
    required this.success,
    required this.areas,
    this.message,
  });

  factory LocationAreasResponse.fromJson(Map<String, dynamic> json) {
    return LocationAreasResponse(
      success: json['success'] ?? false,
      areas: json['areas'] != null
          ? (json['areas'] as List)
              .map((item) => ServiceArea.fromJson(item))
              .toList()
          : [],
      message: json['message'],
    );
  }
}

// Response untuk detail coach
class CoachDetailResponse {
  final bool success;
  final CoachDetail coach;
  final String? message;

  CoachDetailResponse({
    required this.success,
    required this.coach,
    this.message,
  });

  factory CoachDetailResponse.fromJson(Map<String, dynamic> json) {
    return CoachDetailResponse(
      success: json['success'] ?? false,
      coach: CoachDetail.fromJson(json['coach'] ?? {}),
      message: json['message'],
    );
  }
}

// Model detail coach (extended dari CoachProfile)
class CoachDetail {
  final int id;
  final CoachUser user;
  final String? profilePicture;
  final int? age;
  final String? gender;
  final String? phone;
  final SportCategory? mainSportTrained;
  final double ratePerHour;
  final List<ServiceArea> serviceAreas;
  final String experienceDesc;
  final int? yearsOfExperience;
  final String? certifications;
  final String? achievements;
  final List<Review> reviews;
  final int totalReviews;
  final double avgRating;

  CoachDetail({
    required this.id,
    required this.user,
    this.profilePicture,
    this.age,
    this.gender,
    this.phone,
    this.mainSportTrained,
    required this.ratePerHour,
    required this.serviceAreas,
    required this.experienceDesc,
    this.yearsOfExperience,
    this.certifications,
    this.achievements,
    required this.reviews,
    required this.totalReviews,
    required this.avgRating,
  });

  factory CoachDetail.fromJson(Map<String, dynamic> json) {
    return CoachDetail(
      id: json['id'] ?? 0,
      user: CoachUser.fromJson(json['user'] ?? {}),
      profilePicture: json['profile_picture'],
      age: json['age'],
      gender: json['gender'],
      phone: json['phone'],
      mainSportTrained: json['main_sport_trained'] != null
          ? SportCategory.fromJson(json['main_sport_trained'])
          : null,
      ratePerHour: (json['rate_per_hour'] ?? 0).toDouble(),
      serviceAreas: json['service_areas'] != null
          ? (json['service_areas'] as List)
              .map((item) => ServiceArea.fromJson(item))
              .toList()
          : [],
      experienceDesc: json['experience_desc'] ?? '',
      yearsOfExperience: json['years_of_experience'],
      certifications: json['certifications'],
      achievements: json['achievements'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((item) => Review.fromJson(item))
              .toList()
          : [],
      totalReviews: json['total_reviews'] ?? 0,
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
    );
  }

  // Helper method untuk format rupiah
  String get formattedRate {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return '${formatter.format(ratePerHour)}/jam';
  }

  // Helper method untuk service areas text
  String get serviceAreasText {
    if (serviceAreas.isEmpty) return '-';
    return serviceAreas.map((area) => area.name).join(', ');
  }

  // Helper method untuk gender display
  String get genderDisplay {
    if (gender == null) return '-';
    return gender == 'M' ? 'Laki-laki' : gender == 'F' ? 'Perempuan' : gender!;
  }
}

// Model Review
class Review {
  final int id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Helper method untuk format tanggal
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
    }
  }
}