// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      gender: json['gender'] as String,
      profilePicUrl: json['profilePicUrl'] as String?,
      birthPlace: json['birthPlace'] as String?,
      educations: (json['educations'] as List<dynamic>?)
          ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList(),
      workExperiences: (json['workExperiences'] as List<dynamic>?)
          ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentWorkStatus:
          $enumDecodeNullable(_$WorkStatusEnumMap, json['currentWorkStatus']),
      maritalStatus:
          $enumDecodeNullable(_$MaritalStatusEnumMap, json['maritalStatus']),
      familyMembers: (json['familyMembers'] as List<dynamic>?)
          ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      spouse: json['spouse'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      grandChildren: (json['grandChildren'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      caregiver: json['caregiver'] as String?,
      medicalHistory: (json['medicalHistory'] as List<dynamic>?)
          ?.map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dateOfBirth': instance.dateOfBirth,
      'gender': instance.gender,
      'profilePicUrl': instance.profilePicUrl,
      'birthPlace': instance.birthPlace,
      'educations': instance.educations,
      'workExperiences': instance.workExperiences,
      'currentWorkStatus': _$WorkStatusEnumMap[instance.currentWorkStatus],
      'maritalStatus': _$MaritalStatusEnumMap[instance.maritalStatus],
      'familyMembers': instance.familyMembers,
      'spouse': instance.spouse,
      'children': instance.children,
      'grandChildren': instance.grandChildren,
      'caregiver': instance.caregiver,
      'medicalHistory': instance.medicalHistory,
    };

const _$WorkStatusEnumMap = {
  WorkStatus.employed: 'employed',
  WorkStatus.unemployed: 'unemployed',
  WorkStatus.retired: 'retired',
  WorkStatus.student: 'student',
  WorkStatus.homemaker: 'homemaker',
  WorkStatus.unknown: 'unknown',
};

const _$MaritalStatusEnumMap = {
  MaritalStatus.single: 'single',
  MaritalStatus.married: 'married',
  MaritalStatus.divorced: 'divorced',
  MaritalStatus.widowed: 'widowed',
  MaritalStatus.unknown: 'unknown',
};

Education _$EducationFromJson(Map<String, dynamic> json) => Education(
      name: json['name'] as String,
      yearFrom: json['yearFrom'] as String?,
      yearTo: json['yearTo'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$EducationToJson(Education instance) => <String, dynamic>{
      'name': instance.name,
      'yearFrom': instance.yearFrom,
      'yearTo': instance.yearTo,
      'description': instance.description,
    };

WorkExperience _$WorkExperienceFromJson(Map<String, dynamic> json) =>
    WorkExperience(
      company: json['company'] as String,
      position: json['position'] as String,
      yearFrom: json['yearFrom'] as String?,
      yearTo: json['yearTo'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$WorkExperienceToJson(WorkExperience instance) =>
    <String, dynamic>{
      'company': instance.company,
      'position': instance.position,
      'yearFrom': instance.yearFrom,
      'yearTo': instance.yearTo,
      'description': instance.description,
    };

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) => FamilyMember(
      name: json['name'] as String,
      gender: json['gender'] as String,
      relation: json['relation'] as String,
      dob: json['dob'] as String,
      birthPlace: json['birthPlace'] as String,
      educations: (json['educations'] as List<dynamic>?)
          ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList(),
      workExperiences: (json['workExperiences'] as List<dynamic>?)
          ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentWorkStatus:
          $enumDecodeNullable(_$WorkStatusEnumMap, json['currentWorkStatus']),
      maritalStatus:
          $enumDecodeNullable(_$MaritalStatusEnumMap, json['maritalStatus']),
      spouse: json['spouse'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$FamilyMemberToJson(FamilyMember instance) =>
    <String, dynamic>{
      'name': instance.name,
      'gender': instance.gender,
      'relation': instance.relation,
      'dob': instance.dob,
      'birthPlace': instance.birthPlace,
      'educations': instance.educations,
      'workExperiences': instance.workExperiences,
      'currentWorkStatus': _$WorkStatusEnumMap[instance.currentWorkStatus],
      'maritalStatus': _$MaritalStatusEnumMap[instance.maritalStatus],
      'spouse': instance.spouse,
      'children': instance.children,
      'notes': instance.notes,
    };

MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) =>
    MedicalRecord(
      condition: json['condition'] as String,
      dateDiagnosed: json['dateDiagnosed'] as String?,
      ongoingTreatment: json['ongoingTreatment'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MedicalRecordToJson(MedicalRecord instance) =>
    <String, dynamic>{
      'condition': instance.condition,
      'dateDiagnosed': instance.dateDiagnosed,
      'ongoingTreatment': instance.ongoingTreatment,
      'notes': instance.notes,
    };
