import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  String uid;
  String email;
  String firstName;
  String lastName;
  String dateOfBirth;
  String gender;
  String? profilePicUrl;

  String? birthPlace;
  List<Education>? educations;
  List<WorkExperience>? workExperiences;
  WorkStatus? currentWorkStatus;
  MaritalStatus? maritalStatus;
  List<FamilyMember>? familyMembers;
  String? spouse;
  List<String>? children;
  List<String>? grandChildren;
  String? caregiver;
  List<MedicalRecord>? medicalHistory;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.profilePicUrl,
    this.birthPlace,
    this.educations,
    this.workExperiences,
    this.currentWorkStatus,
    this.maritalStatus,
    this.familyMembers,
    this.spouse,
    this.children,
    this.grandChildren,
    this.caregiver,
    this.medicalHistory,
  });

  UserModel.fromOld({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.profilePicUrl,
  })  : educations = null,
        workExperiences = null,
        currentWorkStatus = null,
        maritalStatus = null,
        familyMembers = null,
        spouse = null,
        children = null,
        grandChildren = null,
        caregiver = null,
        medicalHistory = null;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'profilePicUrl': profilePicUrl,
      'birthPlace': birthPlace,
      'educations': educations?.map((e) => e.toMap()).toList(),
      'workExperiences': workExperiences?.map((e) => e.toMap()).toList(),
      'currentWorkStatus': currentWorkStatus?.toString(),
      'maritalStatus': maritalStatus?.toString(),
      'familyMembers': familyMembers?.map((e) => e.toMap()).toList(),
      'spouse': spouse,
      'children': children,
      'grandChildren': grandChildren,
      'caregiver': caregiver,
      'medicalHistory': medicalHistory?.map((e) => e.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      profilePicUrl: map['profilePicUrl'],
      birthPlace: map['birthPlace'],
      educations: map['educations'] != null
          ? List<Education>.from(map['educations'].map((x) => Education.fromMap(x)))
          : null,
      workExperiences: map['workExperiences'] != null
          ? List<WorkExperience>.from(map['workExperiences'].map((x) => WorkExperience.fromMap(x)))
          : null,
      currentWorkStatus: map['currentWorkStatus'] != null
          ? WorkStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['currentWorkStatus']?.split('.').last,
          orElse: () => WorkStatus.unknown
      ) : null,
      maritalStatus: map['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['maritalStatus']?.split('.').last,
          orElse: () => MaritalStatus.unknown
      ) : null,
      familyMembers: map['familyMembers'] != null
          ? List<FamilyMember>.from(map['familyMembers'].map((x) => FamilyMember.fromMap(x)))
          : null,
      spouse: map['spouse'],
      children: map['children'] != null ? List<String>.from(map['children']) : null,
      grandChildren: map['grandChildren'] != null ? List<String>.from(map['grandChildren']) : null,
      caregiver: map['caregiver'],
      medicalHistory: map['medicalHistory'] != null
          ? List<MedicalRecord>.from(map['medicalHistory'].map((x) => MedicalRecord.fromMap(x)))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String str) => UserModel.fromMap(json.decode(str));
}

@JsonSerializable()
class Education {
  String name;
  String? yearFrom;
  String? yearTo;
  String? description;

  Education({required this.name, this.yearFrom, this.yearTo, this.description});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'yearFrom': yearFrom,
      'yearTo': yearTo,
      'description': description,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      name: map['name'],
      yearFrom: map['yearFrom'],
      yearTo: map['yearTo'],
      description: map['description'],
    );
  }

  factory Education.fromJson(Map<String, dynamic> json) => _$EducationFromJson(json);
  Map<String, dynamic> toJson() => _$EducationToJson(this);
}

@JsonSerializable()
class WorkExperience {
  String company;
  String position;
  String? yearFrom;
  String? yearTo;
  String? description;

  WorkExperience({required this.company, required this.position, this.yearFrom, this.yearTo, this.description});

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'position': position,
      'yearFrom': yearFrom,
      'yearTo': yearTo,
      'description': description,
    };
  }

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    return WorkExperience(
      company: map['company'],
      position: map['position'],
      yearFrom: map['yearFrom'],
      yearTo: map['yearTo'],
      description: map['description'],
    );
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) => _$WorkExperienceFromJson(json);
  Map<String, dynamic> toJson() => _$WorkExperienceToJson(this);
}

enum MaritalStatus {
  single,
  married,
  divorced,
  widowed,
  unknown
}

enum WorkStatus {
  employed,
  unemployed,
  retired,
  student,
  homemaker,
  unknown
}


@JsonSerializable()
class FamilyMember {
  String name;
  String gender;
  String relation;
  String dob;
  String birthPlace;
  List<Education>? educations;
  List<WorkExperience>? workExperiences;
  String? currentWorkStatus;
  MaritalStatus? maritalStatus;
  String? spouse;
  List<String>? children;
  String? notes;

  FamilyMember({
    required this.name,
    required this.gender,
    required this.relation,
    required this.dob,
    required this.birthPlace,
    this.educations,
    this.workExperiences,
    this.currentWorkStatus,
    this.maritalStatus,
    this.spouse,
    this.children,
    this.notes,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      name: map['name'],
      gender: map['gender'],
      relation: map['relation'],
      dob: map['dob'],
      birthPlace: map['birthPlace'],
      educations: map['educations'] != null
          ? List<Education>.from(map['educations'].map((x) => Education.fromMap(x)))
          : null,
      workExperiences: map['workExperiences'] != null
          ? List<WorkExperience>.from(map['workExperiences'].map((x) => WorkExperience.fromMap(x)))
          : null,
      currentWorkStatus: map['currentWorkStatus'],
      maritalStatus: map['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere((e) => e.toString() == 'MaritalStatus.' + map['maritalStatus'])
          : null,
      spouse: map['spouse'],
      children: map['children'] != null ? List<String>.from(map['children']) : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'relation': relation,
      'dob': dob,
      'birthPlace': birthPlace,
      'educations': educations?.map((e) => e.toMap()).toList(),
      'workExperiences': workExperiences?.map((e) => e.toMap()).toList(),
      'currentWorkStatus': currentWorkStatus,
      'maritalStatus': maritalStatus?.toString(),
      'spouse': spouse,
      'children': children,
      'notes': notes,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) => _$FamilyMemberFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyMemberToJson(this);
}

@JsonSerializable()
class MedicalRecord {
  final String condition;
  final String? dateDiagnosed;
  final String? ongoingTreatment;
  final String? notes;

  MedicalRecord({
    required this.condition,
    this.dateDiagnosed,
    this.ongoingTreatment,
    this.notes,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      condition: map['condition'],
      dateDiagnosed: map['dateDiagnosed'],
      ongoingTreatment: map['ongoingTreatment'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'dateDiagnosed': dateDiagnosed,
      'ongoingTreatment': ongoingTreatment,
      'notes': notes,
    };
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => _$MedicalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$MedicalRecordToJson(this);
}
