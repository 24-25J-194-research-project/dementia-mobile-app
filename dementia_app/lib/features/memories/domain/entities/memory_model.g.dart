// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Media _$MediaFromJson(Map<String, dynamic> json) => Media(
      type: $enumDecode(_$MediaTypeEnumMap, json['type']),
      url: json['url'] as String?,
      description: json['description'] as String,
    );

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
      'type': _$MediaTypeEnumMap[instance.type]!,
      'url': instance.url,
      'description': instance.description,
    };

const _$MediaTypeEnumMap = {
  MediaType.image: 'image',
  MediaType.video: 'video',
  MediaType.audio: 'audio',
  MediaType.text: 'text',
};

Memory _$MemoryFromJson(Map<String, dynamic> json) => Memory(
      patientId: json['patientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date'] as String?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$MemoryCategoryEnumMap, e))
          .toList(),
      emotions: (json['emotions'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$MemoryEmotionEnumMap, e))
          .toList(),
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => Media.fromJson(e as String))
          .toList(),
      associatedPeople: (json['associatedPeople'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$MemoryToJson(Memory instance) => <String, dynamic>{
      'patientId': instance.patientId,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date,
      'categories':
          instance.categories?.map((e) => _$MemoryCategoryEnumMap[e]!).toList(),
      'emotions':
          instance.emotions?.map((e) => _$MemoryEmotionEnumMap[e]!).toList(),
      'media': instance.media,
      'associatedPeople': instance.associatedPeople,
      'tags': instance.tags,
    };

const _$MemoryCategoryEnumMap = {
  MemoryCategory.family: 'family',
  MemoryCategory.friends: 'friends',
  MemoryCategory.travel: 'travel',
  MemoryCategory.work: 'work',
  MemoryCategory.achievements: 'achievements',
  MemoryCategory.other: 'other',
};

const _$MemoryEmotionEnumMap = {
  MemoryEmotion.anger: 'anger',
  MemoryEmotion.disgust: 'disgust',
  MemoryEmotion.fear: 'fear',
  MemoryEmotion.joy: 'joy',
  MemoryEmotion.neutral: 'neutral',
  MemoryEmotion.sadness: 'sadness',
  MemoryEmotion.surprise: 'surprise',
};
