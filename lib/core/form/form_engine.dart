import 'dart:convert';

class PocketField {
  final String id;
  final String label;
  final String value;
  final bool sensitive;

  const PocketField({
    required this.id,
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  PocketField copyWith({String? label, String? value, bool? sensitive}) =>
      PocketField(
        id: id,
        label: label ?? this.label,
        value: value ?? this.value,
        sensitive: sensitive ?? this.sensitive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        'sensitive': sensitive,
      };

  factory PocketField.fromJson(Map<String, dynamic> json) => PocketField(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        sensitive: json['sensitive'] as bool? ?? false,
      );
}

class PocketProfile {
  final String id;
  final String name;
  final String detail;
  final String initials;
  final int tone;
  final List<PocketField> fields;

  const PocketProfile({
    required this.id,
    required this.name,
    required this.detail,
    required this.initials,
    required this.tone,
    required this.fields,
  });

  PocketProfile copyWith({
    String? name,
    String? detail,
    String? initials,
    int? tone,
    List<PocketField>? fields,
  }) =>
      PocketProfile(
        id: id,
        name: name ?? this.name,
        detail: detail ?? this.detail,
        initials: initials ?? this.initials,
        tone: tone ?? this.tone,
        fields: fields ?? this.fields,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'detail': detail,
        'initials': initials,
        'tone': tone,
        'fields': fields.map((field) => field.toJson()).toList(),
      };

  factory PocketProfile.fromJson(Map<String, dynamic> json) => PocketProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        initials: json['initials'] as String? ?? '',
        tone: (json['tone'] as num?)?.toInt() ?? 0,
        fields: [
          for (final item in json['fields'] as List? ?? [])
            PocketField.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}

class PocketTemplate {
  final String id;
  final String name;
  final String blurb;
  final String profileId;
  final List<String> fieldIds;

  const PocketTemplate({
    required this.id,
    required this.name,
    required this.blurb,
    required this.profileId,
    required this.fieldIds,
  });

  PocketTemplate copyWith({
    String? name,
    String? blurb,
    String? profileId,
    List<String>? fieldIds,
  }) =>
      PocketTemplate(
        id: id,
        name: name ?? this.name,
        blurb: blurb ?? this.blurb,
        profileId: profileId ?? this.profileId,
        fieldIds: fieldIds ?? this.fieldIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'blurb': blurb,
        'profileId': profileId,
        'fieldIds': fieldIds,
      };

  factory PocketTemplate.fromJson(Map<String, dynamic> json) => PocketTemplate(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        blurb: json['blurb'] as String? ?? '',
        profileId: json['profileId'] as String? ?? '',
        fieldIds: [
          for (final id in json['fieldIds'] as List? ?? []) id.toString(),
        ],
      );
}

class FormBook {
  final List<PocketProfile> profiles;
  final List<PocketTemplate> templates;

  const FormBook({required this.profiles, required this.templates});

  Map<String, dynamic> toJson() => {
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
        'templates': templates.map((template) => template.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory FormBook.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FormBook(
      profiles: [
        for (final item in json['profiles'] as List? ?? [])
          PocketProfile.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      templates: [
        for (final item in json['templates'] as List? ?? [])
          PocketTemplate.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}

enum CopyShape { plain, labels, line }

class PocketClip {
  final String title;
  final String text;

  const PocketClip({required this.title, required this.text});

  Map<String, dynamic> toJson() => {'title': title, 'text': text};

  factory PocketClip.fromJson(Map<String, dynamic> json) => PocketClip(
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

class FormEngine {
  FormEngine._();

  static const hiddenMark = '••••••••';
  static const freeProfiles = 3;
  static const freeTemplates = 2;
  static const clipLimit = 8;

  static String shown(PocketField field, {required bool hidden}) {
    if (field.sensitive && hidden) return hiddenMark;
    return field.value;
  }

  static String joinValues(Iterable<PocketField> fields) =>
      format(fields, CopyShape.plain);

  static String format(Iterable<PocketField> fields, CopyShape shape) {
    final ready =
        fields.where((field) => field.value.trim().isNotEmpty).toList();
    switch (shape) {
      case CopyShape.plain:
        return ready.map((field) => field.value.trim()).join('\n');
      case CopyShape.labels:
        return ready
            .map((field) => '${field.label}: ${field.value.trim()}')
            .join('\n');
      case CopyShape.line:
        return ready.map((field) => field.value.trim()).join(' · ');
    }
  }

  static String encodeClips(List<PocketClip> clips) =>
      jsonEncode(clips.map((clip) => clip.toJson()).toList());

  static List<PocketClip> decodeClips(String raw) {
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        if (item is Map) PocketClip.fromJson(Map<String, dynamic>.from(item)),
    ].where((clip) => clip.text.isNotEmpty).toList();
  }

  static List<PocketField> included(
      PocketProfile? profile, List<String> fieldIds) {
    if (profile == null) return const [];
    return [
      for (final id in fieldIds)
        for (final field in profile.fields)
          if (field.id == id) field,
    ];
  }
}
