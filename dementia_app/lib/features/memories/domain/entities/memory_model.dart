import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'memory_model.g.dart';

enum MemoryCategory {
  family,
  friends,
  travel,
  work,
  achievements,
  other
}

enum MemoryEmotion {
  anger,
  disgust,
  fear,
  joy,
  neutral,
  sadness,
  surprise
}

enum MediaType {
  image,
  video,
  audio,
  text
}

@JsonSerializable()
class Media {
  MediaType type;
  String? url;
  String description;

  Media({required this.type, this.url, required this.description});

  factory Media.fromMap(Map<String, dynamic> json) {
    return Media(
      type: MediaType.values.firstWhere(
              (e) => e.toString().split('.').last == json['type'],
          orElse: () => MediaType.image
      ),
      url: json['url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.toString().split('.').last,
    'url': url,
    'description': description,
  };

  Media copyWith({
    MediaType? type,
    String? url,
    String? description,
  }) {
    return Media(
      type: type ?? this.type,
      url: url ?? this.url,
      description: description ?? this.description,
    );
  }

  String toJson() => json.encode(toMap());

  factory Media.fromJson(String str) => Media.fromMap(json.decode(str));
}

@JsonSerializable()
class Memory {
  String? id;
  String patientId;
  String title;
  String? description;
  String? date;
  List<MemoryCategory>? categories;
  List<MemoryEmotion>? emotions;
  List<Media>? media;
  List<String>? associatedPeople;
  List<String>? tags;

  Memory({
    this.id,
    required this.patientId,
    required this.title,
    this.description,
    this.date,
    this.categories,
    this.emotions,
    this.media,
    this.associatedPeople,
    this.tags,
  });

  factory Memory.fromMap(Map<String, dynamic> map, {String? id}) {
    return Memory(
      id: id,
      patientId: map['patientId'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      categories: map['categories'] != null
          ? List<MemoryCategory>.from(map['categories'].map((e) => MemoryCategory.values.firstWhere(
              (element) => element.toString().split('.').last == e,
          orElse: () => MemoryCategory.other)))
          : null,
      emotions: map['emotions'] != null
          ? List<MemoryEmotion>.from(map['emotions'].map((e) => MemoryEmotion.values.firstWhere(
              (element) => element.toString().split('.').last == e,
          orElse: () => MemoryEmotion.neutral)))
          : null,
      media: map['media'] != null
          ? List<Media>.from(map['media'].map((e) => Media.fromMap(e)))
          : null,
      associatedPeople: map['associatedPeople'] != null
          ? List<String>.from(map['associatedPeople'])
          : null,
      tags: map['tags'] != null
          ? List<String>.from(map['tags'])
          : null,
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'title': title,
      'description': description,
      'date': date,
      'categories': categories?.map((e) => e.toString().split('.').last).toList(),
      'emotions': emotions?.map((e) => e.toString().split('.').last).toList(),
      'media': media?.map((e) => e.toMap()).toList(),
      'associatedPeople': associatedPeople,
      'tags': tags,
    };
  }

  String toJson() => json.encode(toMap());

  factory Memory.fromJson(String str) => Memory.fromMap(json.decode(str));

  Memory copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    String? date,
    List<MemoryCategory>? categories,
    List<MemoryEmotion>? emotions,
    List<Media>? media,
    List<String>? associatedPeople,
    List<String>? tags,
  }) {
    return Memory(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      categories: categories ?? this.categories,
      emotions: emotions ?? this.emotions,
      media: media ?? this.media,
      associatedPeople: associatedPeople ?? this.associatedPeople,
      tags: tags ?? this.tags,
    );
  }
}
