import 'dart:convert';

enum StepType {
  introduction,
  normal,
  conclusion,
}

extension StepTypeExtension on StepType {
  String get value {
    return toString().split('.').last;
  }

  static StepType fromString(String value) {
    return StepType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => StepType.normal,
    );
  }
}

class Script {
  String voice;
  String text;

  Script({required this.voice, required this.text});

  factory Script.fromMap(Map<String, dynamic> map) {
    return Script(
      voice: map['voice'],
      text: map['text'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voice': voice,
      'text': text,
    };
  }
}

class Step {
  int step;
  String description;
  List<String> guide;
  StepType type;
  List<String> mediaUrls;
  Script script;
  String? audioUrl;

  Step({
    required this.step,
    required this.description,
    required this.guide,
    required this.type,
    required this.mediaUrls,
    required this.script,
    this.audioUrl,
  });

  factory Step.fromMap(Map<String, dynamic> map) {
    return Step(
      step: map['step'],
      description: map['description'],
      guide: List<String>.from(map['guide']),
      type: StepTypeExtension.fromString(map['type']),
      mediaUrls: List<String>.from(map['mediaUrls']),
      script: Script.fromMap(map['script']),
      audioUrl: map['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step,
      'description': description,
      'guide': guide,
      'type': type.value,
      'mediaUrls': mediaUrls,
      'script': script.toMap(),
      'audioUrl': audioUrl,
    };
  }
}

class TherapyOutline {
  String id;
  String patientId;
  String memoryId;
  String status;
  List<Step>? steps;

  TherapyOutline({
    required this.id,
    required this.patientId,
    required this.memoryId,
    required this.status,
    this.steps,
  });

  factory TherapyOutline.fromMap(Map<String, dynamic> map, {required String id}) {
    return TherapyOutline(
      id: id,
      patientId: map['patientId'],
      memoryId: map['memoryId'],
      status: map['status'],
      steps: map['steps'] != null
          ? List<Step>.from(map['steps'].map((x) => Step.fromMap(x)))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'memoryId': memoryId,
      'status': status,
      'steps': steps?.map((x) => x.toMap()).toList(),
    };
  }
}

