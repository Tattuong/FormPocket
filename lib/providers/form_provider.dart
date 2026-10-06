import 'dart:math';

import 'package:flutter/widgets.dart';

import '../core/form/form_engine.dart';
import '../core/services/storage_service.dart';

class FormProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _bookKey = 'fp_forms';
  static const _hideKey = 'fp_hide_sensitive';
  static const _demoProfileIds = {'personal', 'work', 'family'};
  static const _demoTemplateIds = {'shipping', 'company'};
  static const _lockKey = 'fp_lock_enabled';
  static const _pinKey = 'fp_lock_pin';
  static const _clipKey = 'fp_clips';

  List<PocketProfile> profiles = [];
  List<PocketTemplate> templates = [];
  List<PocketClip> clips = [];
  var hideSensitive = true;
  var lockEnabled = false;
  var unlocked = true;
  final Set<String> revealed = {};
  String _pin = '';
  var _seq = 0;

  FormProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && lockEnabled) {
      unlocked = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> init() async {
    hideSensitive = await StorageService.instance.getBool(_hideKey) ?? true;
    lockEnabled = await StorageService.instance.getBool(_lockKey) ?? false;
    _pin = await StorageService.instance.getString(_pinKey) ?? '';
    unlocked = !lockEnabled;
    final raw = await StorageService.instance.getString(_bookKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final book = FormBook.decode(raw);
        profiles = book.profiles;
        templates = book.templates;
      } catch (_) {
        await StorageService.instance.remove(_bookKey);
      }
    }
    final clipsRaw = await StorageService.instance.getString(_clipKey);
    if (clipsRaw != null && clipsRaw.isNotEmpty) {
      try {
        clips = FormEngine.decodeClips(clipsRaw);
      } catch (_) {
        await StorageService.instance.remove(_clipKey);
      }
    }
    final keptProfiles = [
      for (final profile in profiles)
        if (!_demoProfileIds.contains(profile.id)) profile,
    ];
    final keptIds = {for (final profile in keptProfiles) profile.id};
    final keptTemplates = [
      for (final template in templates)
        if (!_demoTemplateIds.contains(template.id) &&
            keptIds.contains(template.profileId))
          template,
    ];
    if (keptProfiles.length != profiles.length ||
        keptTemplates.length != templates.length) {
      profiles = keptProfiles;
      templates = keptTemplates;
      await _saveBook();
    }
    notifyListeners();
  }

  PocketProfile? profileById(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  PocketTemplate? templateById(String id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  bool canAddProfile(bool hasPro) =>
      hasPro || profiles.length < FormEngine.freeProfiles;

  bool canAddTemplate(bool hasPro) =>
      hasPro || templates.length < FormEngine.freeTemplates;

  Future<PocketProfile?> createProfile({
    required String name,
    required String detail,
    required String initials,
    required List<PocketField> fields,
    required bool hasPro,
  }) async {
    if (!canAddProfile(hasPro)) return null;
    final profile = PocketProfile(
      id: _nextId('profile'),
      name: name.trim(),
      detail: detail.trim(),
      initials: _initials(initials, name),
      tone: profiles.isEmpty ? 0 : 1,
      fields: fields,
    );
    profiles = [...profiles, profile];
    await _saveBook();
    notifyListeners();
    return profile;
  }

  Future<void> addField(String profileId, PocketField field) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id == profileId)
          profile.copyWith(fields: [...profile.fields, field])
        else
          profile,
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<void> updateProfile(PocketProfile profile) async {
    profiles = [
      for (final item in profiles)
        if (item.id == profile.id) profile else item,
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<void> updateField(String profileId, PocketField field) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id == profileId)
          profile.copyWith(
            fields: [
              for (final item in profile.fields)
                if (item.id == field.id) field else item,
            ],
          )
        else
          profile,
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<void> deleteField(String profileId, String fieldId) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id == profileId)
          profile.copyWith(
            fields: [
              for (final field in profile.fields)
                if (field.id != fieldId) field,
            ],
          )
        else
          profile,
    ];
    templates = [
      for (final template in templates)
        template.copyWith(
          fieldIds: [
            for (final id in template.fieldIds)
              if (id != fieldId) id,
          ],
        ),
    ];
    revealed.remove(fieldId);
    await _saveBook();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id != id) profile
    ];
    templates = [
      for (final template in templates)
        if (template.profileId != id) template,
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<PocketTemplate?> createTemplate({
    required String name,
    required String blurb,
    required String profileId,
    required List<String> fieldIds,
    required bool hasPro,
  }) async {
    if (!canAddTemplate(hasPro)) return null;
    final template = PocketTemplate(
      id: _nextId('template'),
      name: name.trim(),
      blurb: blurb.trim(),
      profileId: profileId,
      fieldIds: fieldIds,
    );
    templates = [...templates, template];
    await _saveBook();
    notifyListeners();
    return template;
  }

  Future<void> updateTemplate(PocketTemplate template) async {
    templates = [
      for (final item in templates)
        if (item.id == template.id) template else item,
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<PocketProfile?> duplicateProfile(
    String id, {
    required bool hasPro,
  }) async {
    final source = profileById(id);
    if (source == null) return null;
    return createProfile(
      name: '${source.name} copy',
      detail: source.detail,
      initials: source.initials,
      fields: [
        for (final field in source.fields)
          PocketField(
            id: _nextId('field'),
            label: field.label,
            value: field.value,
            sensitive: field.sensitive,
          ),
      ],
      hasPro: hasPro,
    );
  }

  Future<PocketTemplate?> duplicateTemplate(
    String id, {
    required bool hasPro,
  }) async {
    final source = templateById(id);
    if (source == null) return null;
    return createTemplate(
      name: '${source.name} copy',
      blurb: source.blurb,
      profileId: source.profileId,
      fieldIds: [...source.fieldIds],
      hasPro: hasPro,
    );
  }

  Future<void> rememberClip(String title, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final name = title.trim().isEmpty ? 'Copied' : title.trim();
    clips = [
      PocketClip(title: name, text: trimmed),
      for (final clip in clips)
        if (clip.text != trimmed) clip,
    ].take(FormEngine.clipLimit).toList();
    await StorageService.instance.saveString(
      _clipKey,
      FormEngine.encodeClips(clips),
    );
    notifyListeners();
  }

  Future<void> forgetClip(String text) async {
    clips = [
      for (final clip in clips)
        if (clip.text != text) clip,
    ];
    await StorageService.instance.saveString(
      _clipKey,
      FormEngine.encodeClips(clips),
    );
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    templates = [
      for (final item in templates)
        if (item.id != id) item
    ];
    await _saveBook();
    notifyListeners();
  }

  Future<void> setHideSensitive(bool value) async {
    hideSensitive = value;
    if (value) revealed.clear();
    await StorageService.instance.saveBool(_hideKey, value);
    notifyListeners();
  }

  bool hidden(PocketField field) =>
      field.sensitive && hideSensitive && !revealed.contains(field.id);

  void toggleReveal(String fieldId) {
    if (!revealed.add(fieldId)) revealed.remove(fieldId);
    notifyListeners();
  }

  Future<bool> setLock(String pin) async {
    final trimmed = pin.trim();
    if (trimmed.length < 4) return false;
    _pin = trimmed;
    lockEnabled = true;
    unlocked = true;
    await StorageService.instance.saveString(_pinKey, trimmed);
    await StorageService.instance.saveBool(_lockKey, true);
    notifyListeners();
    return true;
  }

  Future<void> clearLock() async {
    lockEnabled = false;
    unlocked = true;
    _pin = '';
    await StorageService.instance.saveBool(_lockKey, false);
    await StorageService.instance.remove(_pinKey);
    notifyListeners();
  }

  bool checkPin(String pin) => lockEnabled && pin.trim() == _pin;

  void unlock() {
    unlocked = true;
    notifyListeners();
  }

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  String _initials(String raw, String name) {
    final given = raw.trim().toUpperCase();
    if (given.isNotEmpty) return given.substring(0, min(2, given.length));
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'FP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _saveBook() async {
    await StorageService.instance.saveString(
      _bookKey,
      FormBook(profiles: profiles, templates: templates).encode(),
    );
  }
}
